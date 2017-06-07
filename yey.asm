.include "m8515def.inc"
 
.def lives = r10
.def char1 = r11
.def char2 = r12
.def char3 = r13
.def level = r14
.def rand = r15
 
.def temp = r16
.def temp2 = r17
.def temp3 = r18
.def PA = r19
 
.def score_ratusan = r21
.def score_puluhan = r22
.def score_satuan = r23
 
.equ block1 = 0x60
.equ line1 = 0x80 
.equ line2 = 0xa0
.equ line3 = 0xc0
.equ line4 = 0xe0
 
.org $00
rjmp MAIN
 
.org $01
rjmp UP
	 
.org $02
rjmp OK
 
 
MAIN:
	
INIT_STACK:
	ldi temp, low(RAMEND)
	ldi temp, high(RAMEND)
	out SPH, temp
INIT_LED:
	ser temp
	out DDRA, temp ; Set port A as output
	out DDRB, temp ; Set port B as output
	out DDRC, temp
	rcall INIT_LCD
INIT_INTERRUPT:
	ldi temp, 0b00001010
	out MCUCR, temp
	ldi temp, 0b11000000
	out GICR, temp
	sei
INIT_TIMER:
	ldi temp, (1<<CS00)
	out TCCR1B, temp
INIT_GAMESETTING:
	ldi temp, $03
	mov lives, temp
	ldi temp, $30
	mov level, temp
	
	ldi score_ratusan, $30
	ldi score_puluhan, $30
	ldi score_satuan, $30
	
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
	rcall INIT_GAME_SCREEN
 
	;cbi PORTA, 0
	;cbi PORTA, 1
	;cbi PORTA, 2
	;ldi temp, 0x07
	;out PORTB, temp
	;sbi PORTA, 0
	;cbi PORTA, 0
	;ldi temp, 0x14
	;out PORTB, temp
	;sbi PORTA, 0
	;cbi PORTA, 0

	ldi temp3, 10
	LOOP_GAME_START:
		dec temp3
		breq END_GAME_START
		;rcall UPDATE_GAME_SCREEN
		rcall INIT_GAME_SCREEN
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
		ldi ZH, high(2*lines)
		ldi ZL, low (2*lines)
		ldi temp, 20
		LOOP_LOAD_LINES:
			dec temp
			breq END_LOAD_LINES
			lpm
			st Y+, r0
			adiw ZL, 1
			rjmp LOOP_LOAD_LINES
		END_LOAD_LINES:
			ret
SHIFT_LINE_LEFT:
	ldi temp2, 20
 
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
		rcall NEXT_RANDOM
		mov temp, rand
		mod10:
			subi temp, 10
			cpi temp, 10
			brsh mod10
		subi temp, -0x30
		st -Z, temp
		ret
 
INIT_GAME_SCREEN:
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
	rcall DELAY_LONG
	rcall DELAY_LONG
	rcall SHIFT_LINE
	ret

	DISPLAY_LINE:
		ldi temp, 20
		LOOP_DISPLAY_LINE:
			dec temp
			breq END_DISPLAY_LINE
			ld temp2, Z+
			mov PA, temp2
			rcall WRITE_FAST
			rjmp LOOP_DISPLAY_LINE
	 
		END_DISPLAY_LINE:
		ret 
UPDATE_GAME_SCREEN:
	ldi ZH, high(line1)
	ldi ZL, low (line1)
	ldi temp, 0b10010011
	rcall SET_CURSOR_POS 
	rcall SHIFT_LINE_LEFT
	rcall UPDATE_LINE

	ldi ZH, high(line2)
	ldi ZL, low (line2)
	ldi temp, 0b11010011
	rcall SET_CURSOR_POS 
	rcall SHIFT_LINE_LEFT
	rcall UPDATE_LINE

	ldi ZH, high(line3)
	ldi ZL, low (line3)
	ldi temp, 0b10100111
	rcall SET_CURSOR_POS 
	rcall SHIFT_LINE_LEFT
	rcall UPDATE_LINE

	ldi ZH, high(line4)
	ldi ZL, low (line4)
	ldi temp, 0b11100111
	rcall SET_CURSOR_POS 
	rcall SHIFT_LINE_LEFT
	rcall UPDATE_LINE
	
	rcall DELAY_LONG
	rcall DELAY_LONG
	rcall DELAY_LONG
	ret

	UPDATE_LINE:
		ld PA, Z
		rcall WRITE_FAST
		ret

SHIFT_LINE:
	ldi ZH, high(line1)
	ldi ZL, low (line1)
	rcall SHIFT_LINE_LEFT

	ldi ZH, high(line2)
	ldi ZL, low (line2)
	rcall SHIFT_LINE_LEFT

	ldi ZH, high(line3)
	ldi ZL, low (line3)
	rcall SHIFT_LINE_LEFT

	ldi ZH, high(line4)
	ldi ZL, low (line4)
	rcall SHIFT_LINE_LEFT
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
	;push temp
	;push temp2
	;in temp, TCNT1L
	;mov temp2, rand
	;muls temp2, temp
	;mov rand, r0
	;pop temp2
	;pop temp
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
	rcall DELAY_MID
	ret
WRITE_FAST:
	sbi PORTA,1 ; SETB RS
	out PORTB, PA
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY_SHORT
	ret
	
UP: ldi temp, 1 
	reti
 
OK: ldi temp, 2 
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
 
;.db 0x5F, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39