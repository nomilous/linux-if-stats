fs         = require 'fs'
Emitter    = require 'emitter'
dcopy      = require 'deep-copy'
{deferred} = require 'decor'
{EOL}      = require 'os'

###

realized
--------

* internal polling loop per metricset might not be too smart
* more sensible perhaps for a calling parent loop to manage polling
* especially since the parent is likely also polling 
* with the resulting race condition therefore doing the foxtrot
* or playing musical chairs with itself in the mirror
* the music stops
* everybody either gets a chair, or bangs their head


moral of the story
------------------

* outside should not poll
* TODO: inside should publish events


realize (cont)
--------------

* most of the functionality here should be in a superclass, it will be repeated
* not so far fetched wanting to tinker with iface aliases, vlans, and such over a web api
* esp. eg. setting up a private vlan from some appserver vm onto some other dbserver vm on the fly


local
-----

* this module's privates
* accessable for testing via `.test()`
* obviously therefore also accessable in general (if used, expect no consistancy between versions)


`local.reading`        - contains the latest reading from /proc/net/dev

`local.pollTimestamp   - the most recen poll timestamp

`local.history`        - Cambrian was fun, from an evolutionary progress prespective
                       - Also, i don't see much reason why range triggering can't be performed at the monitor agent
                       - Certainly lightens the load at the core
                       - First element in the history [] is the oldest
                       - Each element contains [timespan, reading] where timespan is milliseconds that elapsed till the next reading reading
`local.emitter`        - emits 'counters' event with latest counter values at each poll
                       - emits 'deltas' event including pollspan (milliseconds) at each poll
                       - IMPORTANT, poller skips if it catches it's tail
`local.poke`           - a purposeless additional comment referring, in jest at my excessive annotations, to a non existant property
`remote.fondle`        - not yet implemented on facebook, but just you wait...

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
    pollError:      undefined    # unused   # * undefined unless the last poll errored
    pollInterval:   1000                    # * the interval between polls
    pollHistory:    500 # thumbsuck         # * length of the buffer containing recent polls



    reading:  {}

    
    history:  []
    emitter:  new Emitter

    counters: (opts, callback) ->

        #
        # * TODO: if the first call to current() happens before the first poll
        #         then things don't go quite as planned... 
        # 
        #         pending fix, start() is promised, dont call this until start resolves
        #

        #
        # responds synchronously or asynchronously
        # ----------------------------------------
        # 
        # * opts arg is present to support the web export (see below)
        #


        error = null
        unless local.supported 
            platform = process.platform
            error = new Error "Platform unsupported, expected: linux, got: #{platform}"
                            #
                            # * vertex does not handle this properly yet
                            #
            console.log error

        return callback error, local.reading if typeof callback is 'function'
        throw error unless local.supported
        return local.reading


    poll: -> 

        #
        # teenager, twenty-something, and certainly middle-aged load averages may lead to a 
        # situation where the previous poll has not completed by the next scheduled poll
        # 
        # this stops the birthdays piling up
        #

        return if local.pollActive
        local.pollActive = true


        #
        # previous reading into history
        # -----------------------------
        #

        now = new Date
        if local.pollTimestamp? 

            timespan = now - local.pollTimestamp
            previous = dcopy local.reading

            local.history.push [ timespan, previous ]
            local.history.shift() while local.history.length > local.pollHistory

        local.pollTimestamp = now
        

        #
        # ASSUMPTION: consistancy between linuxes/versions of content of /proc/net/dev
        # VERIFIED:   cat /etc/lsb-release | grep DESCRIPTION
        # 
        # * DISTRIB_DESCRIPTION="Ubuntu 12.04.3 LTS"
        #

        try data = fs.readFileSync '/proc/net/dev', 'utf8'
        catch error

            local.pollError  = error
            local.pollActive = false
            return

        local.pollError = undefined
        data.split( EOL )[2..].map (line) -> 

            return if line.match /^\s*$/

            [ignore, iface, readings] = line.match /\s*(.*)\:(.*)/

            
            keys = local.metrics
            i    = -1
            local.reading[iface] ||= {}


            readings.match( 

                /\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)/ 

            ).map (value) -> 

                return unless key = keys[i++]
                local.reading[iface][key] = parseInt value



            #
            # ASSUMPTION: [Array].map() does not break flow, therefore thigs are ready for emit
            #


            local.emitter.emit 'counters', local.reading, now

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


    ###

    vertex friendlyness
    -------------------

    * this config() function can be exported on a running vertex (see web exports below)
    * web hit: `config?pollInterval=10000` will call the function with `opts.query.interval`
    * obviously having to pass opts.query.pollInterval would seem a bit obtuse for local use, 
      so the function does a bit of juggling about that
    * admittedly this need could be considered a bit of a design wrinkle
        * missing:  Alternative
        * lastseen: 29th Feb, 2017

    ###

    config: (opts, callback) -> 

        params = opts || {}
        if opts.query? then params = opts.query

        #
        # TODO: 
        # * possibly use a decorator for that little switch-a-roo
        # * vertex exported function to support promise, weird mix of
        #   promises and callback in the module will confuse
        #

        results = 
            polling: local.pollTimer?
            interval:
                value: local.pollInterval
                changed: false
                previous: null
            history: 
                value: local.pollHistory
                changed: false
                previous: null


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

* these functions become availiable over http if this component is grafted 
  onto a running [vertex](https://github.com/nomilous/vertex) routes tree
* still much to be done with vertex
* eg. roles in the export config below does nothing yet

###

local.counters.$www = {}
local.config.$www = roles: ['admin']


###

module / component exports
--------------------------

###


module.exports = 

    counters: local.counters
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

