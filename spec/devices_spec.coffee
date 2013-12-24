process.platform = 'linux'

{ipso, original, tag, define} = require 'ipso'

#
# TODO: this is a bit of a mission
#       MAYBE: fix ipso to always walk componets dir, if present
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
            Devices.counters().should.eql eth0: rxBytes: 0


    it 'can start and stop polling', 

        ipso (facto, Devices, local, should) -> 

            @readings = 0
            local.interval = 10  # fast, for testing
            Devices.start().then => 

                setTimeout (=>

                    Devices.stop()
                    (@readings < 6).should.equal true

                    Devices.counters().eth0.should.eql 

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

                ), 40   # time for four readings
                        # ocasionally only 3... ? 


                setTimeout (=> 

                    #
                    # it should have been stopped at 3 readings
                    #

                    should.not.exist local.timer
                    @readings.should.equal 4
                    facto()

                ), 100 # time for 9 readings


    it 'rejects the start promise on unsupported platform', 

        ipso (facto, Devices, local) -> 

            local.supported = false
            process.platform = 'darwin'
            Devices.start().then (->), (err) -> 

                #
                # reset before possible AssertionException otherwise it never resets
                #

                local.supported = true
                process.platform = 'linux'

                err.message.should.equal 'Platform unsupported, expected: linux, got: darwin'
                facto()


    it 'does first poll before resolving the start promise', 

        ipso (facto, Devices, local) -> 

            Devices.stop()
            polled = false
            local.does poll: -> polled = true
            Devices.start().then -> 

                polled.should.equal true
                facto()


    it 'does not start if already running', 

        ipso (facto, Devices, local) -> 

            Devices.start().then -> 

                timer = local.timer
                Devices.start().then -> 
                    
                    local.timer.should.equal timer
                    facto()


    it 'prevents the poll loop from catching its own tail', 

        ipso (facto) -> 

            facto help: 'dunno how to test this one'


    it 'can reset the polling interval while running', 

        ipso (facto, Devices, local) -> 

            Devices.start().then -> 

                Devices.config interval: 10000
                local.interval.should.equal 10000
                local.timer._idleTimeout.should.equal 10000
                facto()


    it 'can reset the interval pending poller next start if not running', 

        ipso (facto, Devices, local, should) -> 

            Devices.stop()
            Devices.config interval: 3000
            local.interval.should.equal 3000
            should.not.exist local.timer

            Devices.start().then ->
            
                local.timer._idleTimeout.should.equal 3000
                facto()


    it 'calls back with result if callback provided', 

        #
        # this one's a little up-in-the-air re shape and size of response
        # specifically: error code other than 200 for vertex call on failure
        # 

        ipso (facto, Devices) -> 

            Devices.config interval: 3000
            Devices.start().then -> 

                Devices.config interval: 2000, (err, res) -> 
                    
                    res.should.eql 

                        interval:

                            changed: true
                            oldVal: 3000
                            newVal: 2000
                            running: true

                    facto()



