{ipso, original, tag} = require 'ipso'

describe 'Device', -> 

    before ipso (fs, Device) -> 

        tag local: Device.test()

        fs.does readFileSync: (filename) ->  

            return """
            Inter-|   Receive                                                |  Transmit
             face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
              eth0: 683321528  714240    0    0    0     0          0         0 138555453  347991    0    0    0     0       0          0
                lo: 95110463   32919    0    0    0     0          0         0 95110463   32919    0    0    0     0       0          0

            """ if filename is '/proc/net/dev'

            #
            # otherwise run original readFileSync (module loader needs it)
            #

            original arguments


    it 'defines current property to return the latest reading', 

        ipso (local, Device) -> 

            local.reading = "DATA"
            Device.current().should.equal 'DATA'
