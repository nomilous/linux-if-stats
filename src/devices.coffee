fs         = require 'fs'
Emitter    = require 'emitter'
dcopy      = require 'deep-copy'
{deferred} = require 'decor'
{EOL}      = require 'os'

###

IMPORTANT
--------- 

* poller skips if it catches it's tail

* emits 'poll' event with

    * `counters`  - Hash of counters
    * `timestamp` - Date
    * `deltas`    - Hash of counters, differece since preceding poll, null on first poll
    * `timespan`  - milliseconds since last poll, null on first poll

* emits 'error' event with

    * `error` - The error

* start returns promise, resolves after first poll


KNOWN SUPPORTED LIST
--------------------

`cat /etc/lsb-release | grep DESCRIPTION`

* DISTRIB_DESCRIPTION="Ubuntu 12.04.3 LTS"


###

local = 

    supported: process.platform is 'linux'
    metrics: [                              # * expected counters for each device listed in /proc/net/dev

        'rxBytes'
        'rxPackets'
        'rxErrs'
        'rxDrop'
        'rxFifo'
        'rxFrame'
        'rxCompressed'
        'rxMulticast'

        'txBytes'
        'txPackets'
        'txErrs'
        'txDrop'
        'txFifo'
        'txColls'
        'txCarrier'
        'txCompressed'
    ]

    pollTimer:      undefined               # * polling setInterval() reference, undefined if not running
    pollActive:     false                   # * a poll is currently in process
    pollError:      null                    # * null unless the last poll errored
    pollInterval:   1000                    # * the interval between polls
    pollHistory:    500 # thumbsuck         # * length of the buffer containing recent polls

                                            # 
    buffer:         []                      # accumulated poll data
                                            # ---------------------
                                            # 
                                            # * first element is the most recent reading
                                            # * element contains [counters, timestamp, deltas, timespan]
                                            # * deltas is the difference since the preceding poll
                                            # * timespan is the elapsed time since the preceding poll
                                            # 

                                            # 
    emitter: new Emitter                    # events
                                            # ------
                                            # 
                                            # `poll` - counters, timestamp, deltas, timespan
                                            # 


    poll: -> 

        return if local.pollActive
        local.pollActive = true

        counters  = {}
        timestamp = new Date
        deltas    = null
        timespan  = null

        try 

            [previousCounters, previousTimestamp] = local.buffer[0]
            timespan = timestamp - previousTimestamp
            deltas   = {}

        reading = [counters, timestamp, deltas, timespan]


        try 

            source = fs.readFileSync '/proc/net/dev', 'utf8'
            source.split( EOL )[2..].map (line) -> 

                return if line.match /^\s*$/
                [ignore, iface, readings] = line.match /\s*(.*)\:(.*)/

                keys    = local.metrics
                i       = -1
                metrics = counters[iface] = {}

                readings.match( 

                    /\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)/ 
                
                ).map (value) -> 

                    return unless key = keys[i++]
                    metrics[key] = parseInt value

        catch error

            local.pollError  = error
            local.emitter.emit 'error', error
            local.pollActive = false
            return


        local.pollError = null

        if deltas? 

            #
            # keep this out of the read loop
            # ------------------------------
            # 
            # * to enable superclass with nothing by read() defined here
            # * a recursive delta processor (spots numbers) will be needed
            #

            for iface of counters

                deltas[iface] ||= {}  # ( or isNumber later )

                for metric of counters[iface]

                    prev = previousCounters[iface][metric]
                    curr =         counters[iface][metric]

                    deltas[iface][metric] = curr - prev


        local.buffer.unshift reading
        local.buffer.pop() while local.buffer.length > local.pollHistory

        local.emitter.emit 'poll', counters, timestamp, deltas, timespan
        local.pollActive = false


    start: deferred (action) -> 

        if not local.supported then return action.reject( 
            new Error "Platform unsupported, expected: linux, got: #{process.platform}"
        )

        return action.resolve() if local.pollTimer?  # already running

        local.poll()
        local.pollTimer = setInterval local.poll, local.pollInterval
        action.resolve()



    stop: -> 

        clearInterval local.pollTimer
        local.pollTimer = undefined


    latest: (opts, callback) ->

        # 
        # * opts arg is present to support the web export (see below)
        #

        error = local.pollError

        unless local.supported 
            platform = process.platform
            error = new Error "Platform unsupported, expected: linux, got: #{platform}"
            console.log error
                            #
                            # * vertex does not handle this properly yet
                            #
            
        try

            [counters, timestamp, deltas, timespan] = local.buffer[0]
            result = 
                counters:  counters
                timestamp: timestamp
                deltas:    deltas
                timespan:  timespan


        #
        # async response
        # --------------
        # 
        # * includes poll error if present AND the latest poll result (if available)
        # * this means an older poll record will be returned if the most recent polls are erroring
        # 

        return callback error, result if typeof callback is 'function'


        #
        # sync response
        #

        throw error unless local.supported
        return result



    config: (opts, callback) -> 

        params = opts || {}
        if opts.query? then params = opts.query

        results = 
            polling: local.pollTimer?
            interval:
                value: local.pollInterval
                changed: false
                previous: null
                error:    null
            history: 
                value: local.pollHistory
                changed: false
                previous: null
                error:    null


        for key of params

            switch key

                when 'interval'

                    try 

                        continue if local.pollInterval == params[key]

                        previous              = local.pollInterval
                        local.pollInterval    = parseInt params[key]

                        results[key].changed  = true
                        results[key].value    = local.pollInterval
                        results[key].previous = previous

                        #
                        # * needs a restart on the new pollInterval if running
                        # * if not running, it still wont be after this
                        #

                        if local.pollTimer?

                            local.stop()
                            local.start()

                when 'history'

                    try 

                        if parseInt(params[key]) < 2
                            results[key].error = 'History buffer length cannot be less than 2'
                            continue

                        continue if local.pollHistory == params[key]

                        previous              = local.pollHistory
                        local.pollHistory     = parseInt params[key]

                        results[key].changed  = true
                        results[key].value    = local.pollHistory
                        results[key].previous = previous


        if typeof callback is 'function' then callback null, results



###

web exports
-----------

[vertex](https://github.com/nomilous/vertex)

###

local.latest.$www = {}
local.config.$www = {}


###

module / component exports
--------------------------

###


module.exports = 

    latest:   local.latest
    start:    local.start
    stop:     local.stop
    config:   local.config
    on:   ->  local.emitter.on.apply   local.emitter, arguments
    once: ->  local.emitter.once.apply local.emitter, arguments
    off:  ->  local.emitter.off.apply  local.emitter, arguments



#
# * export for testing
# 

module.exports.test = -> local

