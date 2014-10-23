##############################################################
# simulator.s -- skeleton file for a simulated MIPS machine		
#								
#    Programming Assignment 2						
#    EE182, Fall 1999-2000					
#    Prof. Fountain
#
##############################################################

		.data
registers:	.space 128		# 32 words for registers
static:		.space 2048		# 512 words.  This stores
					#    the programs you run on your
					#    virtual machine and
					#    also includes stack area


str1:		.asciiz "The return value: "
str2:		.asciiz "The number of instructions executed: "
str3:		.asciiz "R-type: "
str4:		.asciiz "I-type: "
str5:		.asciiz "J-type: "
retn:		.asciiz "\n"
	
		.text
        	.globl main

main:		addi $sp, $sp -32		
		sw $ra, 20($sp)
		sw $fp, 16($sp)
		addiu $fp, $sp, 28

		# this code reads in the input file--a list of integers
		# (one per line) representing a MIPS assembly language
		# program, hand-assembled.  It stops when it sees a 0, i.e., 
		# sll $0, $0, 0 or NOP)  The code is stored at the beginning 
		# of static segment allocated above, one integer per word 
		# (one instruction per word)
		
		la $t0, static		# $t0 = pointer to beginning of
					#    static space, where your
					#    code will be stored.
	
loop1:		li $v0, 5		# code for read_int
		syscall			# $v0 gets integer
		beq $v0, $0, EO_prog
	
		sw $v0, 0($t0)		# place instruction in code space
		addi $t0, $t0, 4	# increment to next code space
		j loop1

EO_prog:	addi $t0, $t0, 4
		sw $v0, 0($t0)		# place the NOP in the code space 
					# as well to signal the end of program

		la $a0, registers
		la $a1, static
		addi $a2, $a1, 2044	# stack pointer points to highest
					#    memory in the static memory area
		la $a3, static		# $a3 can be used as the pointer
					#    to your instructions, so it
					#    is initialized to point to the
					#    first one.
	
		jal sim_mips		# Call the MIPS simulator

		move $t0, $v0		

		la $a0, str1		# "The return value: "
		li $v0, 4
		syscall
		move $a0, $t0
		li $v0, 1
		syscall
		la $a0, retn
		li $v0, 4
		syscall

		la $a0, str2		# "The number of instructions ... "
		li $v0, 4
		syscall
		move $a0, $v1
		li $v0, 1
		syscall
		la $a0, retn
		li $v0, 4
		syscall

		lw $ra, 20($sp)
		lw $fp, 16($sp)
		addi $sp, $sp, 32
		jr $ra			# exit out of main





sim_mips:	# Arguments passed in:
		#	$a0 = pointer to space for your registers (access
		#		0($a0) up to 124($a0)
		#	$a1 = pointer to lowest address in your static 
		#		memory area (2048 bytes available)
		#	$a2 = pointer to the top of the stack (also the
		#		highest memory in the static memory area)
		#	$a3 = pointer to the first instruction in the program 
		# 		(actually contains same value as $a1, since
		#		code is loaded into lowest memory addresses).
		#               Recall that you do not need to load the
		#               instructions in! The shell takes care of this
		#               for you.
		#
		# Register allocation:
		#	You should probably assign certain SPIM registers
		#	to act as your simulated machine's PC, etc.
		#	For clarity's sake, note the assignments here.
		#
		# Virtual machine
		#	If you need more storage area for your
		#	*machine*, use assembler directives to
		#	allocate space.

#####  BEGIN YOUR CODE HERE !!!!!!!!!!!!
		
        addiu   $sp, $sp, -32	# Stack frame 32 bytes long
        sw		$ra,  24($sp)	# Store return address
        sw		$fp,  20($sp)	# Store frame pointer
        sw		$s4,  16($sp)
        sw		$s3,  12($sp)
        sw		$s2,  8($sp)
        sw		$s1,  4($sp)
        sw		$s0,  0($sp)
        addiu   $fp, $sp, 28	# Set up new frame pointer
		
		
		move	$s0, $0			# 'R'
		move	$s1, $0			# 'I'
		move	$s2, $0			# 'J'
		move	$s3, $0			# total

		sw		$0,  0($a0)		# virtual_register[0] = 0
		sub		$t0, $a2, $a1	# initialize sp relative to virtual_memory
		sw		$t0, 116($a0)	# virtual_register[sp]
		
