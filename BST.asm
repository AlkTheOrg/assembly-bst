.data
#  list of integers to be used
#valNodes: .word 8, 3, 6, 10, 13, -9999, 7, 4, 5, -9999
valNodes: .word 8, 3, 6, 6, 10, 13, 7, 4, 5, -9999
#valNodes: .word 15, 5, 25, 1, 35, 45 -9999
#valNodes: .word 15, 5, 25, -9999 
newline: .asciiz "\n" # newline space
findUnsuccessful: .asciiz "Find operation is unsuccessful\n"
findSuccessful: .asciiz "Result of the find: "

.text
.globl main

#===================================================================
 #=========================     MAIN    ===========================
#===================================================================
main:
####################################
#-> getting ready for the BUILD function

	# memory allocation for the root of the tree
	li $a0, 16
	li $v0, 9
	syscall

	la $a0, valNodes # address of the valNodes as 1st argument to build function
	
	move $s0, $v0 # s0 will hold the address of the root until program terminates
	move $a1, $s0 # we pass it as the second argument to build

	jal build

	jal printRoot
	jal printLeftChildOfRoot
	jal printRightChildOfRoot
	jal print2ndRightChildOfRoot
#<- end of build function
####################################
#-> getting ready for FIND function
	#li $a0, 13 # search value
	li $a0, 15
	move $a1, $s0 # adress of the root
	jal find

	#-> Test prints below

		# loads 0 or 1 based on the result
		move $a0, $v0 
		bne $zero, $a0, printUnsuccessfulFind
		j printSuccessfulFind
	find_test_end:
	#<- end of test prints

#<- end of find function
####################################
#-> getting ready for PRINT function
	move $a0, $s0 # root as input
	jal print
#<- end of print function
####################################
# terminating the program
	li $v0, 10
	syscall


#===================================================================
 #========================     BUILD    ===========================
#===================================================================
# build assumes there is at least one integer on the list
# Parameters:: a0: list, a1: tree
build:
	addi $sp, $sp, -8 # allocation of 2 words in stack pointer
	sw $a0, 0($sp) # where we store the first argument
	sw $ra, 4($sp) # and the current ra

	move $t1, $a0 # starting address of the list
	lw $t2, 0($t1) # load first element of the list

	sw $t2, 0($a1) # value of the node = first elem of the list
	sw $zero, 4($a1) # no left child
	sw $zero, 8($a1) # no right child
	sw $zero, 12($a1) # no parent

# calls insert function until current list number becomes -9999
build_loop:
	addi $t1, $t1, 4 # next element's address on the list
	lw $t2, 0($t1) # next(current for $t1) element

	move $a0, $t2 # passing it as an argument to insert
	li $t3, -9999 # loading the max neg int to compare

	beq $a0, $t3, build_end # break the loop if end of the list
	jal insert # call insert method
	j build_loop # loop

build_end:
	# free the memory allocated for this procedure at stack
	lw $ra, 4($sp)
	lw $a0, 0($sp)
	addi $sp, $sp, 8

	jr $ra

#===================================================================
 #=======================     INSERT    ===========================
#===================================================================
# assumes the number and the root are legit
# Parameters:: a0: value, a1: tree
# Return Values:: v0: address of the new node where the value inserted in
insert:
	addi $sp, $sp, -4 # allocating memory for storing first parameter
	sw $a0, 0($sp) # we will need register a0 for sbrk call
	move $t4, $a0 # value parameter will be held at t4
	move $t5, $a1 # root node, but will be used as CURRENT NODE variable

	# allocating memory for the new node
	li $a0, 16
	li $v0, 9
	syscall

	sw $t4, 0($v0) # value is stored at the node
	sw $zero, 4($v0) # no left child
	sw $zero, 8($v0) # no right child
	sw $zero, 12($v0) # no parent YET!

insert_loop:
	lw $t6, 0($t5) # get the value of the current node to t6
	blt $t4, $t6, insert_to_left # if value less then currentNode's value, insert_to_left
	bge $t4, $t6, insert_to_right # if value greater then or equal to currentNode's value, insert_to_left

# if the left child is empty, makes the left child connection of the currentNode to newNode and vice versa
insert_to_left:
	lw $t7, 4($t5) # get the left child of the current node
	bne $zero, $t7, insert_to_next # if it is not empty, make it current node
	sw $t5, 12($v0) # newNode.parent = currentNode
	sw $v0, 4($t5) # currentNode.leftChild = newNode
	j insert_end # end loop

# if the right child is empty, makes the right child connection of the currentNode to newNode and vice versa
insert_to_right:
	lw $t7, 8($t5) # get the right child of the current node
	bne $zero, $t7, insert_to_next # if it is not empty, make it current node
	sw $t5, 12($v0) # newNode.parent = currentNode
	sw $v0, 8($t5) # currentNode.rightChild = newNode
	j insert_end # end loop

# change the current node with the left or right child and keep looping until an empty legit child found
insert_to_next:
	move $t5, $t7 # left or right child of the current node becomes current node
	j insert_loop # keep looking for an empty child

insert_end:
	lw $a0, 0($sp) # reloading the first parameter from stack
	addi $sp, $sp, 4
	jr $ra


#===================================================================
 #========================     FIND    ============================
#===================================================================
# Parameters:: a0: value; a1: tree
# Return Values:: v0: search result (0 or 1); v1: addres of the found value if any
find:
	move $t1, $a1 # currentNode = rootNode

find_loop:
	beq $t1, $zero, find_fail # if currentNode is empty, it failed 

	# otherwise keep looking
	lw $t2, 0($t1) # currentNode's value
	beq $a0, $t2, find_success
	blt $a0, $t2, find_on_left
	bgt $a0, $t2, find_on_right

