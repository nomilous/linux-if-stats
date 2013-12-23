fs = require 'fs'
{EOL} = require 'os' 

###

local
-----

* this module's privates
* accessable for testing via `.test()`
* obviously therefore also eccessable in general (if used, expect no consistancy between versions)

`local.reading`  - contains the latest reading from /proc/net/dev
`local.interval` - the interval of reading taking
`local.timer`    - the running timer loop reference
`local.poke`     - a purposeless additional comment referring, in jest at my excessive annotations, to a non existant property
`remote.fondle`  - not yet implemented on facebook, but just you wait...

###

local = 

    
    reading:  {}
    interval: 1000
    timer:    undefined
    current: -> local.reading

    poll: -> 

        data = fs.readFileSync '/proc/net/dev'

        #
        # ASSUMPTION: consistancy between linuxes/versions of content of /proc/net/dev
        #

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


    ###
    
    `start()` - Starts the poller
    -----------------------------

    ###

    start: -> 

        local.timer = setInterval local.poll, local.interval








###

web exports
-----------

* these functions become availiable over http if this component is grafted 
  onto a running [vertex](https://github.com/nomilous/vertex) routes tree

###

local.current.$www = {}



###

module / component exports
--------------------------

###


module.exports = 

    current: local.current
    start:   local.start



#
# * export for testing
# 

module.exports.test = -> local