fetch:	lw		$t0, 0($a3)		# load next instruction
		addi	$a3, $a3, 4		# increment pc

		beq		$t0, $0, _nop
		addi	$s3, 1			# increment total

		srl		$t1, $t0, 26	# isolate 't1 = opcode'
		sll		$t2, $t1, 26	# shift back into place
		xor		$t0, $t0, $t2	# remove opcode t0 = bits 25-0
		
		li		$t2, 3			# 000 011
		beq		$t1, $t2, _jal

		srl		$t3, $t0, 21	# isolate 't3 = rs'
		sll		$t2, $t3, 21	# shift back into place
		xor		$t0, $t0, $t2	# remove rs field t0 = bits 20-0

		srl		$t4, $t0, 16	# isolate 't4 = rt'
		sll		$t2, $t4, 16	# shift back into place
		xor		$t0, $t0, $t2	# remove rt field t0 = bits 15-0

		bne		$t1, $0, iform
		# j		rform

rform:	addi	$s0, 1			# increment R counter
		srl		$t5, $t0, 11	# isolate 't5 = rd'
		sll		$t2, $t5, 11	# shift back into place
		xor		$t0, $t0, $t2	# remove rd field t0 = bits 10-0

		srl		$t6, $t0, 6		# isolate 't6 = shamt'
		sll		$t2, $t6, 6		# shift back into place
		xor		$t0, $t0, $t2	# remove shamt field t0 = bits 5-0

		move	$t7, $t0		# isolate 't7 = func'

		li		$t2, 0			# 000 000
		beq		$t7, $t2, _sll

		li		$t2, 8			# 001 000
		beq		$t7, $t2, _jr
		
		li		$t2, 32			# 100 000
		beq		$t7, $t2, _add
		
		li		$t2, 34			# 100 010
		beq		$t7, $t2, _sub	

		li		$t2, 36			# 100 100
		beq		$t7, $t2, _and
		
		li		$t2, 42			# 101 010
		beq		$t7, $t2, _slt		
						
		j		fetch

iform:	addi	$s1, 1			# increment I counter
		sll		$t5, $t0, 16	# i form instruction
		sra		$t5, $t5, 16	# 't5 = sign extended immediate data'

		li		$t2, 4			# 000 100
		beq		$t1, $t2, _beq
		
		li		$t2, 5			# 000 101
		beq		$t1, $t2, _bne

		li		$t2, 8			# 001 000
		beq		$t1, $t2, _addi
		
		li		$t2, 10			# 001 010
		beq		$t1, $t2, _slti
		
		li		$t2, 12			# 001 100
		beq		$t1, $t2, _andi		
		
		li		$t2, 15			# 001 111
		beq		$t1, $t2, _lui	
		
		li		$t2, 35			# 100 011
		beq		$t1, $t2, _lw
		
		li		$t2, 43			# 101 011
		beq		$t1, $t2, _sw		
		
		j		fetch
				
# J-format instructions

_jal:	addi	$s2, 1			# increment J counter
		sub		$t2, $a3, $a1	# pc relative to virtual_memory
		sw		$t2, 124($a0)	# store pc in ra
		sll		$t0, $t0, 2		# address * 4
		add		$a3, $t0, $a1	# relative to virtual_memory
		j		fetch

# R-format instructions
		
_sll:	sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		lw		$t0, 0($t0)		# content of virtual_register[rt]
		
		sllv	$t2, $t0, $t6	# shift left logical variable
		
		sll		$t0, $t5, 2		# rd * 4
		add		$t0, $t0, $a0	# address of virtual_register[rd]
		sw		$t2, 0($t0)		# store in virtual_register[rd]
		j		fetch
		