# makes the left child, currentNode and jumps back to the find_loop
find_on_left:
	lw $t3, 4($t1) # left child of the currentNode
	move $t1, $t3 # becomes the currentNode
	j find_loop

# makes the right child, currentNode and jumps back to the find_loop
find_on_right:
	lw $t3, 8($t1) # right child of the currentNode
	move $t1, $t3 # becomes the currentNode
	j find_loop

# makes v0 0 and loads the address of the found value to v1
find_success:
	li $v0, 0
	move $v1, $t1
	j find_end

# makes v0 1
find_fail:
	li $v0, 1

find_end:
	jr $ra

#===================================================================
 #=======================     PRINT    ============================
#===================================================================
# Parameters:: a0: tree
# Assumes the tree is valid.
#!! IT ONLY PRINTS THE NUMBERS. SKIPS THE EMPTY CHILDS
print:
	addi $sp, $sp, -8 # allocation of 2 words in stack pointer
	sw $ra, 0($sp) # where we store the current ra
	sw $a0, 4($sp) # and the first parameter
	move $t0, $a0 # t0 will hold the tree

queue_init:
	# allocating memory for the queue head node
		# 8 bytes:
		# 4 bytes for the address of the node from tree
		# 4 bytes for the nextQueueNode's address
	li $a0, 8
	li $v0, 9
	syscall
	move $s3, $v0 # s3 will hold the head(front) node of the queue. $zero means empty

	sw $t0, 0($s3) # head holds the address of the root on initialization
	sw $zero, 4($s3) # nextQueueNode is zero atm

	## Test code to print the root's value from headQueueNode
		#lw $t5, 0($s3)
		#lw $t6, 0($t5)
		#move $a0, $t6
		#li $v0, 1
		#syscall
	## end of the test code

print_loop:
	beq $zero, $s3, print_end # if queue empty, jump to end

	lw $t1, 0($s3) # loads the headQueueNode's treeNodeAddress
	lw $a0, 0($t1) # loads the treeNode's value to print
	li $v0, 1
	syscall
	# print space, 32 is ASCII code for space
	li $a0, 32
	li $v0, 11  # syscall number for printing character
	syscall

	# getting children of the node before removing node from queue
	lw $t2, 4($t1) # left child
	jal queue_add # add left child to the queue
	lw $t2, 8($t1) # right child
	jal queue_add # add right child to the queue

	# remove the previous head from quee
	jal queue_remove

	j print_loop

# adds a new queueNode to the queue's back. treeNode must be at $t2
# if treeNode is $zero, it skips adding it
queue_add:
	beq $zero, $t2, queue_add_end # if empty child, skip it
	#otherwise make space for the new queueNode
	li $a0, 8
	li $v0, 9
	syscall
	move $t4, $v0 # address of the new queueNode
	sw $t2, 0($t4) # holds the addres of the treeNode
	sw $zero, 4($t4) # newQueueNode.nextNode = null; as it is the tail

	move $t3, $s3 # currentQueueNode = headQueueNode

# for finding the tail of the queue and placing it to the currentQueueNode
queue_add_loop:
	lw $t5, 4($t3) # loads the currentQueueNode.next
	beq $zero, $t5, queue_add_end # if no next, add newQueueNode to currentNode
	move $t3, $t5 # else: make the next node, currentQueueNode and keep looping
	j queue_add_loop

queue_add_end:
	sw $t4, 4($t3) # currentQueueNode.next = newQueueNode
	jr $ra

# makes the next node the new head node
queue_remove:
	lw $t5, 4($s3) # nextQNode = headQueueNode.next
	move $s3, $t5 # head = nextQNode
	jr $ra

print_end:
	lw $ra, 0($sp) # reloading previous $ra value
	lw $a0, 4($sp) # reloading the first parameter
	addi $sp, $sp, 8 # increasing the stack pointer back
	jr $ra # jumping back

#===================================================================
#===================================================================
 #==================     MY TEST FUNCTIONS    =====================
#===================================================================
#===================================================================
# prints the all values that the root node holds
printRoot:
	lw $a0, 0($s0)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	lw $a0, 4($s0)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	lw $a0, 8($s0)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	lw $a0, 12($s0)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	jr $ra

printLeftChildOfRoot:
	lw $s2, 4($s0) # left child address

	lw $a0, 0($s2)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	lw $a0, 4($s2)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	lw $a0, 8($s2)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	lw $a0, 12($s2)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	jr $ra

printRightChildOfRoot:
	lw $s2, 8($s0) # right child address

	lw $a0, 0($s2)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	lw $a0, 4($s2)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	lw $a0, 8($s2)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	lw $a0, 12($s2)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	jr $ra

print2ndRightChildOfRoot:
	lw $s2, 8($s0) # right child address
	lw $t1, 8($s2) # right child of the right child above
	move $s2, $t1

	lw $a0, 0($s2)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	lw $a0, 4($s2)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	lw $a0, 8($s2)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	lw $a0, 12($s2)
	li $v0, 1
	syscall
	la $a0, newline
	li $v0, 4
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	jr $ra

# On successfull find, it moves the result value in order to print
printSuccessfulFind:
	la $a0, findSuccessful
	li $v0, 4
	syscall

	lw $a1, 0($v1) # value from the found adress
	move $a0, $a1
	li $v0, 1
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	j find_test_end

printUnsuccessfulFind:
	la $a0, findUnsuccessful
	li $v0, 4
	syscall
	la $a0, newline
	li $v0, 4
	syscall

	j find_test_end