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
OVERLOAD = 127
file1: .ascii "file1.txt\0"
file2: .ascii "file2.txt\0"

.bss
.comm number1, 32
.comm number2, 32
.comm module1, 24
.comm module2, 24
.comm module_result, 48				# module between [2, 48], overload [0,1]
.comm moved_module, 23
.comm expression, 8
.comm sign, 1
.comm res, 33						# result of multiplication + \n

.text
.global main
main:

push $number1
push $file1
call read_from_file
add $16, %rsp

push $number2
push $file2
call read_from_file
add $16, %rsp

call make_modules

push $module1
push $0
push $23
call decode_number
mov %r9, %r13			#decoded module in r13
add $24, %rsp

push $module2
push $0
push $23
call decode_number
mov %r9, %r14			#decoded module in r14
add $24, %rsp

push %r13
push %r14
call multiply_numbers
add $16, %rsp
mov %rax, %r15

push $48
push %rax
push $module_result
call encode_number
add $24, %rsp

push $number1
push $1
push $8
call decode_number
mov %r9, %r11			# expression 1
add $24, %rsp

push $number2
push $1
push $8
call decode_number
add $24, %rsp

add %r9, %r11			# add expression 2 to expression 1
sub $OVERLOAD, %r11

push $48
push $module_result
call move_module
add $16, %rsp

add %rbx, %r11

push $8
push %r11
push $expression
call encode_number
add $16, %rsp

call check_sign

mov $0, %rcx					# buffors counter
mov $0, %rsi					# result counter

# concatenate with sign
mov sign(, %rcx, 1), %al
mov %al, res(, %rsi, 1)

inc %rsi
mov $0, %rcx

# concatenate with expression
expression_loop:
	mov expression(, %rcx, 1), %al
	mov %al, res(, %rsi, 1)
	inc %rsi
	inc %rcx
	cmp $8, %rcx
	jl expression_loop

# concatenate with module
mov $2, %rcx
md_loop:
	mov module_result(, %rcx, 1), %al
	mov %al, res(, %rsi, 1)
	inc %rcx
	inc %rsi
	cmp $32, %rcx
	jl md_loop

mov $10, %al
mov $32, %rsi
mov %al, res(, %rsi, 1)

mov $1, %rax
mov $1, %rdi
mov $res, %rsi
mov $33, %rdx
syscall

mov $SYSEXIT, %rax
mov $EXIT_SUCCESS, %rdi
syscall

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

# mul(a, b)
# result in rax
multiply_numbers:
	push %rbp
	mov %rsp, %rbp
	
	mov $0, %rax
	mov 16(%rbp), %rax
	mov 24(%rbp), %rbx
	mul %rbx
	
	mov %rbp, %rsp
	pop %rbp
	ret

check_sign:
	mov $0, %rcx
	mov number1(, %rcx, 1), %bl
	mov number2(, %rcx, 1), %bh
	sub $0x30, %bl
	sub $0x30, %bh
	xor %bl, %bh
	cmp $0, %bh
	je insert_0
	jne insert_1

	insert_0:
		mov $0x30, %al
		mov %al, sign(, %rcx, 1)
		ret

	insert_1:
		mov $0x30, %al
		mov %al, sign(, %rcx, 1)
		ret

	ret

# moves module and ret how much sub or add to expression
# move_module( module, size )
move_module:
	push %rbp
	mov %rsp, %rbp

	mov 16(%rbp), %r10
	mov 24(%rbp), %rdi		
	mov $0, %rcx
	mov $1, %rbx 			# result

	move_loop:
		mov (%r10, %rcx, 1), %al
		cmp $0x31, %al
		je break
		inc %rcx
		dec %rbx
		cmp %rdi, %rcx
		jl move_loop
	
	break:

	mov %rbp, %rsp
	pop %rbp
	ret

# decode(higher index, lower index, buffor)
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

make_modules:
	mov $0, %rcx
	mov $9, %rsi

	movb $0x31, module1(, %rcx, 1)
	movb $0x31, module2(, %rcx, 1)

	inc %rcx
	
	modules_loop:
		mov number1(, %rsi, 1), %bl
		mov number2(, %rsi, 1), %bh
		mov %bl, module1(, %rcx, 1)
		mov %bh, module2(, %rcx, 1)
		inc %rcx
		inc %rsi
		cmp $32, %rsi
		jle modules_loop

	ret

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
	mov $32, %rdx
	syscall

	mov $SYSCLOSE, %rax
	mov %r8, %rdi
	mov $0, %rsi
	mov $0, %rdx
	syscall
	
	mov %rbp, %rsp
	pop %rbp
	ret
