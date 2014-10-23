# codeaddi.s  checks for correct operation of addi instruction.
# returns result in $v0
# we expect $v0 = -12
#           $v1 = 5
#
# Sample output:
# R-type: 0
# I-type: 5
# J-type: 0
# The return value: -12
# The number of instructions executed: 5


addi  $t0, $zero, 1       #$t0 gets 1
addi  $t1, $t0,   -12     #$t1 gets -11
addi  $s0, $t1,   32767   #$s0 gets 32756
addi  $s1, $s0,  -32768   #$s1 gets -12
addi  $v0, $s1,   0       #$v1 gets -12
nop

