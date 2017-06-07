.include "m8515def.inc"
;defs
	.def score_ratusan = r6
	.def score_puluhan = r7
	.def score_satuan  = r8
	.def key   = r9
	.def lives = r10
	.def char1 = r11
	.def char2 = r12
	.def char3 = r13
	.def level = r14
	.def rand  = r15
	 
	.def temp  = r16
	.def temp2 = r17
	.def temp3 = r20
	.def PA    = r21
	 
 
	.equ block1 = 0x60
	.equ line1 	= 0x80 
	.equ line2 	= 0xa0
	.equ line3 	= 0xc0
	.equ line4 	= 0xe0

	.equ screenwidth = 20
 
	.org $00	rjmp MAIN
	.org $01	rjmp UP
	.org $02	rjmp OK
	.org $0E 	rjmp READ_KEY

MAIN:
	
INIT_STACK:
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
INIT_LED:
	ser temp
	out DDRA, temp ; Set port A as output
	out DDRB, temp ; Set port B as output
	out DDRC, temp
	rcall INIT_LCD
INIT_KEY:
	ldi temp, 0xF0
	out DDRD, temp
	ldi temp, 0x0F
	out PORTD, temp
INIT_INTERRUPT:
	ldi temp, 0b00001010
	out MCUCR, temp
	ldi temp, 0b11000000
	out GICR, temp
INIT_TIMER:
	ldi temp, (1<<CS00)
	out TCCR1B, temp
	out TCCR0, temp
	ldi temp, (1<<OCF0)
	out TIFR, temp
	ldi temp, (1<<OCIE0)
	out TIMSK, temp
	ldi temp, 0xFF
	out OCR0, temp
	sei
INIT_GAMESETTING:
	ldi temp, $03
	mov lives, temp
	ldi temp, $30
	mov level, temp
	

	ldi temp, 0x30
	mov score_ratusan, temp
	mov score_puluhan, temp
	mov score_satuan, temp
	
	ldi temp, $41
	add char1, temp
	add char2, temp
	add char3, temp
rjmp ASK_LEVEL
DISPLAY_WELCOME:
	ldi ZH, high(2*welcome_message)
	ldi ZL, low(2*welcome_message)
	rcall LOADBYTE
	rcall DELAY_LONG
	rcall DELAY_LONG
 
	cbi PORTA, 1 		; disabling rs, so its a data
	ldi temp2, 0b11000000  ; 1 bit pertama,rumusnya, 7 bit sisanya address DDRAM
	out PORTB, temp2
	sbi PORTA,0
	cbi PORTA,0
	adiw ZL, 1  ; skipping space
	rcall LOADBYTE
	rcall DELAY_LONG
	rcall DELAY_LONG
 
ASK_NAME:
	ldi temp,0
	rcall INIT_LCD
	rcall CLEAR_LCD
	ldi ZH, high(2*askname_message)
	ldi ZL, low(2*askname_message)
	rcall LOADBYTE
	
	LOOP1:
		cbi PORTA, 1 		; disabling rs, so its a data
		ldi temp2, 0b11000000  ; 1 bit pertama,rumusnya, 7 bit sisanya address DDRAM
		out PORTB, temp2
		sbi PORTA,0
		cbi PORTA,0
 
		mov PA, char1
		rcall WRITE_TEXT
 
		;######### Check if button1 or button2 has been pressed ########
		cpi temp, 1
		brne ELSE1
		inc char1
		ldi temp, 0
 
		ELSE1:
			cpi temp, 2 	
			brne LOOP1
			ldi temp,0
 
	LOOP2:
		
		cbi PORTA, 1 		; disabling rs, so its a data
		ldi temp2, 0b11000001  ; 1 bit pertama,rumusnya, 7 bit sisanya address DDRAM
		out PORTB, temp2
		sbi PORTA,0
		cbi PORTA,0
		
		mov PA, char2
		rcall WRITE_TEXT
		
		;######### Check if button1 or button2 has been pressed ########
		cpi temp, 1
		brne ELSE2
		inc char2
		ldi temp, 0
 
		ELSE2:
			cpi temp, 2 	
			brne LOOP2
			ldi temp,0
 
	LOOP3:
	
		cbi PORTA, 1 		; disabling rs, so its a data
		ldi temp2, 0b11000010  ; 1 bit pertama,rumusnya, 7 bit sisanya address DDRAM
		out PORTB, temp2
		sbi PORTA,0
		cbi PORTA,0
		
		mov PA, char3
		rcall WRITE_TEXT
 
		;######### Check if button1 or button2 has been pressed ########
		cpi temp, 1
		brne ELSE3
		inc char3
		ldi temp, 0
 
		ELSE3:
			cpi temp, 2 	
			brne LOOP3
			ldi temp,0
