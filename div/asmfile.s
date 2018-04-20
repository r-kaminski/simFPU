.data
STDIN = 0
STDOUT = 1
SYSREAD = 0
SYSWRITE = 1
SYSOPEN = 2
SYSCLOSE = 3
FREAD = 0
FWRITE = 1
SYSEXIT = 60
EXIT_SUCCESS = 0
file1: .ascii "fpu1.txt\0"
file2: .ascii "fpu2.txt\0"
in_error: .ascii "Not allowed number. Each number must have 64 bits in IEEE754-2008 standard representation.\n"
in_error_len = .-in_error
shift_var = 0


.bss
.comm input1, 65     # 64 + \n
.comm input2, 65
.comm div_result, 65

.text
.global main

main:
# --- OTWARCIE PIERWSZEGO PLIKU
mov $SYSOPEN, %rax
mov $file1, %rdi
mov $FREAD, %rsi
mov $0, %rdx
syscall

mov %rax, %r10      # ID pliku

# --- ODCZYTANIE PIERWSZEJ LICZBY Z PLIKU
mov $SYSREAD, %rax
mov %r10, %rdi
mov $input1, %rsi
mov $65, %rdx
syscall

mov %rax, %r8       # długość liczby

# --- ZAMKNIĘCIE PIERWSZEGO PLIKU
mov $SYSCLOSE, %rax
mov %r10, %rdi
mov $0, %rsi
mov $0, %rdx
syscall


# --- SPRAWDZENIE CZY LICZBA MA 64 ZNAKI
cmp $65, %r8        # 64 + \n
jne input_error

# --- OTWARCIE DRUGIEGO PLIKU
mov $SYSOPEN, %rax
mov $file2, %rdi
mov $FREAD, %rsi
mov $0, %rdx
syscall

mov %rax, %r10      # ID pliku

# --- ODCZYTANIE DRUGIEJ LICZBY Z PLIKU
mov $SYSREAD, %rax
mov %r10, %rdi
mov $input2, %rsi
mov $65, %rdx
syscall

mov %rax, %r9       # długość liczby

# --- ZAMKNIĘCIE DRUGIEGO PLIKU
mov $SYSCLOSE, %rax
mov %r10, %rdi
mov $0, %rsi
mov $0, %rdx
syscall

# --- SPRAWDZENIE CZY LICZBA MA 64 ZNAKI
cmp $65, %r9
jne input_error

jmp after_def

to_number:
movb (%r10, %rdi, 1), %bl   # r10, rdi - argumenty
sub $0x30, %bl  # zamiana z ASCII na cyfre

cmp $11, %rdi
je add_first

cmp $63, %rdi
je add_first


exponent:
mov %r12, %rax
mul %r13
mov %rax, %r12

mul %rbx
add %rax, %r14
jmp after_add

add_first:
add %rbx, %r14
jmp after_add

after_add:
dec %rdi
cmp %r11, %rdi
jge to_number

ret



after_def:






write_div:
mov $SYSWRITE, %rax
mov $STDOUT, %rdi
mov $div_result, %rsi
mov $65, %rdx
syscall

jmp exit

input_error:
mov $SYSWRITE, %rax
mov $STDOUT, %rdi
mov $in_error, %rsi
mov $in_error_len, %rdx
syscall


exit:
mov $SYSEXIT, %rax
mov $EXIT_SUCCESS, %rdi
syscall
