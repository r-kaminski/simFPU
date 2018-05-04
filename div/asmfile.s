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
.comm help_buff_bin, 66
.comm rev_help_buff_bin, 66
.comm help_buff, 19
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

# --- CZĘŚĆ GŁÓWNA PROGRAMU
after_def:
# Pierwszy krok to dzielenie mantys, w tym celu zamieniamy obie mantysy na reprezentacje dziesiętną

first_man:
mov $input1, %r10
mov $63, %rdi
mov $12, %r11
mov $1, %r12
mov $2, %r13

mov $0, %r14
call to_number
mov %r14, %r15  # %r15 - mantysa pierwszej liczby

second_man:
mov $input2, %r10
mov $63, %rdi
mov $12, %r11
mov $1, %r12
mov $2, %r13

mov $0, %r14
call to_number
# %r14 - mantysa drugiej liczby


# --- SPRAWDZAMY, CZY I ILE RAZY MANTYSA PIERWSZA JEST MNIEJSZA OD MANTYSY DRUGIEJ
# JEŚLI JEST MNIEJSZA, TO MNOŻYMY JĄ RAZY 10 TAK DŁUGO, AŻ BĘDZIE RÓWNA/WIĘKSZA OD MANTYSY DRUGIEJ
# LICZNIK ILE RAZY POMNOŻYLIŚMY JĄ PRZEZ 10 BĘDZIE KOREKTĄ WYKŁADNIKA

cmp %r14, %r15
jl before_correction
jge after_correction

before_correction:
mov $0, %r8         # licznik korekty
mov %r15, %rax
mov $10, %r9

count_correction:
mul %r9             # pomnożenie mantysy pierwszej liczby (teraz w %rax) przez 10
inc %r8             # korekta do wykładnika
cmp %r14, %rax      # sprawdzamy, czy pierwsza mantysa nadal jest mniejsza od drugiej 
jl count_correction

mov %rax, %r15

after_correction:
# procedura dzielenia
mov %r15, %rax
mov $0, %rdx
div %r14
# wynik dzielenia w rax
mov $0, %rdi
movb %al, help_buff(, %rdi, 1)
inc %rdi
# reszta w rdx
mov %rdx, %r13

jmp after_bin_def

to_binary:
mov $2, %r11
mov $0, %rdi

to_binary_loop:
div %r11
movb %dl, EXAMPLE_BUFF(, %rdi, 1)
inc %rdi
cmp $0, %rax
jne to_binary_loop

ret


after_bin_def:

add_rest:

cmp %r14, %r13
jl mul_rest
jge div_rest

mul_rest:
mov %r13, %rax
mul %r9
mov %rax, %r13
#jmp add_rest

div_rest:
mov %r13, %rax
mov $0, %rdx
div %r14
# rdx - przechowuje resztę
mov %rdx, %r13
# rax - wynik dzielenia, zapisujemy do bufora
movb %al, help_buff(, %rdi, 1)
inc %rdi

cmp $19, %rdi
jl add_rest

# help_buff przechowuje teraz wynik mantysy w systemie dziesietnym (52 znaki). Nalezy zamienic ten wynik na reprezentacje binarna. W tym celu zamieniamy bufor na liczbe, nastepnie dzielimy przez 2. Zapisujemy wyniki reszty po kolei do bufora. Na koncu bierzemy tylko 52 ostatnie reszty - jest to mantysa wynikowa.
mov $18, %rdi   # licznik bufora
mov $10, %r12   # czynnik mnożenia
mov $10, %r10   # pomocniczy czynnik mnożenia
mov $0, %r11    # suma


convert_div_to_number:
movb help_buff(, %rdi, 1), %al
dec %rdi

cmp $18, %rdi
je add_div_to_number

mul %r12
mov %rax, %rbx
mov %r12, %rax
mul %r10
mov %rax, %r12
mov %rbx, %rax


add_div_to_number:
add %rax, %r11

cmp $0, %rdi
jge convert_div_to_number

# teraz w r11 znajduje się mantysa w reprezentacji dziesiętnej
mov $2, %r10    # rejestr do dzielenia
mov %r11, %rax
mov $0, %rdi

convert_div_to_binary:
mov $0, %rdx
div %r10
movb %dl, help_buff_bin(, %rdi, 1)
inc %rdi
cmp $66, %rdi
jl convert_div_to_binary

dec %rdi
mov $0, %r10

reverse_div_to_binary:
movb help_buff_bin(, %rdi, 1), %al
movb %al, rev_help_buff_bin(, %r10, 1)
dec %rdi
inc %r10

cmp $0, %rdi
jge reverse_div_to_binary

# --- mantysa zapisana na 66 znakach w rep. binarnej przechowywana w rev_help_buff_bin. Wyciągamy tylko 52 znaki.




# --- TODO: PROCEDURA ODEJMOWANIA WYKŁADNIKÓW, DODANIA OBCIĄŻENIA I KOREKTY



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
