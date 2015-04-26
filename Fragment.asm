	.text
main:

jal reader #store the input into memory
jal printInput
jal fragment
jal exit


	#===============================================================
	# reader- Read in the text file for conversion to binary
	#===============================================================
reader:
	subu $sp, 20 #save our registers
	sw $ra, ($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)

	jal readInput


	jal removeNewLines


	#get a register for message address
	la $s0, message
	la $s3, buffer #get a register for the buffer address

readerBigLoop: #each time a big loop executes, a word of data will be saved into memory
	li $s1, 0 #create a word
	li $s2, 0 #create a counter

readerLittleLoop: #each time a little loop executes, a byte of the input stream will be converted into a bit
	move $a0, $s3  #load parameters
	lb $t0, ($s3)
	beq $t0, $zero, readerExit #if the byte is the null charcter we are done reading
	
	jal convert
	sll $s1, $s1, 1 #move our current word of data over be one to make room for a new bit
	or $s1, $s1, $v0 #or the current word with the return value from convert
	addiu $s2, $s2, 1
	addiu $s3, $s3, 1 #increment counter and buffer place
	li $t0, 32
	bne $s2, $t0, readerLittleLoop #if our word isn't full, continue adding bits
	sw $s1, ($s0) #save word of data into memory
	addiu $s0, $s0, 4
	b readerBigLoop


readerExit:
	lw $s3, 16($sp)
	lw $s2, 12($sp)
	lw $s1, 8($sp)
	lw $s0, 4($sp)
	lw $ra, ($sp) #reload our registers
	addu $sp, 20
	jr $ra


	#===============================================================
	# convert - converts a string byte to binary bit
	# - $a0: address of the byte to convert
	# => $v0 = the binary conversion for the bit
	#===============================================================
convert:
	subu $sp, 4
	sw $ra, ($sp)
	lb $t0, ($a0)

	li $t1, 48#ascii 0 value
	li $t2, 49 #ascii 1 value

	beq $t0, $t1, returnZero
	beq $t0, $t2, returnOne

	la $a0, illegalCharacter #not a 1 or a 0
	li $v0, 4
	syscall #print illegal character error message and exit the script
	b exit

returnZero:
	li $v0, 0
	b convertReturn

returnOne:
	li $v0, 1

convertReturn:
	lw $ra, ($sp)
	addu $sp, 4
	jr $ra


	#===============================================================
	# removeNewLines- removes all the new line characters from the buffer to make formatting in the text document easier
	#===============================================================
removeNewLines:
	li $t0, 0 #initialize counter
	la $t1, buffer  #initialize buffer location

removeNewLinesLoop:
	lb $t2, ($t1) #load byte from location in buffer

	li $t3, 13 #carriage return ascii value
	beq $t2, $t3, deleteCarriageReturn

	subu $t4, $t1, $t0 #calculate the location of the buffer minus the counter
	sb $t2, ($t4)

	beq $t2, $zero, removeNewLinesEnd #if byte just moved is null, end the loop

	addiu $t1, $t1, 1 #increment the buffer location
	b removeNewLinesLoop


deleteCarriageReturn:
	addiu $t0, $t0, 2 #increment the counter to indicate that we have passed a carriage return
	addiu $t1, $t1, 2 #increment the buffer location
	b removeNewLinesLoop


removeNewLinesEnd:
	jr $ra

	
	#===============================================================
	# readInput - read every line from the input file
	#===============================================================
readInput:
	la $a0, buffer
	li $a1, 100
	li $v0, 8

readLine:
	syscall  #read the text file into a buffer
	lb $t0, ($a0)
	beq $t0, $zero, readInputFinish
	b findNullCharacter

findNullCharacter:
	addiu $a0, $a0, 1
	lb $t0, ($a0)
	beq $t0, $zero, readLine
	b findNullCharacter

readInputFinish:
	jr $ra


	#===============================================================
	# printInput- print the values of the input package
	#===============================================================
printInput:
	subu $sp, 12
	sw $ra, 8($sp)

	#tell the console that this is the package recieved as input
	li $v0, 4
	la $a0, inputAnnounce
	syscall
	
	#load the packet that we recieved
	la $t0, message
	#find the source address and store it
	lw $a0, 12($t0)
	sw $a0, sourceStore
	#find the destination address and store it
	lw $a1, 16($t0)
	sw $a1, destinationStore
	#find the ident and store it 
	lhu $a2, 4($t0)
	sw $a2, identStore
	#load the offset, AND it to drop the flags and store for printPacket call
	lh $t1, 6($t0)
	li $t2, 0x1FFF
	and $a3, $t1, $t2
	sw $a3, offsetStore
	#use the offset load, AND to get M bit and store for printPacket call
	li $t2, 0x2000
	and $t1, $t1, $t2
	srl $t1, $t1, 13
	sw $t1, mBitStore
	sw $t1, ($sp)
	#load the length halfword, and store it
	lh $t1, 2($t0)
	sw $t1, 4($sp)
	sw $t1, sizeStore

	jal printPacket

	lw $ra, ($sp)
	addu $sp, 4
	jr $ra


	#===============================================================
	# printPacket- function to print packet in designated form given packet values
	#$a0 - Source address field
	#$a1 - Destination address field
	#$a2 - Ident field
	#$a3 - Offset field
	#5th arguement - ($sp) - M flag field
	#6th arguement - 4($sp)  - Packet size field 
	#===============================================================