ASK_LEVEL:
	ldi temp, 0
	rcall CLEAR_LCD
	ldi ZH, high(2*level_message)
	ldi ZL, low (2*level_message)
	rcall LOADBYTE
 
	LOOP_ASK_LEVEL:
		cbi PORTA, 1
		ldi temp2, 0b11000000
		out PORTB, temp2
		sbi PORTA, 0
		cbi PORTA, 0
 
		mov PA, level
		rcall WRITE_TEXT
 
		cpi temp, 1
		brne END_ASK_LEVEL
		inc level
		ldi temp, 0
 
		END_ASK_LEVEL:
			cpi temp, 2
			brne LOOP_ASK_LEVEL
			ldi temp, 0
GAME_START:
	rcall CLEAR_LCD 
	
	ldi temp, 0
	 
	rcall CLEAR_LCD
	rcall SHIFT_LINE_LEFT
	rcall LOAD_GAME_DATA
	;rcall INIT_GAME_SCREEN
 
	ldi temp3, 10
	LOOP_GAME_START:
		dec temp3
		breq END_GAME_START
		rcall UPDATE_GAME_SCREEN
		rjmp LOOP_GAME_START
 
	END_GAME_START:
	rjmp EXIT
 
LOAD_GAME_DATA:
	ldi YH, high(line1)
	ldi YL, low (line1)
	rcall LOAD_LINES
 
	ldi YH, high(line2)
	ldi YL, low (line2)
	rcall LOAD_LINES
 
	ldi YH, high(line3)
	ldi YL, low (line3)
	rcall LOAD_LINES
 
	ldi YH, high(line4)
	ldi YL, low (line4)
	rcall LOAD_LINES
 
	ret
 
	LOAD_LINES:
		ldi temp, screenwidth
		LOOP_LOAD_LINES:
			dec temp
			breq END_LOAD_LINES
			ldi temp2, 0x5F
			st Y+, temp2
			rjmp LOOP_LOAD_LINES
		END_LOAD_LINES:
			ret
 
UPDATE_GAME_SCREEN:
	ldi ZH, high(line1)
	ldi ZL, low (line1)
	ldi temp, 0b10000000
	rcall SET_CURSOR_POS
	rcall DISPLAY_LINE
 
	ldi ZH, high(line2)
	ldi ZL, low (line2)
	ldi temp, 0b11000000
	rcall SET_CURSOR_POS
	rcall DISPLAY_LINE 
 
	ldi ZH, high(line3)
	ldi ZL, low (line3)
	ldi temp, 0b10010100
	rcall SET_CURSOR_POS
	rcall DISPLAY_LINE 
	
	ldi ZH, high(line4)
	ldi ZL, low (line4)
	ldi temp, 0b11010100
	rcall SET_CURSOR_POS
	rcall DISPLAY_LINE 	
	
	rcall DELAY_LONG

	rcall SHIFT_LINE
	ret

	DISPLAY_LINE:
		ldi temp, screenwidth
		LOOP_DISPLAY_LINE:
			dec temp
			breq END_DISPLAY_LINE
			ld temp2, Z+
			mov PA, temp2
			rcall WRITE_FAST
			rjmp LOOP_DISPLAY_LINE
	 
		END_DISPLAY_LINE:
		ret 
