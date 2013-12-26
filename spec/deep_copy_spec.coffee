
{ipso, define} = require 'ipso'

define 'deep-copy': -> require process.cwd() + '/components/simov-deep-copy/lib/dcopy'

describe 'Which is faster', -> 

    before -> @tree = 

        precambrian:
            accretion: '-4,570,000,000'
            'SOLAR MAIN SEQUENCE START': '-4,550,000,000'
            hadean: '-4,500,000,000'
            'COLOSSAL LAGRANGIAN PROTOPLANETARY IMPACT': '-4,500,000,000'
            archean:
                'EARTHS CRUST STABALIZES': '-4,400,000,000'
                eoarchean: '-3,750,000,000'
                paleoarchean: '-3,600,000,000'
                'MAGNETIC FIELD ESTABLISHED': '-3,500,000,000'
                'EARLIEST KNOWN BACTERIA': '-3,460,000,000'
                mesoarchean: '-3,100,000,000'
                'VAALBARA': '-3,100,000,000'
                neoarchean: '-2,750,000,000'
            proterozoic: 
                paleoproterozoic: '-2,500,000,000'
                'EARLIEST MITOSIS': '-2,100,000,000'
                mesoproterozoic: '-1,600,000,000'
                'RODINIA AND MIROVIA': '-1,000,000,000'
                neoproterozoic: '-1,000,000,000'
                'FIRST ALGEA': '-1,000,000,000'
        phanerozoic:
            paleazoic:
                cambrian:
                    'CAMBRIAN EXPLOSION': '-530,000,000'
                    ordovician:' -490,000,000'
                    'ORDOVICIAN-SILURIAN MASS EXTINCTION EVENT': '-450,000,000'
                    silurian: '-450,000,000'
                    devonian: '-420,000,000'
                    'FIRST CREATURE TO TAKE A BREATH OF AIR': '-420,000,000'
                    'LATE DEVONIAN MASS EXTINCTION EVENT': '-360,000,000'
                    carboniferous: '-360,000,000'
                    permian: '-300,000,000'
               mesozoic:
                    'PERMIAN-TRIASSIC MASS EXTINCTION EVENT': '-251,000,000'
                    'FIRST DINOSOAR': '-225,000,000'
                    triassic: '-200,000,000'
                    'TRIASSIC-JURASSIC MASS EXTINCTION EVENT': '-205,000,000'
                    'PANGEA DIVIDES': '-180,000,000'
                    jurassic: '-150,000,000'
                    cretaceous: '-69,000,000'
                    'TYRANNOSAURUS REX': '-68,000,000 '
                cenozoic:
                    paleogene:
                        'CRETACEOUS-TERTIARY MASS EXTINCTION EVENT': '-65,000,000'
                        'FIRST PRIMATE': '-60,000,000'
                        paleocene: '-59,000,000'
                        'WHALES RETURN TO THE OCEAN': '-49.000.000'
                        eocene: '-34,000,000'
                        oligocene: '-23,000,000'
                  neogene:
                        miocene: '-6,500,000'
                        pliocene: '-2,800,000'
                  quaternary:
                        pleistocene:
                            gelasian: '-1,800,000'
                            calabrian: '-781,000'
                            'EARLIEST HOMO SAPIENS': '-200,000'
                            ionian: '-126,000'
                            'VENUS OF HOHLE FELS': '-40,000'
                            tarantian: '-11,700'
                        holocene:
                            'THE RISE OF JERICHO': '-11,000'
                            preboreal: '-9,000'
                            boreal: '-8,000'
                            'INVENTION OF THE WHEEL': '-7,000'
                            atlantic: '-5,000'
                            'SUMERIAN CUNEIFORM AND THE INVENTION OF WRITING': '-5,000'
                            'STONE AGE ENDS': '-5,000'
                            subboreal: '-2,500'
                            'DEATH OF SOCRATES': '-2,500'
                            'FIRST COUNCIL OF NICAEA': '-1,700'
                            'BIRTH OF THE INTERNET': '-30'




    it 'is faster to deep copy', -> 

        dcopy = require 'deep-copy'
        start = Date.now()

        copy = dcopy @tree for i in [0..10000]

        time = Date.now() - start
        console.log deep: time


    it 'is faster to pipe through json', -> 

        start = Date.now()

        copy = JSON.parse JSON.stringify @tree for i in [0..10000]

        time = Date.now() - start
        console.log json: time

    it 'is faster to deep copy', -> 

        dcopy = require 'deep-copy'
        start = Date.now()

        copy = dcopy @tree for i in [0..10000]

        time = Date.now() - start
        console.log deep: time

    it 'is faster to pipe through json', -> 

        start = Date.now()

        copy = JSON.parse JSON.stringify @tree for i in [0..10000]

        time = Date.now() - start
        console.log json: time



