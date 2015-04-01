	.text
main:

jal reader #store the input into memory
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
	# exit- cleanly exits the script
	#===============================================================
exit:
	li $v0, 10
	syscall


	

	.data
buffer: .space 1000 #defines a 1000 byte buffer
message: .space 1000 #defines a 1000 byte buffer
illegalCharacter: .asciiz "Illegal Character recieved as input.\n"
