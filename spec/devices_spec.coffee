process.platform = 'linux'

{ipso, original, tag, define} = require 'ipso'

#
# TODO: this is a bit of a mission
#       fix ipso to always walk componets dir, if present
#

define q: -> require process.cwd() + '/components/techjacker-q/q'


describe 'Devices', -> 

    before ipso (fs, Devices) -> 

        tag local: Devices.test()

        @readings = 0

        fs.does readFileSync: (filename) => 

            if filename is '/proc/net/dev'
                
                @readings++

                return """
                Inter-|   Receive                                                |  Transmit
                 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
                  eth0: 683321528  714240    0    0    0     0          0         0 138555453  347991    0    0    0     0       0          0
                    lo: 95110463   32919    0    0    0     0          0         0 95110463   32919    0    0    0     0       0          0
                
                """ 

            #
            # otherwise run original readFileSync (module loader needs it)
            #

            original arguments


    it 'can access the latest reading', 

        ipso (Devices, local) -> 

            local.reading = eth0: rxBytes: 0
            Devices.current().should.eql eth0: rxBytes: 0


    it 'can start and stop polling', 

        ipso (facto, Devices, local, should) -> 

            local.interval = 10
            Devices.start()

            setTimeout (=>

                Devices.stop()
                (@readings < 4).should.equal true

                Devices.current().eth0.should.eql 

                    rxBytes: 683321528
                    rxPackets: 714240
                    rxErrs: 0
                    rxDrop: 0
                    xrFifo: 0
                    rxFrame: 0
                    rxCompressed: 0
                    rxMulticast: 0

                    txBytes: 138555453
                    txPackets: 347991
                    txErrs: 0
                    txDrop: 0
                    txFifo: 0
                    txColls: 0
                    txCarrier: 0
                    txCompressed: 0

            ), 40   # time for three readings
                    # ocasionally only 2... ? 


            setTimeout (=> 

                #
                # it should have been stopped at 3 readings
                #

                should.not.exist local.timer
                @readings.should.equal 3
                facto()

            ), 100 # time for 9 readings


    it 'does not start if already running', 

        ipso (Devices, local) -> 

            Devices.start()
            timer = local.timer
            Devices.start()
            local.timer.should.equal timer


    it 'prevents the poll loop from catching its own tail', 

        ipso (facto) -> 

            facto help: 'dunno how to test this one'


    it 'can reset the polling interval while running', 

        ipso (Devices, local) -> 

            Devices.start()
            Devices.config interval: 10000
            local.interval.should.equal 10000
            local.timer._idleTimeout.should.equal 10000


    it 'can reset the interval pending poller next start if not running', 

        ipso (Devices, local, should) -> 

            Devices.stop()
            Devices.config interval: 3000
            local.interval.should.equal 3000
            should.not.exist local.timer

            Devices.start()
            local.timer._idleTimeout.should.equal 3000


    it 'calls back with result if callback provided', 

        #
        # this one's a little up-in-the-air re shape and size of response
        # specifically: error code other than 200 for vertex call on failure
        # 

        ipso (facto, Devices) -> 

            Devices.config interval: 3000
            Devices.start()

            Devices.config interval: 2000, (err, res) -> 
                
                res.should.eql 

                    interval:

                        changed: true
                        oldVal: 3000
                        newVal: 2000
                        running: true

                facto()



