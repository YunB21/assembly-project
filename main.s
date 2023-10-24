.data
filename:
    .string "numbers.txt"
error_message:
    .string "Error: Failed to process the file\n"
error_message_len:
    .quad . - error_message

read_error_message:
    .string "Error: Failed to read the file\n"
read_error_message_len:
    .quad . - read_error_message

write_error_message:
    .string "Error: Failed to write to stdout\n"
write_error_message_len:
    .quad . - write_error_message

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

    # Preserving registers
    pushq %rdi
    pushq %rsi

    # Get the size of the file after opening
    call getFileSize
    movq %rax, %r8

    # Restore the registers
    popq %rsi
    popq %rdi

    # Adjusting the buffer size:
    movq $4096, %rax
    cmpq %r8, %rax
    jle read_loop    # If file size is less than or equal to 4096, continue to read_loop

    # If here, then we need to allocate a larger buffer
    movq %r8, %rdi
    call allocate
    movq %rax, %rbx  # rbx will now point to the new buffer.

read_loop:
    # Read from the file
    movq $0, %rax         # syscall: sys_read
    leaq buffer, %rsi     # buffer pointer
    movq $4096, %rdx      # number of bytes to read
    syscall
    
    # Write to stdout
    movq %rax, %rdx       # number of bytes to write
    movq $1, %rax         # syscall: sys_write
    movq $1, %rdi         # file descriptor: STDOUT
    leaq buffer, %rsi     # buffer pointer
    syscall


    # Getting the number of lines (coordinates)
    testq %rbx, %rbx      # Check if we are using the dynamically allocated buffer
    jz use_default_buffer_for_linecount
    leaq (%rbx), %rdi
    jmp done_buffer_selection_for_linecount
use_default_buffer_for_linecount:
    leaq buffer, %rdi
done_buffer_selection_for_linecount:
    movq %r8, %rsi        # length of buffer (file size)
    call getLineCount
    movq %rax, %r9        # Save the number of lines in r9

    # Allocate memory for parsed numbers
    movq %r9, %rax
    shlq $4, %rax         # Times 2 for two numbers per line and times 8 for size of long
    movq %rax, %rdi
    call allocate
    movq %rax, %rdx       # rdx now points to allocated space for parsed numbers 

    # Parse the numbers
    testq %rbx, %rbx      # Check if we are using the dynamically allocated buffer
    jz use_default_buffer_for_parsing
    leaq (%rbx), %rdi
    jmp done_buffer_selection_for_parsing
use_default_buffer_for_parsing:
    leaq buffer, %rdi
done_buffer_selection_for_parsing:
    movq %r8, %rsi        # length of buffer (file size)
    call parseData

    #Pass pointer to parsed numbers to rdx
    movq %rdx, %r13
    call sort_coordinates

    # Sorting the coordinates and retriving y-dimenssion
sort_coordinates:
    movq %r9, %rcx          # rcx will be our outer loop counter
outer_loop:
    decq %rcx
    jz end_of_sorting       # If rcx is zero, we've completed the sorting

    movq %r9, %rdx          # rdx will be our inner loop counter
    xorq %rsi, %rsi         # rsi will be our inner loop index

inner_loop:
    # Load coordinates at index rsi
    movq (%r13, %rsi, 8), %r10      # Load x of first coordinate
    movq 8(%r13, %rsi, 8), %r11     # Load y of first coordinate

    # Load coordinates at index rsi + 1
    movq 16(%r13, %rsi, 8), %r12    # Load x of next coordinate
    movq 24(%r13, %rsi, 8), %r14    # Load y of next coordinate

    # Compare and potentially swap
    cmpq %r12, %r10
    jg swap_coordinates
    je check_y
    jmp no_swap

swap_coordinates:
    # Swap x coordinates
    movq %r10, 16(%r13, %rsi, 8)
    movq %r12, (%r13, %rsi, 8)
    # Swap y coordinates
    movq %r11, 24(%r13, %rsi, 8)
    movq %r14, 8(%r13, %rsi, 8)
    jmp done_swap

check_y:
    cmpq %r14, %r11
    jg swap_coordinates

done_swap:
    addq $2, %rsi          # Move to the next pair of coordinates
    decq %rdx
    jnz inner_loop
    jmp outer_loop

no_swap:
    addq $2, %rsi
    decq %rdx
    jnz inner_loop

end_of_sorting:
    ret

    jmp close_file

close_file:
    # Close the file
    movq $3, %rax         # syscall: sys_close
    syscall
    testq %rax, %rax      # check for close error
    js close_failed       # jump if there's an error closing the file
    jmp exit_program

close_failed:
    jmp exit_failure

open_failed:
    movq $1, %rax         # syscall: sys_write
    movq $2, %rdi         # file descriptor: STDERR
    leaq error_message, %rsi
    movq $error_message_len, %rdx
    syscall
    jmp exit_failure

read_failed:
    movq $1, %rax          # syscall: sys_write
    movq $2, %rdi          # file descriptor: STDERR
    leaq read_error_message, %rsi
    movq read_error_message_len, %rdx
    syscall
    jmp close_file

write_failed:
    movq $1, %rax          # syscall: sys_write
    movq $2, %rdi          # file descriptor: STDERR
    leaq write_error_message, %rsi
    movq write_error_message_len, %rdx
    syscall
    jmp close_file

    # Close the file
    movq $3, %rax         # syscall: sys_close
    syscall
    jmp exit_program

exit_program:
    # Exit the program
    movq $60, %rax        # syscall: sys_exit
    xorq %rdi, %rdi       # exit status: 0
    syscall

exit_failure:
    movq $60, %rax        # syscall: sys_exit
    movq $1, %rdi         # exit status: 1 (error)
    syscall

