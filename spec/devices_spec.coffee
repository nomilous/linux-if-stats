process.platform = 'linux'

{ipso, original, tag, define} = require 'ipso'

describe 'Devices', -> 

    before -> 

        #
        # alias component/component-emitter instance as 'emitter'
        # -------------------------------------------------------
        # 
        # * This enables the module being tested to require 'emitter' even tho
        #   it's not an installed node_module
        #

        define 

            emitter: -> require process.cwd() + '/components/component-emitter'
            'deep-copy': -> require process.cwd() + '/components/simov-deep-copy/lib/dcopy'


    before ipso (fs, Devices) -> 

        tag 

            local: Devices.test()

            #
            # tag the emitter instance
            # ------------------------
            # 
            # * This enables the injection of the 'emitterInstance' into tests
            # * The injector attaches `.does()` for assignment of function
            #   expectations in the tests.
            #

            emitterInstance: Devices.test().emitter


        @pollCount      = 0

        @currentBytes   = 0
        @currentPackets = 0
        @incrBytes      = 1024 * 10
        @incrPackets    = 10

        fs.does readFileSync: (filename) => 

            if filename is '/proc/net/dev'
                
                @pollCount++

                #
                # return a mock reading from /proc/net/dev
                # ----------------------------------------
                # 
                # * notice the incrementing counters rxBytes and rxPackets on 'lo' device
                #

                return """
                Inter-|   Receive                                                |  Transmit
                 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
                  eth0: 683321528  714240    0    0    0     0          0         1 138555453  347991    0    0    0     0       0          2
                    lo: #{@currentBytes += @incrBytes}   #{@currentPackets += @incrPackets}    0    0    0     0          0         0 95110463   32919    0    0    0     0       0          0
                
                """ 

            #
            # return original( arguments )
            # ----------------------------
            #
            # * just incase something else in the test would like to fs.readFileSync()
            #   in a manner that actually works as intended.
            # 

            console.log file: filename
            original arguments


    it 'can access the latest reading', 

        ipso (Devices, local) -> 

            local.poll()
            Devices.counters().data.eth0.rxBytes.should.equal 683321528


    it 'can start and stop polling', 

        ipso (facto, Devices, local, should) -> 

            @pollCount = 0
            local.pollInterval = 10  # fast, for testing
            Devices.start().then => 

                setTimeout (=>

                    Devices.stop()

                    #
                    # second timeout (below) ensures it stopped
                    #

                    (@pollCount < 6).should.equal true

                    Devices.counters().data.eth0.should.eql 

                        rxBytes: 683321528
                        rxPackets: 714240
                        rxErrs: 0
                        rxDrop: 0
                        rxFifo: 0
                        rxFrame: 0
                        rxCompressed: 0
                        rxMulticast: 1

                        txBytes: 138555453
                        txPackets: 347991
                        txErrs: 0
                        txDrop: 0
                        txFifo: 0
                        txColls: 0
                        txCarrier: 0
                        txCompressed: 2

                ), 40 


                setTimeout (=> 

                    should.not.exist local.pollTimer
                    (@pollCount < 6).should.equal true
                    facto()

                ), 100 # time for 10(ish) pollCounts


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

                pollTimer = local.pollTimer
                Devices.start().then -> 
                    
                    local.pollTimer.should.equal pollTimer
                    facto()


    it 'keeps buffer of counter values from each poll', 

        ipso (local) -> 

            local.buffer.length = 0 # flush
            local.poll()
            local.poll()

            [{eth0, lo}, at] = local.buffer[1] 

            #
            # second in buffer is previous the reading
            #

            #(timespan        < 2           ).should.equal true
            (@currentBytes   - lo.rxBytes  ).should.equal @incrBytes
            (@currentPackets - lo.rxPackets).should.equal @incrPackets



    it 'limits the length of the buffer and stores newest to oldest',

        ipso (local) -> 

            local.pollHistory = 3
            local.buffer.length = 0 # flush history array

            local.poll()
            local.poll()
            local.poll()
            local.poll()
            local.poll()

            local.buffer.length.should.equal 3

            console.log 'todo: timespan'

            # [timespan, {eth0, lo}] = local.history[0]
            # (@currentBytes - lo.rxBytes).should.equal @incrBytes * 3 # oldest

            # [timespan, {eth0, lo}] = local.history[1]
            # (@currentBytes - lo.rxBytes).should.equal @incrBytes * 2

            # [timespan, {eth0, lo}] = local.history[2]
            # (@currentBytes - lo.rxBytes).should.equal @incrBytes * 1




    it 'exports pubsub controls', 

        ipso (Devices, emitterInstance) -> 

            emitterInstance.does 
                once: ->
                off: ->
                on: -> 

            Devices.on()
            Devices.off()
            Devices.once()


    it 'publishes "counters" event on poll', 

        ipso (facto, emitterInstance, local) -> 

            emitterInstance.does 

                emit: (event, counters, timestamp) -> 

                    if event is 'counters'

                        timestamp.should.be.an.instanceof Date
                
                        counters.eth0.should.eql

                            rxBytes: 683321528
                            rxPackets: 714240
                            rxErrs: 0
                            rxDrop: 0
                            rxFifo: 0
                            rxFrame: 0
                            rxCompressed: 0
                            rxMulticast: 1
                            txBytes: 138555453
                            txPackets: 347991
                            txErrs: 0
                            txDrop: 0
                            txFifo: 0
                            txColls: 0
                            txCarrier: 0
                            txCompressed: 2

                        facto()

            local.poll()


    xit 'publishes "deltas" event on poll',

        ipso (facto, emitterInstance, local) -> 

            local.poll()

            emitterInstance.does 

                emit: (event, deltas, timespan) -> 

                    if event is 'deltas'

                        facto()


            setTimeout local.poll, 100


    it 'prevents the poll loop from catching its own tail', 

        ipso (facto) -> 

            facto help: 'dunno how to test this one'


    it 'can reset the polling interval while running', 

        ipso (facto, Devices, local) -> 

            Devices.start().then -> 

                Devices.config interval: 10000
                local.pollInterval.should.equal 10000
                local.pollTimer._idleTimeout.should.equal 10000
                facto()


    it 'can reset the interval pending poller next start if not running', 

        ipso (facto, Devices, local, should) -> 

            Devices.stop()
            Devices.config interval: 3000
            local.pollInterval.should.equal 3000
            should.not.exist local.pollTimer

            Devices.start().then ->
            
                local.pollTimer._idleTimeout.should.equal 3000
                facto()


    it 'calls back with config change result if callback provided', 

        #
        # this one's a little up-in-the-air re shape and size of response
        # specifically: error code other than 200 for vertex call on failure
        # 

        ipso (facto, Devices, local) -> 

            local.pollInterval = 1001
            local.pollHistory  = 1002

            Devices.start().then -> 

                Devices.config 

                    interval: 2000  # change polling interval
                    history:  1969  # change history length

                    (err, res) -> 
                    
                        res.should.eql 

                            polling: true

                            interval:
                                value:    2000
                                changed:  true
                                previous: 1001
                                error:    null

                            history:
                                value:    1969
                                changed:  true
                                previous: 1002
                                error:    null


                        facto()

    it 'cannot set history buffer length to less than 2', 

        ipso (facto, Devices) -> 

            Devices.config 
                history: 1
                (err, res) -> 

                    res.history.error.should.equal 'History buffer length cannot be less than 2'
                    facto()


    it 'calls back with running config even if no change', 

        ipso (facto, local, Devices) -> 

            Devices.stop()

            local.pollInterval = 1001
            local.pollHistory  = 1002
            Devices.config {}, (err, res) -> 

                res.should.eql 

                    polling: false

                    interval:
                        value:    1001
                        changed:  false
                        previous: null
                        error:    null

                    history:
                        value:    1002
                        changed:  false
                        previous: null
                        error:    null
                        
                facto()





