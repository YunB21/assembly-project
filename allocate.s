# void *allocate(int n)
#
# 	A naive memory allocator that simply retrieves some new space from the OS.
# 	It is not possible to deallocate the memory again.
.globl allocate
.type allocate, @function
allocate:
	push %rdi
	# 1. Find the current end of the data segment.
	movq $12, %rax # brk
	xorq %rdi, %rdi # 0 means we retrieve the current end.
	syscall
	# 2. Add the amount of memory we want to allocate.
	pop %rdi # the argument
	push %rax # current end, which is where the allocated memory will start
	addq %rax, %rdi # compute the new end
	movq $12, %rax # brk
	syscall
	pop %rax # the old end, which is the address of our allocated memory
	ret
