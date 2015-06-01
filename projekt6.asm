#############################################################################################
#	Program czytajacy program asemblerowy MIPS i generujacy statystykeliczb wystapien 
#	poszczegolnych instrukcji i dyrektyw asemblera.
#	Autor: HUBERT KUCZYNSKI
#############################################################################################
	
	.data
fnf:		.asciiz	"Nie znaleziono pliku "
msg:		.asciiz "Podaj sciezke do pliku "
file:		.space	64				# Nazwa pliku wejsciowego
buffer: 	.space	512				# bufor 
instructions:	.space	1024				# Tablica instrukcji
numbers:	.word	200				# Tablica liczb oznaczajacych ilosc odpowiednich instrukcji
 
	.text

	li	$v0, 4					# Wyswietla msg
	la	$a0, msg
	syscall
	li	$v0, 8					# Wczytuje sciazke do pliku
	la	$a0, file
	li	$a1, 64
	syscall
	move	$t0, $a0

deleteNewLine:						# Usuwa znak '\n' na koncu sciezki do pliku
	lb	$t1, ($t0)
	addiu	$t0, $t0, 1
	bne	$t1, '\n', deleteNewLine
	subiu	$t0, $t0, 1
	sb	$zero, ($t0)

open:							# Otwiera plik
	li	$v0, 13		
	la	$a0, file	
	li	$a1, 0					# Flaga Read-Only
	li	$a2, 0	
	syscall
	move	$s6, $v0	
	blt	$v0, 0, err	
	li	$t5, 0		
	la	$t2, instructions			# w $t2 adres poczatku tablicy instructions		
	move	$t4, $t2				# w $t4 adres po spacji po ostatniej instrukcjis
	li	$t5, 0					# w $t5 indeks (0) do iteracji po numbers
	li	$s5, 0
	
read:							# Wczytuje z pliku
	li	$v0, 14			
	move	$a0, $s6		
	la	$a1, buffer			
	li	$a2, 512		
	syscall
	beqz	$v0, beforeClose				# jezeli wczytano 0 znakow, to konczy program
	la	$t0, buffer				# w $t0 adres poczatku bufora
	move	$s7, $v0				
	addu	$s7, $s7, $t0				# w $s7 adres elementu za ostatnim w buffer						
	move	$s3, $t0				# adres poczatku bufora 			
	beqz	$ra, beforeInstruction			
	jr	$ra
	
inInstruction:
	sb 	$t1, ($t2)				# zapisuje znak do tablicy instructions
	addiu	$t2, $t2, 1				# inkrementuje adres instructions		
	subu	$t3, $t0, $s7		
	bgezal	$t3, read	
	lb	$t1, ($t0)				# wczytuje znak z buffer	
	beq	$t1, '#', beforeCheck
	ble 	$t1, ' ', beforeCheck			# jesli znak <= ' ', to przechodzi do sprawdzania czy nowa instrukcja jest juz zapisana
	addiu	$t0, $t0, 1				# inkrementuje adres buffer
	bne	$t1, ':', inInstruction			# jesli znak == ':', to kasuje wszesniej zapisane slowo (jest to etykieta)
	move	$t2, $t4
	
beforeInstruction:
	subu	$t3, $t0, $s7				
	bgezal	$t3, read
	lb	$t1, ($t0)
	addiu	$t0, $t0, 1
	beq 	$t1, ':', beforeInstruction
	ble 	$t1, ' ', beforeInstruction
	bne 	$t1, '#', inInstruction

ignore:							# Pomija wszystkie znaki az do '\n'
	subu	$t3, $t0, $s7		
	bgezal	$t3, read
	lb	$t1, ($t0)
	addiu	$t0, $t0, 1
	beq 	$t1, '\n', beforeInstruction
	j	ignore
	
beforeClose:
	beq	$t2, $t4, closeFile
	addiu	$t2, $t2, 1
	
beforeCheck:						# Ustawia rejestry przed sprawdzaniem czy instrukcja pojawila sie wczesniej
	la	$t6, instructions			# adres poczatku tablicy instrukcji
	move	$t5, $t4				# adres poczatku nowej instrukcji
	move	$s2, $t2				# w $s2 adres konca instructions
	li	$t1, '\n'				# wczytuje '\n' do $t1
	sb 	$t1, ($t2)				# zapisuje '\n' na koncu tablicy instructions	
	li	$t7, 0					# ustawia indeks w numbers	
	
checkIfExist:						# Sprawdza czy nowa instrukcja jest juz na liscie wystapien w tablicy instructions
	lb	$t8, ($t5)				# nowa instrukcja
	lb	$t9, ($t6)				# wszystkie instrukcje	
	bne	$t8, $t9, moveForward			# jezeli znaki roznia sie to przechodzi do nastepnego slowa w instructions
	beq	$t6, $s2, notExist			# jezeli $t6 == $s2, to znaczy ze doszlismy do konca tablicy, wiec szukana instrukcja nie wystepuje
	beq	$t8, '\n', checkNumber			# jezeli doszlismy do '\n' to znaczy ze szukana instrukcja wystepuje
	addi	$t5, $t5, 1
	addi	$t6, $t6, 1
	j	checkIfExist
	
moveForward:						# Ustawia zmienne
	addi	$t7, $t7, 4				# Dodaje 4 do licznika s��w
	move	$t5, $t4				# ustawia ponownie na poczatek nowej instrukcji
	
moveToNextInstruction:					# Przechodzi w tablicy do nastepnej zapisanej instrukcji
	lb	$t9, ($t6)
	addi	$t6, $t6, 1
	bgt	$t9, ' ', moveToNextInstruction
	j	checkIfExist
	
notExist:						# Aktualna instrukcja nie pojawila sie wczesniej
	sb	$t1, ($t2)				# zapisuje '\n'
	li	$t9, 1
	sb	$t9, numbers($t7)
	addiu	$t2, $t2, 1
	move	$t4, $t2
	j	ignore
	
addToNumber:						# Inkrementuje liczbe oznaczajaca ilosc wystapien danej instrukcji
	addi	$t9, $t9, 1
	sb	$t9, numbers($t7)
	move	$t2, $t4
	j	ignore
	
checkNumber:						# Sprawdza czy liczba wystapien jest wieksza od 0
	lb	$t9, numbers($t7)
	bgt	$t9, 0, addToNumber
	addi	$t9, $zero, 1
	sb	$t9, numbers($t7)
	
afterInstruction:					
	sb	$t1, ($t2)				# zapisuje '\n'
	addiu	$t2, $t2, 1
	move	$t4, $t2
 
closeFile:						# Zamyka plik
	li	$v0, 16		
	move	$a0, $s6		
	syscall		
 
beforePrint:						# Wypisywanie wynikow
	li	$t5, 0
	la	$s1, instructions
	
printNames:
	beq	$s1, $t2, quit
	li	$v0, 11
	lb	$a0, ($s1)
	addi	$s1, $s1, 1
	ble	$a0, ' ', printNumbers
	syscall
	j printNames
	
printNumbers:
	li	$v0, 11
	li	$a0, '\t'
	syscall
	li	$v0, 1
	lw	$a0, numbers($t5)
	syscall
	li	$v0, 11
	li	$a0, '\n'
	syscall
	addiu	$t5, $t5, 4
	j	printNames
	
err:							# Blad otwarcia pliku
	li	$v0, 4			
	la	$a0, fnf		
	syscall
	
quit:
	li	$v0, 10		
	syscall