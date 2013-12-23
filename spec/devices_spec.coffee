{ipso, original, tag} = require 'ipso'

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

        ipso (facto, Devices, local) -> 

            local.interval = 10
            Devices.start()

            setTimeout (=>

                Devices.stop()
                @readings.should.equal 3

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

            ), 40 # time for three readings


            setTimeout (=> 

                #
                # it should have been stopped at 3 readings
                #

                @readings.should.equal 3
                facto()

            ), 100 # time for 9 readings

