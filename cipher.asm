# Menu options
# r - read text buffer from file 
# p - print text buffer
# e - encrypt text buffer
# d - decrypt text buffer
# w - write text buffer to file
# g - guess the key
# q - quit

.data
MENU:              .asciiz "Commands (read, print, encrypt, decrypt, write, guess, quit):"
REQUEST_FILENAME:  .asciiz "Enter file name:"
REQUEST_KEY: 	 .asciiz "Enter key (upper case letters only):"
REQUEST_KEYLENGTH: .asciiz "Enter a number (the key length) for guessing:"
REQUEST_LETTER: 	 .asciiz "Enter guess of most common letter:"
ERROR:		 .asciiz "There was an error.\n"

FILE_NAME: 	.space 256	# maximum file name length, should not be exceeded
KEY_STRING: 	.space 256 	# maximum key length, should not be exceeded

.align 2		# ensure word alignment in memory for text buffer (not important)
TEXT_BUFFER:  	.space 10000
.align 2		# ensure word alignment in memory for other data (probably important)
# TODO: define any other spaces you need, for instance, an array for letter frequencies

Frequency: 	.space 104  #Array to store 26 integers, corresponding to frequency of A-Z of text_buffer
##############################################################


.text
		move $s1 $0 	# Keep track of the buffer length (starts at zero)
MainLoop:	li $v0 4		# print string
		la $a0 MENU
		syscall
		li $v0 12	# read char into $v0
		syscall
		move $s0 $v0	# store command in $s0			
		jal PrintNewLine

		beq $s0 'r' read
		beq $s0 'p' print
		beq $s0 'w' write
		beq $s0 'e' encrypt
		beq $s0 'd' decrypt
		beq $s0 'g' guess
		beq $s0 'q' exit
		b MainLoop

read:		jal GetFileName
		li $v0 13	# open file
		la $a0 FILE_NAME 
		li $a1 0		# flags (read)
		li $a2 0		# mode (set to zero)
		syscall
		move $s0 $v0
		bge $s0 0 read2	# negative means error
		li $v0 4		# print string
		la $a0 ERROR
		syscall
		b MainLoop
read2:		li $v0 14	# read file
		move $a0 $s0
		la $a1 TEXT_BUFFER
		li $a2 9999
		syscall
		move $s1 $v0	# save the input buffer length
		bge $s0 0 read3	# negative means error
		li $v0 4		# print string
		la $a0 ERROR
		syscall
		move $s1 $0	# set buffer length to zero
		la $t0 TEXT_BUFFER
		sb $0 ($t0) 	# null terminate the buffer 
		b MainLoop
read3:		la $t0 TEXT_BUFFER
		add $t0 $t0 $s1
		sb $0 ($t0) 	# null terminate the buffer that was read
		li $v0 16	# close file
		move $a0 $s0
		syscall
		la $a0 TEXT_BUFFER
		jal ToUpperCase
print:		la $a0 TEXT_BUFFER
		jal PrintBuffer
		b MainLoop	

write:		jal GetFileName
		li $v0 13	# open file
		la $a0 FILE_NAME 
		li $a1 1		# flags (write)
		li $a2 0		# mode (set to zero)
		syscall
		move $s0 $v0
		bge $s0 0 write2	# negative means error
		li $v0 4		# print string
		la $a0 ERROR
		syscall
		b MainLoop
write2:		li $v0 15	# write file
		move $a0 $s0
		la $a1 TEXT_BUFFER
		move $a2 $s1	# set number of bytes to write
		syscall
		bge $v0 0 write3	# negative means error
		li $v0 4		# print string
		la $a0 ERROR
		syscall
		b MainLoop
		write3:
		li $v0 16	# close file
		move $a0 $s0
		syscall
		b MainLoop

encrypt:		jal GetKey
		la $a0 TEXT_BUFFER
		la $a1 KEY_STRING
		jal EncryptBuffer
		la $a0 TEXT_BUFFER
		jal PrintBuffer
		b MainLoop

