# int getLineCount(const char *data, int size)
#
#	Returns the number of '\n' characters in the memory pointed to.
#	'data': the address of the first character to look at.
#	'size': the length of the memory area to scan through.
.globl getLineCount
.type getLinecount, @function
getLineCount:
	# rdi: 'data'
	# rsi: 'size'
	addq %rdi, %rsi         # make rsi the past-the-end pointer
	xorq %rax, %rax         # count = 0
.LgetLineCount_loop:
	cmpq %rdi, %rsi
	je .LgetLineCount_end   # if rdi == rsi: we are done
	movb (%rdi), %dl        # load the next byte
	addq $1, %rdi
	cmpb $0xA, %dl          # is it a newline char?
	jne .LgetLineCount_loop # if not, continue in the buffer
	addq $1, %rax           # completed a number
	jmp .LgetLineCount_loop
.LgetLineCount_end:
	ret


# void parseData(const char *data, int size, int *result)
#
#	Converts the ASCII representation of the coordinates into pairs of numbers.
#	'data': the address of the first character in the ASCII representation.
#	'size': the length of the ASCII representation.
#	'result': the address of a piece of memory big enough to hold the
#		coordinates. If there are n coordinates in the input, the 'result'
#		memory will be an array of 2n 8-byte integers, with alternating x and y
#		coordinates.
#
#	Note, this functions only expects unsigned ints in the input and does not
#	perform any validity checks at all.
.globl parseData
.type parseData, @function
parseData:
	addq %rdi, %rsi # make rsi the past-the-end pointer
	push %rsi       # and store it as the top element on the stack
.LparseData_coordinateLoop:
	cmpq (%rsp), %rdi
	je .LparseData_coordinateLoop_end
	movq $9, %rsi      # '\t'
	call parseNumber   # increases rdi to point past-the-end of the number
	movq %rax, (%rdx)  # store the number
	addq $8, %rdx      # point to the next place for a number
	movq $10, %rsi     # '\n'
	call parseNumber   # increases rdi to point past-the-end of the number
	movq %rax, (%rdx)  # store the number
	addq $8, %rdx      # point to the next place for a number
	jmp .LparseData_coordinateLoop
.LparseData_coordinateLoop_end:
	addq $8, %rsp
	ret

# int parseNumber(const char *&data, const char *end)
parseNumber:
	xorq %rax, %rax    # result
.LparseNumber_loop:
	xorq %r10, %r10    # the next digit
	movb (%rdi), %r10b # read character
	addq $1, %rdi      # ++data
	cmpq %rsi, %r10    # done with this number?
	je .LparseNumber_loop_end
	# here we assume that the character is actually a digit
	# add this digit to the current number
	subq $48, %r10     # convert the ASCII code to the digit it represents
	imul $10, %rax     # 'make room' for the new digit
	addq %r10, %rax    # and add the new digit
	jmp .LparseNumber_loop
.LparseNumber_loop_end:
	# we now have a number in rax
	ret
