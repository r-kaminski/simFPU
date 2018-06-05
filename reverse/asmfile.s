.data
SYSREAD = 0
STDIN = 0
SYSWRITE = 1
STDOUT = 1
SYSOPEN = 2
SYSCLOSE = 3
FREAD = 0
FWRITE = 1
SYSEXIT = 60
EXIT_SUCCESS = 0
file1: .ascii "fpu1.txt\0"
pow2 = 0x10000000
overload = 2046					# O*2

.bss
.comm number, 64
.comm reversed_expression, 11
.comm reversed_module, 52
.comm reversed_number, 64

.text
.global main
main:

push $number 
push $file1
call read_from_file
add $16, %rsp

push $number
push $1
push $11
call decode_number
add $24, %rsp

mov $overload, %rbx
sub %r9, %rbx			# reversed expression

push $11
push %rbx
push $reversed_expression
call encode_number
add $24, %rsp

cmp $pow2, %r9
jge reverse_1
jl reverse_0


ext_program:

mov $0, %rcx
mov number(, %rcx, 1), %al
mov %al, reversed_number(, %rcx, 1)

mov $1, %rcx
mov $0, %rsi
concat_expression:
	mov reversed_expression(, %rsi, 1), %al
	mov %al, reversed_number(, %rcx, 1)
	inc %rcx
	inc %rsi
	cmp $11, %rcx
	jle concat_expression

mov $12, %rcx
mov $0, %rsi
concat_module:
	mov reversed_module(, %rsi, 1), %al
	mov %al, reversed_number(, %rcx, 1)
	inc %rcx
	inc %rsi
	cmp $63, %rcx
	jle concat_module

mov $1, %rax
mov $1, %rdi
mov $reversed_number, %rsi
mov $64, %rdx
syscall

mov $SYSEXIT, %rax
mov $EXIT_SUCCESS, %rdi
syscall

reverse_0:
	mov $12, %rcx
	mov $0, %rsi
	negate0_loop:
		mov number(, %rcx, 1), %al
		cmp $0x30, %al
		je swap_0
		jne swap_1

		rt_0:
		mov %al, reversed_module(, %rsi, 1)
		inc %rsi
		inc %rcx
		cmp $63, %rcx
		jle negate0_loop

	jmp exit_r0

	swap_0:
		mov $0x31, %al
		jmp rt_0

	swap_1:
		mov $0x30, %al
		jmp rt_0

	exit_r0:
		push $reversed_module
		push $0
		push $51
		call decode_number
		add $24, %rsp
		
		add $1, %r9

		push $52
		push %r9
		push $reversed_module
		call encode_number
		add $24, %rsp

	jmp ext_program

reverse_1:

	push $number
	push $12
	push $63
	call decode_number
	add $24, %rsp

	shr %r9
	add $2, %r9
	
	push $52
	push %r9
	push $reversed_module
	call encode_number
	add $24, %rsp

	mov $0, %rcx
	
	negate1_loop:
		mov reversed_module(, %rcx, 1), %al
		cmp $0x30, %al
		je swap1_0
		jne swap1_1

		rt1:
		mov %al, reversed_module(, %rcx, 1)
		inc %rcx
		cmp $52, %rcx
		jl negate1_loop
		jmp ext_program

	swap1_0:
		mov $0x31, %al
		jmp rt1

	swap1_1:
		mov $0x30, %al
		jmp rt1



# encode(size, number, buff)
encode_number:
	push %rbp
	mov %rsp, %rbp
	
	mov 16(%rbp), %r10
	mov 24(%rbp), %rax			# number to encode
	mov 32(%rbp), %rcx
	mov $2, %rbx
	dec %rcx
	
	encode_loop:
		xor %rdx, %rdx
		div %rbx
		add $0x30, %dl
		mov %dl, (%r10, %rcx, 1)
		dec %rcx
		cmp $0, %rcx
		jge encode_loop
	
	mov %rbp, %rsp
	pop %rbp
	ret

# decode(higher index, lower index, buffor)
# result in r9
decode_number:
	push %rbp
	mov %rsp, %rbp

	mov 16(%rbp), %rcx
	mov 32(%rbp), %r10

	mov $1, %r8
	mov $0, %r9
	mov $0, %rax

	decode_loop:
		mov (%r10, %rcx, 1), %al
		sub $0x30, %al
		mul %r8
		add %rax, %r9
		shl %r8
		dec %rcx
		mov $0, %rax
		cmp 24(%rbp), %rcx
		jge decode_loop
	
	mov %rbp, %rsp
	pop %rbp
	ret

# read ( filename, buff )
read_from_file:
	push %rbp
	mov %rsp, %rbp
	
	mov $SYSOPEN, %rax		# file descriptor in rax
	mov 16(%rbp), %rdi
	mov $FREAD, %rsi
	mov $0, %rdx
	syscall

	mov %rax, %r8

	mov $SYSREAD, %rax
	mov %r8, %rdi
	mov 24(%rbp), %rsi
	mov $64, %rdx
	syscall

	mov $SYSCLOSE, %rax
	mov %r8, %rdi
	mov $0, %rsi
	mov $0, %rdx
	syscall
	
	mov %rbp, %rsp
	pop %rbp
	ret
