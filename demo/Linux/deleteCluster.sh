#!/bin/bash
# Delete all possible demo queue managers
endmqm -w QMGR4
dltmqm QMGR4
endmqm -w QMGR3
dltmqm QMGR3
endmqm -w QMGR2
dltmqm QMGR2
endmqm -w QMGR1
dltmqm QMGR1