printPacket:
	move $t0, $a0

	#print the header of a packet
	la $a0, packetBorder
	li $v0, 4
	syscall 

	#print the source address
	la $a0, source
	syscall

	move $a0, $t0
	li $v0, 1
	syscall

	#print the destination address
	la $a0, destination
	li $v0, 4
	syscall

	move $a0, $a1
	li $v0, 1
	syscall

	#print the ident field
	la $a0, ident
	li $v0, 4
	syscall

	move $a0, $a2
	li $v0, 1
	syscall

	#print the offset field
	la $a0, offset
	li $v0, 4
	syscall

	move $a0, $a3
	li $v0, 1
	syscall

	#print the M flag field
	la $a0, mFlag
	li $v0, 4
	syscall

	lw $a0, ($sp)
	li $v0, 1
	syscall

	#print the packet size
	la $a0, size
	li $v0, 4
	syscall

	lw $a0, 4($sp)
	li $v0, 1
	syscall

	#print the packet end border
	la $a0, newLine
	li $v0, 4
	syscall

	la $a0, packetBorder
	syscall
	
	#pop off the stack
	addu $sp, 8

	jr $ra

	#===============================================================
	# fragment- split the packet depending on MTU
	#===============================================================
fragment:
	subu $sp, 4
	sw $ra, ($sp)

	#tell the console that the following packets are fragmented
	li $v0, 4
	la $a0, fragmentAnnounce
	syscall

fragmentStart:
	#load total size
	lw $t0, sizeStore
	#add 20 to account for header
	addiu $t0, $t0, 20
	#load mtu
	lw $t1, mtu
	#if MTU >=Total size+20 (+20 to account for header space)
	bge $t1, $t0, printOriginalPacket
	#Psize = mut
	move $t2, $t1
	#HDR=20
	li $t3, 20
	#DFragSize=Psize-HDR
	subu $t2, $t2, $t3
	#DataSize=Totalsize-HDR
	subu $t4, $t0, $t3
	#if DataSize<=DFragSize
	ble $t4, $t2, printLastPacket
mtuDivisibleBy8Check:
	#ensure that packets sizes are divisible by 8
	li $t5, 8
	div $t2, $t5
	mfhi $t6
	mflo $t7
	bne $t6, $zero, decrementFragSize
	b correctFragSize

decrementFragSize:
	subu $t2, 1
	b mtuDivisibleBy8Check

correctFragSize:
	subu $sp, 8
	#load parameters for call to printPacket
	lw $a0, sourceStore
	lw $a1, destinationStore
	lw $a2, identStore
	lw $a3, offsetStore
	li $t5, 1
	sw $t5, ($sp)
	sw $t2, 4($sp)

	jal printPacket

	#update the size of the remaining packet
	lw $t5, sizeStore
	subu $t5, $t2
	sw $t5, sizeStore

	#update the offset for the remaining packet
	lw $t5, offsetStore
	addu $t5, $t5, $t7
	sw $t5, offsetStore

	b fragmentStart
	
printLastPacket:
	subu $sp, 8
	#load the parameters for call to printPacket
	lw $a0, sourceStore
	lw $a1, destinationStore
	lw $a2, identStore
	lw $a3, offsetStore
	lw $t0, mBitStore
	sw $t0, ($sp)
	sw $t2, 4($sp)
	
	jal printPacket

	lw $ra, ($sp)
	addu $sp, 4
	jr $ra


printOriginalPacket:
	subu $sp, 8
	load the parameters for call to printPacket
	lw $a0, sourceStore
	lw $a1, destinationStore
	lw $a2, identStore
	lw $a3, offsetStore
	lw $t0, mBitStore
	sw $t0, ($sp)
	lw $t1, sizeStore
	sw $t1, 4($sp)
	
	jal printPacket

	lw $ra, ($sp)
	addu $sp, 4
	jr $ra


	#===============================================================
	# exit- cleanly exits the script
	#===============================================================
exit:
	li $v0, 10
	syscall


	

	.data

illegalCharacter: .asciiz "Illegal Character recieved as input.\n"
.align 2
inputAnnounce: .asciiz "The package imported was:\n"
.align 2
fragmentAnnounce: .asciiz "\nThe fragmented package(s) are:\n"
packetBorder: .asciiz "#-------------------------------------------#\n"
.align 2
newLine: .asciiz "\n"
.align 2
source: .asciiz "Source Address: "
.align 2
destination: .asciiz "\nDestination Address: "
.align 2
ident: .asciiz "\nIdent: "
.align 2
offset: .asciiz "\nOffset: "
.align 2
mFlag: .asciiz "\nM flag: "
.align 2
size: .asciiz "\nPacket size: "
.align 2
mtu: .word 44
.align 2
sourceStore: .word 0
.align 2
destinationStore: .word 0
.align 2
identStore: .word 0
.align 2
offsetStore: .word 0
.align 2
mBitStore: .word 0
.align 2
sizeStore: .word 0
.align 2
buffer: .space 1000 #defines a 1000 byte buffer
message: .space 1000 #defines a 1000 byte buffer



