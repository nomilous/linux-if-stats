fs = require 'fs'
{EOL} = require 'os'

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


local
-----

* this module's privates
* accessable for testing via `.test()`
* obviously therefore also accessable in general (if used, expect no consistancy between versions)

`local.reading`  - contains the latest reading from /proc/net/dev
`local.interval` - the interval of reading taking
`local.timer`    - the running timer loop reference
`local.polling`  - the poll is currently active
`local.poke`     - a purposeless additional comment referring, in jest at my excessive annotations, to a non existant property
`remote.fondle`  - not yet implemented on facebook, but just you wait...

###

local = 

    reading:  {}
    interval: 1000
    timer:    undefined
    polling:  false

    current: (opts, callback) ->

        #
        # responds synchronously or asynchronously
        # ----------------------------------------
        # 
        # * opts arg is present to support the web export (see below)
        #

        error = null
        return callback error, local.reading if typeof callback is 'function'
        return local.reading

    poll: -> 

        #
        # teenager, twenty-something, and certainly middle-aged load averages may lead to a 
        # situation where the previous poll has not completed by the next scheduled poll
        # 
        # this stops the birthdays piling up
        #

        return if local.polling
        local.polling = true

        #
        # ASSUMPTION: consistancy between linuxes/versions of content of /proc/net/dev
        #

        data = fs.readFileSync '/proc/net/dev'
        data.split( EOL )[2..].map (line) -> 

            [ignore, iface, readings] = line.match /\s*(.*)\:(.*)/

            local.reading[iface] ||= {}

            keys = [ 
                'ignore'   # first item in match is the input string
                'rxBytes'
                'rxPackets'
                'rxErrs'
                'rxDrop'
                'xrFifo'
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

            readings.match( 

                /\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)\s*(\d*)/ 

            ).map (value) -> 

                key = keys.shift()
                return if key is 'ignore'

                                            #
                                            # possibly hazardous
                                            #
                local.reading[iface][key] = parseInt value


            #
            # ASSUMPTION: [Array].map() does not break flow, therefore the lowering of this flag
            #             only occurs after all calls into the mapper
            #

            local.polling = false


    start: -> 

        return if alreadyRunning = local.timer?
        local.timer = setInterval local.poll, local.interval


    stop: -> 

        clearInterval local.timer
        local.timer = undefined


    ###

    vertex friendlyness
    -------------------

    * this config() function can be exported on a running vertex (see web exports below)
    * web hit: `config?interval=10000` will call the function with `opts.query.interval`
    * obviously having to pass opts.query.interval would seem a bit obtuse for local use, 
      so the function does a bit of juggling about that
    * admittedly this need could be considered a bit of a design wrinkle
        * missing:  Alternative
        * lastseen: 29th Feb, 2017

    ###

    config: (opts, callback) -> 

        params = opts || {}
        if opts.query? then params = opts.query

        #
        # possibly use a decorator for that little switch-a-roo
        #

        for key of params

            if key is 'interval'

                try local.interval = parseInt params[key]

                #
                # * needs a restart on the new interval if running
                # * if not running, it still wont be after this
                #

                if local.timer?

                    local.stop()
                    local.start()



###

web exports
-----------

* these functions become availiable over http if this component is grafted 
  onto a running [vertex](https://github.com/nomilous/vertex) routes tree
* still much to be done with vertex
* eg. roles in the export config below does nothing yet

###

local.current.$www = {}
local.config.$www = roles: ['admin']


###

module / component exports
--------------------------

###


module.exports = 

    current: local.current
    start:   local.start
    stop:    local.stop
    config:  local.config



#
# * export for testing
# 

module.exports.test = -> local

