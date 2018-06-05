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
file2: .ascii "fpu2.txt\0"

.bss
.comm number1, 64
.comm number2, 64
.comm module1, 53				# 52 + hide bit
.comm module2, 53
.comm result_module, 53
.comm result_sign, 1
.comm result_expression, 11
.comm result, 64

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

push $number1
push $1
push $11
call decode_number
add $24, %rsp
mov %r9, %r13			# decoded expression, number1

push $number2
push $1
push $11
call decode_number
add $24, %rsp
mov %r9, %r14			# decoded expression, number2

call create_modules

push $module1
push $0
push $52
call decode_number
add $24, %rsp
mov %r9, %r11			# decoded module, number1

push $module2
push $0
push $52
call decode_number
add $24, %rsp
mov %r9, %r12			# decoded module, number2

call set_sign

# expression in r13 and r14
call move_module

# module values in r11 and r12
call sub_modules

push $53
push %r11
push $result_module
call encode_number
add $24, %rsp

push $11
push %r13
push $result_expression
call encode_number
add $24, %rsp

# iter for result
mov $0, %rsi

# concatenate with sign
mov $0, %rcx
mov result_sign(, %rcx, 1), %al
mov %al, result(, %rsi, 1)
inc %rsi

# concatenate with expr
mov $0, %rcx
conc_expr:
	mov result_expression(, %rcx, 1), %al
	mov %al, result(, %rsi, 1)
	inc %rsi
	inc %rcx
	cmp $11, %rcx
	jl conc_expr

# concatenate with module
mov $1, %rcx
conc_module:
	mov result_module(, %rcx, 1), %al
	mov %al, result(, %rsi, 1)
	inc %rsi
	inc %rcx
	cmp $52, %rcx
	jl conc_module

mov $1, %rax
mov $1, %rdi
mov $result, %rsi
mov $64, %rdx
syscall



mov $SYSEXIT, %rax
mov $EXIT_SUCCESS, %rdi
syscall

# align expression and moves module
# r11 module number1
# r12 module number2
# r13 expression number1
# r14 expression number2
move_module:
	cmp %r13, %r14
	jg add_to_first
	jl add_to_second
	je break

	add_to_first:				# r14 > r13
		mov %r14, %r15
		sub %r13, %r14

		move_module1:
			shr %r11
			dec %r14
			cmp $0, %r14
			jg move_module1

		mov %r15, %r13
		mov %r15, %r14
		jmp break

	add_to_second:
		mov %r13, %r15
		sub %r14, %r13

		move_module2:
			shr %r12
			dec %r13
			cmp $0, %r13
			jg move_module2

		mov %r15, %r14
		mov %r15, %r13
		jmp break
		
	break:
	ret

sub_modules:
	sub %r12, %r11
	cmp $0, %r11
	jl add_to_module
	jmp break_add

	add_to_module:
		mov $1, %r8
		shl $52, %r8
		add_to_mod_loop:
			add %r8, %r11
			dec %r14
			cmp $0, %r11
			jl add_to_mod_loop
			jmp break_add
		
	break_add:
	ret

# module ( higher index, lower index, buff )
create_modules:	
	mov $0x31, %al
	mov $0, %rsi
	mov $12, %rcx

	mov %al, module1(, %rsi, 1)
	mov %al, module2(, %rsi, 1)
	inc %rsi
	
	create_loop:
		mov number1(, %rcx, 1), %bl
		mov number2(, %rcx, 1), %bh
		mov %bl, module1(, %rsi, 1)
		mov %bh, module2(, %rsi, 1)
		inc %rcx
		inc %rsi
		cmp $53, %rsi
		jl create_loop

	ret

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

# sets sign of subtraction
# r13 - r14
# module and expressions should be in r11, r12, r13, r14
# r11 - mod1, r12 - mod2, r13 - exp1, r14 - exp2
set_sign:
	mov $0, %rcx
	mov $0x30, %al
	mov $0x31, %ah
	cmp %r14, %r13
	jg set_0
	jl set_1
	je chck_modules

	chck_modules:
		cmp %r12, %r11
		jg set_0
		jl set_1
		mov %al, result_sign(, %rcx, 1)
		jmp break_sign

	set_0:
		mov %al, result_sign(, %rcx, 1)
		jmp break_sign

	set_1:
		mov %ah, result_sign(, %rcx, 1)

	break_sign:
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