_jr:	sll		$t0, $t3, 2		# rs * 4
		add		$t0, $t0, $a0	# address of virtual_register[rs]
		lw		$t2, 0($t0)		# content of virtual_register[rs]
		add		$a3, $t2, $a1	# relative to virtual_memory
		j		fetch
		
_add:	sll		$t0, $t3, 2		# rs * 4
		add		$t0, $t0, $a0	# address of virtual_register[rs]
		lw		$t1, 0($t0)		# content of virtual_register[rs]
		
		sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		lw		$t2, 0($t0)		# store in virtual_register[rt]
		
		add		$t2, $t1, $t2	# add
		
		sll		$t0, $t5, 2		# rd * 4
		add		$t0, $t0, $a0	# address of virtual_register[rd]
		sw		$t2, 0($t0)		# store in virtual_register[rd]
		j		fetch
		
_sub:	sll		$t0, $t3, 2		# rs * 4
		add		$t0, $t0, $a0	# address of virtual_register[rs]
		lw		$t1, 0($t0)		# content of virtual_register[rs]
		
		sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		lw		$t2, 0($t0)		# store in virtual_register[rt]
		
		sub		$t2, $t1, $t2	# subtract
		
		sll		$t0, $t5, 2		# rd * 4
		add		$t0, $t0, $a0	# address of virtual_register[rd]
		sw		$t2, 0($t0)		# store in virtual_register[rd]
		j		fetch
		
_and:	sll		$t0, $t3, 2		# rs * 4
		add		$t0, $t0, $a0	# address of virtual_register[rs]
		lw		$t1, 0($t0)		# content of virtual_register[rs]
		
		sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		lw		$t2, 0($t0)		# store in virtual_register[rt]
		
		and		$t2, $t1, $t2	# and
		
		sll		$t0, $t5, 2		# rd * 4
		add		$t0, $t0, $a0	# address of virtual_register[rd]
		sw		$t2, 0($t0)		# store in virtual_register[rd]
		j		fetch
		
_slt:	sll		$t0, $t3, 2		# rs * 4
		add		$t0, $t0, $a0	# address of virtual_register[rs]
		lw		$t1, 0($t0)		# content of virtual_register[rs]
		
		sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		lw		$t2, 0($t0)		# store in virtual_register[rt]
		
		slt		$t2, $t1, $t2	# set less than
		
		sll		$t0, $t5, 2		# rd * 4
		add		$t0, $t0, $a0	# address of virtual_register[rd]
		sw		$t2, 0($t0)		# store in virtual_register[rd]
		j		fetch	

# I-format instructions
		
_beq:	sll		$t0, $t3, 2		# rs * 4
		add		$t0, $t0, $a0	# address of virtual_register[rs]
		lw		$t1, 0($t0)		# content of virtual_register[rs]
		
		sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		lw		$t2, 0($t0)		# content of virtual_register[rt]
		
		bne		$t1, $t2, fetch # condition not met
		sll		$t0, $t5, 2		# offset * 4
		add		$a3, $a3, $t0	# pc = pc + branch offset
		j		fetch	

_bne:	sll		$t0, $t3, 2		# rs * 4
		add		$t0, $t0, $a0	# address of virtual_register[rs]
		lw		$t1, 0($t0)		# content of virtual_register[rs]
		
		sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		lw		$t2, 0($t0)		# content of virtual_register[rt]
		
		beq		$t1, $t2, fetch # condition not met
		sll		$t0, $t5, 2		# offset * 4
		add		$a3, $a3, $t0	# pc = pc + branch offset
		j		fetch

_addi:	sll		$t0, $t3, 2		# rs * 4
		add		$t0, $t0, $a0	# address of virtual_register[rs]
		lw		$t0, 0($t0)		# content of virtual_register[rs]
		
		add		$t2, $t0, $t5	# add immediate
		
		sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		sw		$t2, 0($t0)		# store in virtual_register[rt]
		j		fetch		
		
_slti:	sll		$t0, $t3, 2		# rs * 4
		add		$t0, $t0, $a0	# address of virtual_register[rs]
		lw		$t0, 0($t0)		# content of virtual_register[rs]
		
		slt		$t2, $t0, $t5	# set less than
	
		sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		sw		$t2, 0($t0)		# store in virtual_register[rt]
		j		fetch