decrypt:		jal GetKey
		la $a0 TEXT_BUFFER
		la $a1 KEY_STRING
		jal DecryptBuffer
		la $a0 TEXT_BUFFER
		jal PrintBuffer
		b MainLoop

guess:		li $v0 4		# print string
		la $a0 REQUEST_KEYLENGTH
		syscall
		li $v0 5		# read an integer
		syscall
		move $s2 $v0
		
		li $v0 4		# print string
		la $a0 REQUEST_LETTER
		syscall
		li $v0 12	# read char into $v0
		syscall
		move $s3 $v0	# store command in $s0			
		jal PrintNewLine

		move $a0 $s2
		la $a1 TEXT_BUFFER
		la $a2 KEY_STRING
		move $a3 $s3
		jal GuessKey
		li $v0 4		# print String
		la $a0 KEY_STRING
		syscall
		jal PrintNewLine
		b MainLoop

exit:		li $v0 10 	# exit
		syscall

###########################################################
PrintBuffer:	li $v0 4          # print contents of a0
		syscall
		li $v0 11	# print newline character
		li $a0 '\n'
		syscall
		jr $ra

###########################################################
PrintNewLine:	li $v0 11	# print char
		li $a0 '\n'
		syscall
		jr $ra

###########################################################
PrintSpace:	li $v0 11	# print char
		li $a0 ' '
		syscall
		jr $ra

#######################################################
GetFileName:	addi $sp $sp -4
		sw $ra ($sp)
		li $v0 4		# print string
		la $a0 REQUEST_FILENAME
		syscall
		li $v0 8		# read string
		la $a0 FILE_NAME  # up to 256 characters into this memory
		li $a1 256
		syscall
		la $a0 FILE_NAME 
		jal TrimNewline
		lw $ra ($sp)
		addi $sp $sp 4
		jr $ra

###########################################################
GetKey:		addi $sp $sp -4
		sw $ra ($sp)
		li $v0 4		# print string
		la $a0 REQUEST_KEY
		syscall
		li $v0 8		# read string
		la $a0 KEY_STRING  # up to 256 characters into this memory
		li $a1 256
		syscall
		la $a0 KEY_STRING
		jal TrimNewline
		la $a0 KEY_STRING
		jal ToUpperCase
		lw $ra ($sp)
		addi $sp $sp 4
		jr $ra

###########################################################
# Given a null terminated text string pointer in $a0, if it contains a newline
# then the buffer will instead be terminated at the first newline
TrimNewline:	lb $t0 ($a0)
		beq $t0 '\n' TNLExit
		beq $t0 $0 TNLExit	# also exit if find null termination
		addi $a0 $a0 1
		b TrimNewline
TNLExit:		sb $0 ($a0)
		jr $ra

##################################################
# converts the provided null terminated buffer to upper case
# $a0 buffer pointer
ToUpperCase:	lb $t0 ($a0)
		beq $t0 $zero TUCExit
		blt $t0 'a' TUCSkip
		bgt $t0 'z' TUCSkip
		addi $t0 $t0 -32	# difference between 'A' and 'a' in ASCII
		sb $t0 ($a0)
TUCSkip:		addi $a0 $a0 1
		b ToUpperCase
TUCExit:		jr $ra

###################################################
# END OF PROVIDED CODE... 
# TODO: use this space below to implement required procedures
###################################################



