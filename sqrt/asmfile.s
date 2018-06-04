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

.bss
.comm input, 32
.comm sqrt, 25      # znak + przecinek + 23 bity mantysy
.comm result, 25

.text
.globl _start

_start:
# W input będzie reprezentacja liczby w standardzie IEEE 2008-754


# TODO: sprawdzenie, czy znak jest ujemny/dodatni
jmp after_def

to_number:
movb (%r10, %rdi, 1), %bl   # r10, rdi - argumenty
sub $0x30, %bl              # zamiana z ASCII na cyfre

cmp $31, %rdi
je add_first

cmp $8, %rdi
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
mov $input, %r10
mov $8, %rdi
mov $1, %r11
mov $1, %r12
mov $2, %r13

mov $0, %r14    # suma
call to_number

# w %r14 jest wykładnik w kodzie z obciążeniem

sub $127, %r14

# w %r14 jest wykładnik

# sprawdzamy, czy jest parzysty
is_odd_even:
mov %r14, %rax
mov $0, %rdx
mov $2, %r8
div %r8
cmp $0, %rdx
je exp_even
jne exp_odd

exp_even:
mov $0, %r8     # flaga wskazująca na to, że nie wystąpiła korekta
jmp after_oddeven

exp_odd:
sub $1, %r14    # - || - wystąpiła korekta
mov $1, %r8

jmp after_oddeven


after_oddeven:
mov %r14, %r15      # <---- wykładnik po korekcji, przed dzieleniem


# liczba pierwiastkowana: najpierw znak specjalny + przecinek
mov $0, %rdi
movb input(, %rdi, 1), %bl
sub $'0', %bl
movb %bl, sqrt(, %rdi, 1)

mov 0x2C, %bl
inc %rdi
mov %bl, sqrt(, %rdi, 1)

# teraz mantysa
mov $9, %rdi

sign_field:
movb input(, %rdi, 1), %bl
sub $'0', %bl
movb %bl, sqrt(, %rdi, 1)

inc %rdi

cmp $31, %rdi
jle sign_field

# ---- liczba pierwiastkowana w %rdi, sprawdzamy czy konieczna jest korekcja

cmp $0, %r8
je after_correction
jne do_correction

do_correction:
mov $1, %rdi
movb sqrt(, %rdi, 1), %bl   # przecinek
inc %rdi
movb sqrt(, %rdi, 1), %al   # liczba po prawej stronie przecinka

# zamiana miejscami przecinka i liczby po jego prawej stronie
movb %bl, sqrt(, %rdi, 1)
dec %rdi
movb %al, sqrt(, %rdi, 1)


after_correction:
mov $0, %rdi    # iterator liczenia pierwiastka
mov $0, %r9

count_sqrt:
mov $0, %rax
mov $0, %r13
cmp $0, %r8
je no_correction
jne count_with_correction

# -----
no_correction:
cmp $0, %rdi
je take_one_nc

cmp $24, %rdi
jl take_two_nc
je take_two_cor_nc

take_one_nc:
movb sqrt(, %rdi, 1), %al
inc %rdi    # przechodzimy na przecinek
inc %rdi    # przechodzimy na liczbę

# TODO: %al do rejestru sumującego %r13 
sub $1, %al
add %rax, %r13
# TODO: done?

movb $1, result(, %r9, 1)
inc %9

jmp after_take_nc

take_two_nc:
movb sqrt(, %rdi, 1), %al
mov $2, %r10
mul %r10
inc %rdi

movb sqrt(, %rdi, 1), %bl
inc %rdi

add %bl, %al

# TODO: %r13 * 2, potem %r13 += %al
mov %al, %bl
mov %r13, %rax
mov $2, %r10
mul %r10
mov %rax, %r13

mov $0, %rax
mov %bl, %al
add %rax, %r13

# TODO: done?
# w %r13 będą liczby rozpisywane "pod" pierwiastkiem


jmp after_take_nc

take_two_cor_nc:



after_take_nc:

count_with_correction:






