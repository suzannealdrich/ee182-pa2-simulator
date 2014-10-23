# code3: multiplies two numbers. 
#        returns result in $v0
#        we expect $v0 = 1242 (0x000004da)
#                  $v1 = 233


main:	addi	$a0, $0, 23
	addi	$a1, $0, 54
	lui	$a3, 0x8000
	add	$t0, $0, $0
	add	$s0, $0, $0
	addi	$s1, $0, 32
	addi	$t1, $a0, 0
loop:	and	$t2, $a3, $t1
	beq	$0, $t2, noadd
	add	$t0, $a1, $t0		
noadd:	addi	$s0, $s0, 1
	beq	$s0, $s1, end
	sll	$t1, $t1, 1
	sll	$t0, $t0, 1
	beq	$0, $0, loop
end:	addi	$v0, $t0, 0
	nop
	nop
	jr $ra