##################################################
# null terminated buffer is in $a0
# null terminated key is in $a1
EncryptBuffer:	# TODO: Implement this function!
	addi $sp, $sp, -32
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp) #store the encrypted string
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	move $s5, $a1 #not modified key in s5
	
	
Loop: 
	lb $s2, ($a0) 		#load a char from text to s2
	beq $s2, '\0', Exit 	#if reach Null, exit
	jal IsChar
	beq $v0, 1, CheckKey #if current char is in A-Z, branch to CheckKey, then encrypted
	
	#if current char is not A-Z
	# sb $s2, ($a0) #store current char to a0
	addi $a0, $a0, 1 #increment address of a0
	lb $s4, ($a1) #current key letter -> s4
	addi $a1, $a1, 1
	bne $s4, '\0', Loop #loop if key hasnt reached Null
	#else if key reached null
	move $a1, $s5 #restore key
	addi $a1, $a1, 1  		
	j Loop

CheckKey: 
	#check if key has reached end
	lb $s4, ($a1) #load key
	#give argument to encrypt:
	move $s6, $s2 #set current Char as s6
	bne $s4, '\0', Encrypt #not reach end, directly go to encrypt
	#else, if reached null, restore
	move $a1, $s5 #restore key

Encrypt:
	lb $s0, ($a1) #current key in s0
	jal EncryptChar
	sb $v0, ($a0) #store encrypted char to a0    		##NOT STORING??
	addi $a1, $a1, 1 #increment key
	addi $a0, $a0, 1 
	j Loop

Exit: 
	
	#addi $a0, $a0, 1
	#sb $s2, ($a0) #$s2 has '\0'
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp) #store the encrypted string
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	addi $sp, $sp, 32
	jr $ra

#subroutine, encrypt a char (s6) with key (a1), encrypted char stored in v0
EncryptChar: 
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s1, 4($sp)
				
	subi $s6, $s6, 'A' 	#subtract 'A' from char(a0), s0 = charValue between 0-25 A=0, B=1...
	subi $s1, $s0, 'A' 	#subtract 'A' from key (a1), s1 = key (0-25)
	add $s6, $s6, $s1 	#add key to charValue
	li $s1, 26
	#if exceed 26, s0 mod 26 (goes back from a)
	divu $s6, $s1 		#remainder stored in HI
	mfhi $s6 		#store remainder in s0 
	addi $v0, $s6, 'A' 	#encryped char stored in v0
	
	#restore stack
	lw $ra, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	jr $ra
	
IsChar: #check if s2 is A-Z
#if it's in A-Z v0=1 (true), if not v0=0 (false
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	blt $s2, 'A', NotChar
	bgt $s2, 'Z', NotChar		#goes to NotChar
	li $v0, 1 	#else, isChar (v0=1, true)
	j EndIsChar
	
	
NotChar: #not char, v0=0 (false)
	li $v0, 0
	
EndIsChar: 
	 #restore stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

		

##################################################
# null terminated buffer is in $a0
# null terminated key is in $a1
DecryptBuffer:	# for each word, subtract the key
		
	addi $sp, $sp, -32
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp) #store the encrypted string
	sw $s4, 20($sp)
	sw $s5, 24($sp)
	sw $s6, 28($sp)
	move $s5, $a1 #not modified key in s5
	
	
DeLoop: 
	lb $s2, ($a0) 		#load a char from text to s2
	beq $s2, '\0', DeExit 	#if reach Null, exit
	jal IsChar
	beq $v0, 1, DeCheckKey #if current char is in A-Z, branch to CheckKey, then encrypted
	
	#if current char is not A-Z
	# sb $s2, ($a0) #store current char to a0
	addi $a0, $a0, 1 #increment address of a0
	lb $s4, ($a1) #current key letter -> s4
	addi $a1, $a1, 1
	bne $s4, '\0', DeLoop #loop if key hasnt reached Null
	#else if key reached null
	move $a1, $s5 #restore key
	addi $a1, $a1, 1
	j DeLoop

DeCheckKey: 
	#check if key has reached end
	lb $s4, ($a1) #load key
	#give argument to encrypt:
	move $s6, $s2 #set current Char as s6
	bne $s4, '\0', Decrypt #not reach end, directly go to encrypt
	#else, if reached null, restore
	move $a1, $s5 #restore key