SHIFT_LINE:
	rcall NEXT_RANDOM
	ldi temp, 3
	and temp, rand

	ldi ZH, high(line1)
	ldi ZL, low (line1)
	
	cpi temp, 0
	brne NOT_LINE_1
	rcall SHIFT_LINE_RAND
	NOT_LINE_1:
	cpi temp, 0
	breq LINE_1
	rcall SHIFT_LINE_LEFT
	LINE_1:

	ldi ZH, high(line2)
	ldi ZL, low (line2)

	cpi temp, 1
	brne NOT_LINE_2
	rcall SHIFT_LINE_RAND
	NOT_LINE_2:
	cpi temp, 1
	breq LINE_2
	rcall SHIFT_LINE_LEFT
	LINE_2:

	ldi ZH, high(line3)
	ldi ZL, low (line3)

	cpi temp, 2
	brne NOT_LINE_3
	rcall SHIFT_LINE_RAND
	NOT_LINE_3:
	cpi temp, 2
	breq LINE_3
	rcall SHIFT_LINE_LEFT
	LINE_3:
	
	ldi ZH, high(line4)
	ldi ZL, low (line4)

	cpi temp, 3
	brne NOT_LINE_4
	rcall SHIFT_LINE_RAND
	NOT_LINE_4:
	cpi temp, 3
	breq LINE_4
	rcall SHIFT_LINE_LEFT
	LINE_4:

	ret
SHIFT_LINE_RAND:
	push temp
	push temp3
	ldi temp2, screenwidth
 
	mov YL, ZL
	mov YH, ZH
	inc YL
 
	LOOP_SHIFT_LINE_R:
		dec temp2
		breq END_SHIFT_LINE_R
		ld temp3, Y+
		st Z+, temp3
		rjmp LOOP_SHIFT_LINE_R
 
	END_SHIFT_LINE_R:
		rcall NEXT_RANDOM
		mov temp, rand
		mod10:
			subi temp, 10
			cpi temp, 10
			brsh mod10
		subi temp, -0x30
		st -Z, temp
		pop temp3
		pop temp
		ret
SHIFT_LINE_LEFT:
	push temp
	push temp3
	ldi temp2, screenwidth
 
	mov YL, ZL
	mov YH, ZH
	inc YL
 
	LOOP_SHIFT_LINE:
		dec temp2
		breq END_SHIFT_LINE
		ld temp3, Y+
		st Z+, temp3
		rjmp LOOP_SHIFT_LINE
 
	END_SHIFT_LINE:
		ldi temp, 0x5F
		st -Z, temp
		pop temp3
		pop temp
		ret

SET_CURSOR_POS:
	cbi PORTA, 1
	out PORTB, temp
	sbi PORTA, 0
	cbi PORTA, 0
	ret

EXIT:
	rcall CLEAR_LCD
	rjmp ENDLESS_LOOP
 
INIT_RANDOM:
	in rand, TCNT1L
	ret
NEXT_RANDOM:
	in rand, TCNT1L
	ret

INIT_LCD:
	cbi PORTA,1 ; CLR RS
	ldi temp2,0x38 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORTB,temp2
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_MID
 
	cbi PORTA,1 ; CLR RS
	ldi temp2,$0E ; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
	out PORTB,temp2
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_MID
 
	rcall CLEAR_LCD ; CLEAR LCD
	cbi PORTA,1 ; CLR RS
	ldi temp2,$06 ; MOV DATA,0x06 --> increase cursor, display sroll OFF
	out PORTB,temp2
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_MID
 
	ret	
CLEAR_LCD:
	cbi PORTA,1 ; CLR RS
	ldi temp2,$01 ; MOV DATA,0x01
	out PORTB,temp2
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_MID
	ret
LOADBYTE:
	lpm ; Load byte from program memory into r0
	
	tst r0
	breq END_LOADBYTE ; If so, quit
	mov PA, r0 ; Put the character onto Port B
	rcall WRITE_TEXT
	adiw ZL,1 ; Increase Z registers
 
	rjmp LOADBYTE
	END_LOADBYTE:
	ret
