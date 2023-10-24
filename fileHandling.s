# int getFileSize(int fd)
#
# 	Returns the size (in bytes) of the file indicated by the file descriptor.
.section .data
.Lstat: .space 144 # size of the fstat struct
.section .text
.globl getFileSize
.type getFileSize, @function
getFileSize:
	movq $5, %rax # fstat
	# rdi already contains the fd
	movq $.Lstat, %rsi # buffer to write fstat data into
	syscall
	movq $.Lstat, %rax
	movq 48(%rax), %rax # position of size in the struct
	ret
