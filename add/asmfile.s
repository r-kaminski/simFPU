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
.comm sum, 65

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



# Przy dodawaniu/odejmowaniu wykładnik obu licz musi być taki sam.
# Wykładnik zapisywany jest na 11 bitach, poczynając od drugiego bitu do dwunastego włącznie.
# _ ___________ ____________________________________________________
#   |wykladnik|

# --- PRZED PROCEDURĄ ZAMIANY WYKŁADNIKA
first_exp:
mov $input1, %r10   # wskaźnik na pierwszy element ciągu
mov $11, %rdi       # iterator ciągu - będziemy dekrementować od 12 elementu (indeks = 11)
mov $1, %r11        # iterujemy do 1 elementu
mov $1, %r12        # będziemy mnożyć * 2 przy każdej iteracji, żeby otrzymać potęgi 2
mov $2, %r13        # patrz wyżej

mov $0, %r14        # suma
call to_number

mov %r14, %r15      # przechowanie pierwszej sumy w innym rejestrze

second_exp:
# --- PRZED PROCEDURĄ ZAMIANY WYKŁADNIKA
mov $input2, %r10
mov $11, %rdi
mov $1, %r11
mov $1, %r12
mov $2, %r13

mov $0, %r14
call to_number

after_convert:
mov %r15, %r8
mov %r14, %r9
# %r8 = wykładnik 1szej liczby
# %r9 = wykładnik drugiej liczby

# --- OBLICZENIE MANTYS
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
#%r14 - mantysa drugiej liczby

cmp %r9, %r8
je before_add  # gdy wykładniki są równe, to możemy po prostu dodać mantysy
jmp before_convert


before_add:
mov %r8, %rdx   # rdx - wykładnik
jmp add_values

before_convert:
# w przeciwnym wypadku, należy sprowadzić mniejszy wykładnik do większego
cmp %r9, %r8
jl convert_r8
jg convert_r9


# --- SPROWADZENIE WYKŁADNIKÓW DO TEJ SAMEJ WARTOŚCI
convert_r8:
# r8 jest mniejsze
mov %r9, %rdx     # rdx - wykładnik końcowy
sub %r8, %r9      # r9 = r9 - r8 <-- o tyle pozycji musimy przesunąć mantysę r8
# będziemy zmieniać liczbę pierwszą, bo r8 to jej wykładnik
jmp shift_first_num

convert_r9:
# r9 jest mniejsze
mov %r8, %rdx     # rdx - wykładnik końcowy
sub %r9, %r8      # r8 = r8 - r9 <-- o tyle pozycji musimy przesunąć mantysę r9
# będziemy zmieniać liczbę drugą, bo r9 to jej wykładnik
jmp shift_second_num


shift_first_num:
# shr A, B - przesunięcie bitowe B o A w prawo (podzielenie przez 2^A)
# nasze A to %r9 - patrz "convert_r8"
# nasze B to mantysa pierwszej liczby, czyli %r15
mov %r9, %rcx
cmp $255, %rcx
jg set_zero_r15

shr %cl, %r15   # cl to rejestr przesunięcia
jmp add_values

set_zero_r15:
mov $0, %r15

jmp add_values


shift_second_num:
mov %r8, %rcx
cmp $255, %rcx
jg set_zero_r14

shr %cl, %r14 
jmp add_values

set_zero_r14:
mov $0, %r14
jmp add_values


# --- DODAWANIE MANTYS
add_values:
mov $0, %r13    # S - znak decydujący o +/-
# sprawdzamy, czy liczby są ujemne/dodatnie
mov $0, %rdi
movb input1(, %rdi, 1), %al
movb input2(, %rdi, 1), %bl


cmp $'0', %al
je first_plus
jne first_minus

first_plus:
cmp $'0', %bl
je both_plus
jne first_plus_second_minus

first_minus:
cmp $'0', %bl
je first_minus_second_plus
jne both_plus   # teoretycznie to "both minus" ale ważne, że mają takie same znaki, więc dodajemy normalnie


first_plus_second_minus:
#r15 - pierwsza, r14 - druga
# r15 + (-r14) = r15 - r14
sub %r14, %r15  # r15 = r15 - r14
cmp $0, %r15
jl sub_flag_r15
jmp end_add


sub_flag_r15:
mov $1, %r13
mov $4503599627370496, %r10
add %r10, %r15
dec %r8         # odjęcie 1 od wykładnika
jmp end_add

first_minus_second_plus:
# (-r15) + r14 = r14 - r15
sub %r15, %r14  # r14 = r14 - r15
cmp $0, %r14
jl sub_flag_r14
jmp end_add

sub_flag_r14:
mov $1, %r13
mov $4503599627370496, %r10
add %r10, %r14
mov %r14, %r15
dec %r8
jmp end_add

both_plus:
# nie jest konieczne dodawanie z flagą, bo 2^52 + 2^52 < 2^64, więc przeniesienie nie wystąpi
mov $4503599627370496, %r10
add %r14, %r15  # suma w %r15
cmp %r10, %r15  # czy nastąpiło przekroczenie 2^52
jl end_add

# nastąpiło przekroczenie 2^52
sub %r10, %r15  # %r15 = %r15 - 2^52
inc %r8         # dodanie 1 do wykładnika


# --- KONIEC DODAWANIA
end_add:
# S = %r13 (znak specjalny, 0 to plus, 1 to minus)
# E = %rdx (wykładnik)
mov %rdx, %r8
# M = %r15 (mantysa)
mov $1, %rax
mul %r13
# rejestr A - znak specjalny
add $0x30, %al
mov $0, %rdi
movb %al, sum(, %rdi, 1)


mov %r8, %rax
mov $2, %r11
mov $11, %rdi
# --- zamiana wykładnika na ASCII i zapisanie
write_exponent:
cmp $1, %rdi
jge cont_write_exp

jmp after_write_exp

cont_write_exp:
mov $0, %rdx
div %r11    # dzielenie przez 2
add $'0', %dl
movb %dl, sum(, %rdi, 1)
dec %rdi

cmp $0, %rax
jne write_exponent

after_write_exp:

mov %r15, %rax
mov $63, %rdi

write_man:
cmp $12, %rdi
jge cont_write_man

jmp after_write_man

cont_write_man:
mov $0, %rdx
div %r11
add $'0', %dl
movb %dl, sum(, %rdi, 1)
dec %rdi

cmp $0, %rax
jne write_man
# --- /\ zamiana mantysy na ASCII i zapisanie
after_write_man:
mov $64, %rdi
movb $0x0A, sum(, %rdi, 1)

jmp write_sum


# --- SPROWADZENIE ZNAKÓW WYKŁADNIKA DO LICZBY
to_number:
movb (%r10, %rdi, 1), %bl
sub $0x30, %bl      # zamiana z ASCII na cyfre

cmp $11, %rdi       # jeśli to pierwsza iteracja, tj. wyciągamy pierwszy znak, to nie mnożymy
je add_first

cmp $63, %rdi       # to samo co wyzej, ale dla mantysy
je add_first


exponent:
mov %r12, %rax      # aktualna potęga
mul %r13            # mnożymy zawsze x2
mov %rax, %r12      # przechowujemy aktualną potęgę

mul %rbx            # mnożymy aktualną potęgę przez wyciągnięty znak (wcześniej jako %bl)
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


write_sum:
# --- WYPISANIE NA EKRAN
mov $SYSWRITE, %rax
mov $STDOUT, %rdi
mov $sum, %rsi
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
# -- WYJŚCIE Z PROGRAMU
mov $SYSEXIT, %rax
mov $EXIT_SUCCESS, %rdi
syscall