Decrypt:
	lb $s0, ($a1) 	#current key in s0
	jal DecryptChar
	sb $v0, ($a0) #store encrypted char to a0    		
	addi $a1, $a1, 1 #increment key
	addi $a0, $a0, 1 
	j DeLoop

DeExit: 
	addi $a0, $a0, 1
	sb $s2, ($a0) #$s2 has '\0'
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp) #store the encrypted string
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	addi $sp, $sp, 32
	jr $ra



#subroutine, decrypt a char (s6) with key (s0), decrypted char stored in v0
DecryptChar: 
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s1, 4($sp)

	subi $s6, $s6, 'A' 	#subtract 'A' from char(s6), s6 = charValue between 0-25 A=0, B=1...
	subi $s1, $s0, 'A' 	#subtract 'A' from key (a1), s1 = key (0-25)
	sub $s6, $s6, $s1 	#subtract key to get charValue (s6)
	
	slt $t6, $s6, $zero
	beq $t6, $zero, DeCont  #if $s6>=$zero, branch to DeCont
	
	# else if s6 is negative, v0 = '[' + s6
If_Negative: 
	addi $v0, $s6, '['
	j Exit_DeCryptChar

DeCont:		
	li $s1, 26
	#if exceed 25, s0 mod 26 (goes back from A)
	divu $s6, $s1 		#remainder stored in HI
	mfhi $s6 		#store remainder in s0 
	addi $v0, $s6, 'A' 	#encryped char stored in v0
	
Exit_DeCryptChar:
	#restore stack
	lw $ra, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	jr $ra
	
DeIsChar: #check if a0 is A-Z
#if it's in A-Z v0=1 (true), if not v0=0 (false
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	blt $s0, 'A', DeNotChar
	bgt $s0, 'Z', DeNotChar
	li $v0, 1 #else, isChar (v0=1, true)
	j DeEndIsChar
	
	
DeNotChar: #not char, v0=0 (false)
	li $v0, 0
	
DeEndIsChar: 
	 #restore stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


###########################################################
# a0 keySize - size of key length to guess
# a1 Buffer - pointer to null terminated buffer to work with
# a2 KeyString - on return will contain null terminated string with guess
# a3 common letter guess - for instance 'E' 

#Key Length = 2
# extract two arrays (index of 1, 3, 5, 7… ) and (index of 2, 4, 6, 8) from cipher text

GuessKey:

	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp) #counter
	sw $s3, 12($sp) #index
	move $s2, $zero
	
G_Loop: 	
	#while s2 < n (a0) - loop through whole thing n times (find n keys)
	
	slt $t0, $s2, $a0
	beq $t0, $zero, G_Exit 		#if s2>n (a0), branch to G-Exit
	addi $s2, $s2, 1  		#increment s2
	move $s3, $s2
	subi $s3, $s3, 1
	
	
EmptyFrequency: #empty Frequency space
	# $t0 from 0 to 103, sb $zero into Frequency
	move $t2, $zero
	addi $t2, $t2, 104
	move $t0, $zero
	
EmptyLoop:
	slt $t3, $t0, $t2  # if t0 >= 104 (t2) exit loop
	beq $t3, $zero, ExitEmpty
	sb $zero, Frequency($t0)  #else, store zero in Frequency
	addi $t0, $t0, 1 #increment to next
	j EmptyLoop
	
ExitEmpty: 	
	