_andi:	sll		$t0, $t3, 2		# rs * 4
		add		$t0, $t0, $a0	# address of virtual_register[rs]
		lw		$t0, 0($t0)		# content of virtual_register[rs]
		
		and		$t2, $t0, $t5	# and immediate
	
		sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		sw		$t2, 0($t0)		# store in virtual_register[rt]
		j		fetch
		
_lui:	sll		$t2, $t5, 16	# isolate lower half into upper
			
		sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		sw		$t2, 0($t0)		# store in virtual_register[rt]
		j		fetch
		
_lw:	sll		$t0, $t3, 2		# rs * 4
		add		$t0, $t0, $a0	# address of virtual_register[rs]
		lw		$t0, 0($t0)		# content of virtual_register[rs]
		
		add		$t0, $t0, $t5	# add immediate
		add		$t0, $t0, $a1	# address of virtual_memory[rs + offset]
		lw		$t2, 0($t0)		# content of virtual_memory[rs + offset]
	
		sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		sw		$t2, 0($t0)		# store in virtual_register[rt]
		j		fetch	
		
_sw:	sll		$t0, $t4, 2		# rt * 4
		add		$t0, $t0, $a0	# address of virtual_register[rt]
		lw		$t2, 0($t0)		# content of virtual_register[rt]
	
		sll		$t0, $t3, 2		# rs * 4
		add		$t0, $t0, $a0	# address of virtual_register[rs]
		lw		$t0, 0($t0)		# content of virtual_register[rs]
		
		add		$t0, $t0, $t5	# add immediate
		add		$t0, $t0, $a1	# address of virtual_memory[rs + offset]
		sw		$t2, 0($t0)		# content of virtual_memory[rs + offset]
		j		fetch			

# Wrap it up

_nop:	
		move	$s4, $a0		# save a0
		
		la		$a0, str3		# R
		li		$v0, 4
		syscall
		move	$a0, $s0
		li		$v0, 1
		syscall
		la		$a0, retn
		li		$v0, 4
		syscall

		la		$a0, str4		# I
		li		$v0, 4
		syscall
		move	$a0, $s1
		li		$v0, 1
		syscall
		la		$a0, retn
		li		$v0, 4
		syscall

		la		$a0, str5		# J
		li		$v0, 4
		syscall
		move	$a0, $s2
		li		$v0, 1
		syscall
		la		$a0, retn
		li		$v0, 4
		syscall

		move	$a0, $s4		# restore a0
		lw		$v0, 8($a0)		# load virtual v0 into real v0
		move	$v1, $s3		# load instruction count into v1
		
		lw		$s0, 0($sp)
		lw		$s1, 4($sp)
        lw		$s2, 8($sp)
        lw		$s3, 12($sp)
        lw		$s4, 16($sp)
        lw		$fp, 20($sp)
        lw 		$ra, 24($sp)
        addiu	$sp, $sp, 32	# stack frame 32 bytes long
        
		jr		$ra
		
		#####  END YOUR CODE HERE !!!!!!!!!!!!

		# Here are some guidelines about how you might want to 
		# approach this problem:
		#
		# 1. Fetch the instruction from memory. 
		#    To facilitate this, you will need to implement a
		#    "virtual" PC. The PC points to the address of the next
		#    instruction. 
		# 
		# 2. Decode the instruction
		#    a. Determine the opcode (and function field ... if
		#       applicable)
		#    b. Read the rs and rt registers.
		#
		# 3. Now you know the kind of instruction you are
		#    executing. Use your opcode (and function field)
		#    to branch to a code block that will do what the 
		#    opcode (and function field) dictates.
		#
		# Reminders:
		# ===============
		# 1. Do not forget to increment your virtual PC after each
		#    instruction fetch.
		#
		# 2. Remember that jumps change your virtual PC and that
		#    branches *may* change your virtual PC.
		#
		# 3. Before you return to the shell, make sure you load 
        #    the real $v0 register with the value stored in you
		#    virtual $v0 register.
		#    

