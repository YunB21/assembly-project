.data
filename:
    .string "numbers.txt"

.bss
    .lcomm buffer, 4096

.text
    .globl _start

_start:
    # Open the file
    movq $2, %rax         # syscall: sys_open
    leaq filename, %rdi   # filename pointer
    xorq %rsi, %rsi       # flags: O_RDONLY
    syscall
    movq %rax, %rdi       # Save file descriptor in rdi

read_loop:
    # Read from the file
    movq $0, %rax         # syscall: sys_read
    leaq buffer, %rsi     # buffer pointer
    movq $4096, %rdx      # number of bytes to read
    syscall

    # Check if we've reached the end of the file
    testq %rax, %rax      # If rax is 0, we've reached EOF
    jz close_file

    # Write to stdout
    movq %rax, %rdx       # number of bytes to write
    movq $1, %rax         # syscall: sys_write
    movq $1, %rdi         # file descriptor: STDOUT
    leaq buffer, %rsi     # buffer pointer
    syscall

    # Go back to read the next chunk
    jmp read_loop

close_file:
    # Close the file
    movq $3, %rax         # syscall: sys_close
    syscall

    # Exit the program
    movq $60, %rax        # syscall: sys_exit
    xorq %rdi, %rdi       # exit status: 0
    syscall