LoopKey: 
	
	#iterating a1 in n's (n is in $a0)
	lb $s1, TEXT_BUFFER($s3)	 # for each character, store in $s1 		
	add $s3, $s3, $a0 		#for next loop, incrementing index
	beq $s1, '\0', MostCommonChar	# check if a char is '\0' if is, jump to MostCommonChar
	
	#check if s1 is a character before going forward
	# Use Key_IsChar from EncryptBuffer
	jal Key_IsChar
	
	beq $v0, $zero, LoopKey		#if not s1 is not a character (v0=0), LoopKey
	
	#increment frequency array of current character's corresponding index, for example if currentChar = A, add 1 to index 0 of Frequency
	# index to store = t0 = 4 times (char minus ‘A’)
	subi $t0, $s1, 'A'
	addi $t1, $zero, 4
	mul $t0, $t0, $t1
	
	# add 1 to Frequency($t0)
	lw $t1, Frequency($t0) 	#store current frequncy at $t0th index in t1
	addi $t1, $t1, 1	#add 1 to corresponding frequncy
	sw $t1, Frequency($t0)	#store in right index of Freqeuncy array
	
	j LoopKey

MostCommonChar: 

	add $t0, $zero, $zero	#t0 is index
	move $t2, $zero 	#t2 = highest Frequency
	
LoopFrequency: 
	#t0 to keep track of index in Frequency
	
	# find highest value in Frequency - store in t1, t0 is index
	# store highest frequency in t2
	
	lw $t1, Frequency($t0) 	#for each frequency at index t0
	# if t1 > t2, t2 = t1, v0 = t0 (jal GreaterFrequency)
	slt $t3, $t2, $t1
	bne $t3, $zero, GreaterFrequency
	addi $t0, $t0, 4	#increment index to next register	
	
	# exit when t0 reaches 100 (looped through entire loop)
	beq $t0, 104, FindKey
	j LoopFrequency

GreaterFrequency: 

	#t2 = t1
	#v0 = t0
	move $t2, $t1
	move $v0, $t0
	addi $t0, $t0, 4	#increment index to next register
	
	j LoopFrequency

FindKey: #stores ith keyLetter calculated in a2 given v0 (commonChar of ith array) and a3
	
	#v0 is the index (0-104) in Frequency array corresponding to most frequent character
	#ex. 0 = A, 4= B, ... 60 = P
	
	#common char is 60 divide by 4 + 'A' - store in v0
	addi $t0, $zero, 4
	div $v0, $v0, $t0  #t0/4
	addi $v0, $v0, 'A'
	
	# letterGuess (a3) + key = commonChar (v0)
	
	# if commonChar (v0) < letterGuess (a3)
	# key = '[' - letterGuess (a3) + commonChar
	slt $t0, $v0, $a3 	# if commonChar (v0) < letterGuess (a3)
	bne $t0, $0, StoreKey
	
	# else: key =  commonChar (v0) - letterGuess (a3)
	sub $v0, $v0, $a3
	addi $v0, $v0,'A'
	sb $v0, ($a2)
	addi $a2, $a2, 1 	#increment a2
	j G_Loop 
	
StoreKey: 
	# if commonChar (v0) < letterGuess (a3)
	# key = '[' - letterGuess (a3) + commonChar (v0)
	#$t0 = '[' - letterGuess (a3)
	
	subi $t0, $a3, '[' 	#negative 
	subu $t0, $zero, $t0	 #make t0 positive
	add $v0, $v0, $t0 	#v0 holds the key
	sb $v0, ($a2)		#store key
	addi $a2, $a2, 1	#increment a2
	j G_Loop



G_Exit:	
		addi $t0, $t0, '\0'
		sb $t0, ($a2)		#end a2 with /0	
		addi $a2, $a2, 1
		lw $ra, 0($sp)
		lw $s1, 4($sp)
		lw $s2, 8($sp)
		lw $s3, 12($sp)
		addi $sp, $sp, 16
		jr $ra
		
Key_IsChar: #check if s1 is A-Z
#if it's in A-Z v0=1 (true), if not v0=0 (false
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	blt $s1, 'A', Key_NotChar
	bgt $s1, 'Z', Key_NotChar		#goes to NotChar
	li $v0, 1 	#else, isChar (v0=1, true)
	j Key_EndIsChar
	
	
Key_NotChar: #not char, v0=0 (false)
	li $v0, 0
	
Key_EndIsChar: 
	 #restore stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