WRITE_TEXT:
	sbi PORTA,1 ; SETB RS
	out PORTB, PA
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_SHORT
	ret
WRITE_FAST:
	sbi PORTA,1 ; SETB RS
	out PORTB, PA
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	;rcall DELAY_SHORT
	ret
	
UP: 
	ldi temp, 1 
	reti
OK: 
	ldi temp, 2 
	reti
READ_KEY:
	push temp
	in temp, SREG
	push temp
	push r0
	push ZH
	push ZL

	ldi ZH, high(2*keytable)
	ldi ZL, low (2*keytable)

	; read column 1
	ldi temp ,0b01111111 		; PB7 = 0
	out PORTD,temp 
	in temp ,PIND 			; read input line
	ori temp ,0b11110000 	; mask upper bits
	cpi temp ,0b11111111 	; a key in this column pressed?
	
	brne KeyRowFound 		; key found
	adiw ZL,4 				; column not found, point Z one row down

	; read column 2
	ldi temp ,0b10111111 		; PB6 = 0
	out PORTD,temp 
	in temp ,PIND 			; read again input line
	ori temp ,0b11110000 	; mask upper bits
	cpi temp ,0b11111111 	; a key in this column?
	
	brne KeyRowFound 		; key found
	adiw ZL,4 				; column not found, another four keys down

	; read column 3
	ldi temp ,0b11011111 		; PB5 = 0
	out PORTD,temp 
	in temp ,PIND 			; read last line
	ori temp ,0b11110000 	; mask upper bits
	cpi temp ,0b11111111 	; a key in this column?

	brne KeyRowFound 		; key found
	adiw ZL,4 				; column not found, another four keys down
	
	; read column 4
	ldi temp ,0b011101111 	; PB4 = 0
	out PORTD,temp 
	in temp ,PIND 			; read last line
	ori temp ,0b11110000 	; mask upper bits
	cpi temp ,0b11111111 	; a key in this column?

	breq NoKey 				; unexpected: no key in this column pressed

	KeyRowFound: 			; column identified, now identify row
		lsr temp 			; shift a logic 0 in left, bit 0 to carry
		brcc KeyFound 		; a zero rolled out, key is found
		adiw ZL,1 			; point to next key code of that column
		rjmp KeyRowFound 	; repeat shift
		
KeyFound: 				; pressed key is found 
	lpm 				; read key code to R0
	mov key, r0 		; countinue key processing
	

NoKey:
	clr temp
	out TCNT0, temp

	pop ZL
	pop ZH
	pop r0
	pop temp
	out SREG, temp
	pop temp
	reti
		
DELAY_SHORT:
	ldi  r18, 6
	ldi  r19, 49
	L0: dec  r19
	    brne L0
	    dec  r18
	    brne L0
	ret
DELAY_MID:
    ldi  r18, 52
    ldi  r19, 242
	L1: dec  r19
	    brne L1
	    dec  r18
	    brne L1
	    nop
	ret
DELAY_LONG:
    ldi  r18, 208
    ldi  r19, 202
	L2: dec  r19
	    brne L2
	    dec  r18
	    brne L2
	    nop
		ret
		
ENDLESS_LOOP:	rjmp ENDLESS_LOOP

welcome_message:
	.db "SELAMAT DATANG DI",0
	.db "NUMBER TILES !1!",0
askname_message:
	.db "MASUKKAN NAMA ANDA", 0
 
level_message:
	.db "PILIH LEVEL AWAL",0
 
stage_message:
	.db "PLAYER : ",0,0,"SCORE ",0,"LIVES ",0
 
stage_number:
	.db "2326498553"
	.db "3802775842"
	.db "8842823897"
	.db "2273758429"
	.db "2399238599"
	.db 0
 
lines :
.db 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F
.db 0

keytable:
.db 0x01, 0x02, 0x03, 0x0F
.db 0x04, 0x05, 0x06, 0x0A
.db 0x07, 0x08, 0x09, 0x0B
.db 0x0F, 0x00, 0x0F, 0x0F
