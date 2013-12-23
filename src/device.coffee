###

local
-----

* this module's privates
* accessable for testing via `.test()`
* obviously therefore also eccessable in general (if used, expect no consistancy between versions)

`local.reading`  - contains the latest reading from /proc/net/dev
`local.interval` - the interval of reading taking
`local.poke`     - a purposeless additional comment referring, in jest at my excessive annotations, to a non existant property
`remote.fondle`  - not yet implemented on facebook, but just you wait...

###

local = 

    
    reading:  {}
    interval: 1000

    current: -> local.reading



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



#
# * export for testing
# 

module.exports.test = -> local

