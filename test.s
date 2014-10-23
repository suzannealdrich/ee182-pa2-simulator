addi $t0, $0, 1
andi $t0, $t0, -2
slti $t1, $t0, 1
bne $t1, $0, lessthanone
addi $v0, $t0, 13
beq $0, $0, done
lessthanone: addi $v0, $t0, 7
done: nop

