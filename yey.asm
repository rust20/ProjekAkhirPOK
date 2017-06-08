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
	.def pointer = r22
 
	.equ block1 = 0x60
	.equ line1 	= 0x80 
	.equ line2 	= 0xa0
	.equ line3 	= 0xc0
	.equ line4 	= 0xe0

	.equ screenwidth = 20
	.equ startdebug = ASK_LEVEL

	.equ DDR_LED 	= DDRB
	.equ PORT_LED 	= PORTB
	.equ DDR_KEY	= DDRC
	.equ PORT_KEY 	= PORTC
	.equ PIN_KEY 	= PINC

	.equ DDR_LCD_A  = DDRA
	.equ DDR_LCD_B  = DDRB
	.equ PORT_LCD_A = PORTA
	.equ PORT_LCD_B = PORTB
	.equ SETTING_A	= PORTD
	.equ SETTING_B	= PORTD
	.equ EN_A = 0
	.equ EN_B = 7
	.equ RS_A = 1
	.equ RS_B = 4

 
	.org $00	rjmp MAIN
	.org $01	rjmp UP
	.org $02	rjmp OK
	.org $05 	rjmp READ_KEY

MAIN:
	
INIT_STACK:
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
INIT_LED:
	ser temp
	out DDR_LCD_A, temp ; Set port B as output
	out DDR_LCD_B, temp ; Set port C as output
	out DDR_LED, temp ; Set port E as output
	ldi temp, 0b11
	rcall INIT_LCD
INIT_KEY:
	ldi temp, 0xF0
	out DDR_KEY, temp
	ldi temp, 0x0F
	out PORT_KEY, temp
INIT_INTERRUPT:
	ldi temp, 0b00001010
	out MCUCR, temp
	ldi temp, 0b11000000
	out GICR, temp

INIT_TIMER:
	ldi temp, (1<<CS10)
	out TCCR1B, temp
	ldi temp, (1<<CS00)
	out TCCR0, temp
	ldi temp, (1<<OCF1B)
	out TIFR, temp
	ldi temp, (1<<OCIE1B)
	out TIMSK, temp
	ldi temp, 0x06
	out OCR1BH, temp
	ldi temp, 0xFF
	out OCR1BL, temp
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

rjmp startdebug

INIT_LCD:
	cbi SETTING_A, RS_A ; CLR RS
	ldi temp, 0x38 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORT_LCD_A, temp
	sbi SETTING_A, EN_A ; SETB EN
	cbi SETTING_A, EN_A ; CLR EN
	sbi SETTING_A, EN_A ; SETB EN
	cbi SETTING_A, EN_A ; CLR EN
	rcall DELAY_SHORT
 
	cbi SETTING_A, RS_A ; CLR RS
	ldi temp, $0E ; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
	out PORT_LCD_A, temp
	sbi SETTING_A, EN_A ; SETB EN
	cbi SETTING_A, EN_A ; CLR EN
	rcall DELAY_SHORT
 
	rcall CLEAR_LCD ; CLEAR LCD
	cbi SETTING_A, RS_A ; CLR RS
	ldi temp, $06 ; MOV DATA,0x06 --> increase cursor, display sroll OFF
	out PORT_LCD_A, temp
	sbi SETTING_A, EN_A ; SETB EN
	cbi SETTING_A, EN_A ; CLR EN
	rcall DELAY_SHORT

	cbi SETTING_B, RS_B ; CLR RS
	ldi temp, 0x38 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
	out PORT_LCD_B, temp
	sbi SETTING_B, EN_B ; SETB EN
	cbi SETTING_B, EN_B ; CLR EN
	sbi SETTING_B, EN_B ; SETB EN
	cbi SETTING_B, EN_B ; CLR EN
	rcall DELAY_SHORT
 
	cbi SETTING_B, RS_B ; CLR RS
	ldi temp, $0E ; MOV DATA,0x0E --> disp ON, cursor ON, blink OFF
	out PORT_LCD_B, temp
	sbi SETTING_B, EN_B ; SETB EN
	cbi SETTING_B, EN_B ; CLR EN
	rcall DELAY_SHORT
 
	rcall CLEAR_LCD_2 ; CLEAR LCD
	cbi SETTING_B, RS_B ; CLR RS
	ldi temp, $06 ; MOV DATA,0x06 --> increase cursor, display sroll OFF
	out PORT_LCD_B, temp
	sbi SETTING_B, EN_B ; SETB EN
	cbi SETTING_B, EN_B ; CLR EN
	rcall DELAY_SHORT

	out PORT_LED, level
 
	ret	
CLEAR_LCD:
	cbi SETTING_A,1 ; CLR RS
	ldi temp2,$01 ; MOV DATA,0x01
	out PORT_LCD_A,temp2
	sbi SETTING_A,0 ; SETB EN
	cbi SETTING_A,0 ; CLR EN
	rcall DELAY_MID
	ret
CLEAR_LCD_2:
	cbi SETTING_B, RS_B ; CLR RS
	ldi temp2,$01 ; MOV DATA,0x01
	out PORT_LCD_B,temp2
	sbi SETTING_B, EN_B ; SETB EN
	cbi SETTING_B, EN_B ; CLR EN
	rcall DELAY_MID

	out PORT_LED, level
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
LOADBYTE_2:
	lpm ; Load byte from program memory into r0
	
	tst r0
	breq END_LOADBYTE_2 ; If so, quit
	mov PA, r0 ; Put the character onto Port B
	rcall WRITE_FAST_2
	adiw ZL,1 ; Increase Z registers
 
	rjmp LOADBYTE_2
	END_LOADBYTE_2:
	ret
WRITE_TEXT:
	sbi SETTING_A, RS_A ; SETB RS
	out PORT_LCD_A, PA
	sbi SETTING_A, EN_A ; SETB EN
	cbi SETTING_A, EN_A ; CLR EN
	rcall DELAY_MID
	ret
WRITE_FAST:
	sbi SETTING_A, RS_A ; SETB RS
	out PORT_LCD_A, PA
	sbi SETTING_A, EN_A ; SETB EN
	cbi SETTING_A, EN_A ; CLR EN
	ret
WRITE_FAST_2:
	sbi SETTING_B, RS_B ; SETB RS
	out PORT_LCD_B, PA
	sbi SETTING_B, EN_B ; SETB EN
	cbi SETTING_B, EN_B ; CLR EN

	out PORT_LED, level
	ret

LEVEL_DELAY:
	mov temp level
	subi temp, 0x30

	cpi temp, 7
	brne DELAY_6
	rcall DELAY_LONG
	rcall DELAY_LONG
	ret

	DELAY_6:
	cpi temp, 6
	brne DELAY_5
	rcall DELAY_LONG
	rcall DELAY_MID
	ret

	DELAY_5:
	cpi temp, 5
	brne DELAY_4
	rcall DELAY_LONG
	rcall DELAY_LONG
	ret

	DELAY_4:
	cpi temp, 4
	brne DELAY_3
	rcall DELAY_MID
	rcall DELAY_MID
	ret

	DELAY_3:
	cpi temp, 3
	brne DELAY_2
	rcall DELAY_MID
	rcall DELAY_SHORT
	ret

	DELAY_2:
	cpi temp, 2
	brne DELAY_1
	rcall DELAY_SHORT
	rcall DELAY_LONG
	ret

	DELAY_1: 
	ret

	cpi temp, 
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

DISPLAY_WELCOME:
	ldi ZH, high(2*welcome_message)
	ldi ZL, low(2*welcome_message)
	rcall LOADBYTE

	cbi SETTING_A, RS_A 		; disabling rs, so its a data
	ldi temp2, 0b11000000  ; 1 bit pertama,rumusnya, 7 bit sisanya address DDRAM
	out PORT_LCD_A, temp2
	sbi SETTING_A, EN_A
	cbi SETTING_A, EN_A
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
		cbi SETTING_A, RS_A		; disabling rs, so its a data
		ldi temp2, 0b11000000  	; 1 bit pertama,rumusnya, 7 bit sisanya address DDRAM
		out PORT_LCD_A, temp2
		sbi SETTING_A, EN_A
		cbi SETTING_A, EN_A
 
		mov PA, char1
		rcall WRITE_TEXT
 
		;######### Check if button1 or button2 has been pressed ########
		cpi temp, 1
		brne ELSE1
		inc char1
		ldi temp, 0S
 
		ELSE1:
			cpi temp, 2 	
			brne LOOP1
			ldi temp,0
 
	LOOP2:
		
		cbi SETTING_A, RS_A		; disabling rs, so its a data
		ldi temp2, 0b11000001  	; 1 bit pertama,rumusnya, 7 bit sisanya address DDRAM
		out PORT_LCD_A, temp2
		sbi SETTING_A, EN_A
		cbi SETTING_A, EN_A
		
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
	
		cbi SETTING_A, RS_A		; disabling rs, so its a data
		ldi temp2, 0b11000010  ; 1 bit pertama,rumusnya, 7 bit sisanya address DDRAM
		out PORT_LCD_A, temp2
		sbi SETTING_A, EN_A
		cbi SETTING_A, EN_A
		
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

	ldi temp2, (1<<7)
	out PORT_LED, temp2
 
	LOOP_ASK_LEVEL:
		cbi SETTING_A, RS_A
		ldi temp3, 0b11000000
		out PORT_LCD_A, temp3
		sbi SETTING_A, EN_A
		cbi SETTING_A, EN_A
 
		mov PA, level
		rcall WRITE_TEXT
 
		cpi temp, 1
		brne END_ASK_LEVEL
		mov temp, level
		cpi temp, 0x37
		breq MAX_LEVEL
		inc level
		lsr temp2
		out PORT_LED, temp2
		ldi temp, 0
		rjmp END_ASK_LEVEL

		MAX_LEVEL:
			ldi temp, 0x30
			mov level, temp
			ldi temp2, 1<<7


	END_ASK_LEVEL:
		rcall DELAY_MID
		cpi temp, 2
		brne LOOP_ASK_LEVEL
		ldi temp, 0
GAME_START:
	ldi temp, 0

	rcall CLEAR_LCD
	rcall CLEAR_LCD_2

	; Write name
	ldi temp, 0x80
	rcall SET_CURSOR_POS_2
	mov PA, char1
	rcall WRITE_FAST_2
	mov PA, char2
	rcall WRITE_FAST_2
	mov PA, char3
	rcall WRITE_FAST_2
	
	; Write lives
	ldi temp, 0xC0
	rcall SET_CURSOR_POS_2
	ldi PA, 0xF4
	rcall WRITE_FAST_2
	rcall WRITE_FAST_2
	rcall WRITE_FAST_2
	
	; Write score
	ldi temp, 0x94
	rcall SET_CURSOR_POS_2
	ldi PA, 0x30
	rcall WRITE_FAST_2
	rcall WRITE_FAST_2
	rcall WRITE_FAST_2

	; Shift Line left 15 times
	rcall SHIFT_LINE_LEFT
	rcall LOAD_GAME_DATA
	ldi temp3, 15
	teamUeno: 
		rcall SHIFT_LINE
		dec temp3
		brne teamUeno

	; Display pointer
	ldi pointer, 1
	ldi temp, 0x80
	rcall SET_CURSOR_POS
	ldi PA, 0x3E
	rcall WRITE_FAST
 
 	; Game loop
	LOOP_GAME_START:
		rcall UPDATE_GAME_SCREEN
		rcall SHIFT_LINE
		rjmp LOOP_GAME_START

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
	rcall Z_LINE1
	ldi temp, 0b10000001
	rcall SET_CURSOR_POS
	rcall DISPLAY_LINE
 
	rcall Z_LINE2
	ldi temp, 0b11000001
	rcall SET_CURSOR_POS
	rcall DISPLAY_LINE 
 
	rcall Z_LINE3
	ldi temp, 0b10010101
	rcall SET_CURSOR_POS
	rcall DISPLAY_LINE 
	
	rcall Z_LINE4
	ldi temp, 0b11010101
	rcall SET_CURSOR_POS
	rcall DISPLAY_LINE 	
	
	ret

	DISPLAY_LINE:
		ldi temp, screenwidth
		LOOP_DISPLAY_LINE:
			dec temp
			breq END_DISPLAY_LINE
			ld temp2, Z+
			mov PA, temp2
			rcall WRITE_FAST
			rcall LEVEL_DELAY
			rjmp LOOP_DISPLAY_LINE
	 
		END_DISPLAY_LINE:
		ret 
SHIFT_LINE:
	rcall NEXT_RANDOM
	ldi temp, 3
	and temp, rand

	rcall Z_LINE1
	
	cpi temp, 0
	brne NOT_LINE_1
	rcall SHIFT_LINE_RAND
	NOT_LINE_1:
	cpi temp, 0
	breq LINE_1
	rcall SHIFT_LINE_LEFT
	LINE_1:

	rcall Z_LINE2

	cpi temp, 1
	brne NOT_LINE_2
	rcall SHIFT_LINE_RAND
	NOT_LINE_2:
	cpi temp, 1
	breq LINE_2
	rcall SHIFT_LINE_LEFT
	LINE_2:

	rcall Z_LINE3

	cpi temp, 2
	brne NOT_LINE_3
	rcall SHIFT_LINE_RAND
	NOT_LINE_3:
	cpi temp, 2
	breq LINE_3
	rcall SHIFT_LINE_LEFT
	LINE_3:
	
	rcall Z_LINE4

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
	cbi SETTING_A, RS_A
	out PORT_LCD_A, temp
	sbi SETTING_A, EN_A
	cbi SETTING_A, EN_A
	ret
SET_CURSOR_POS_2:
	cbi SETTING_B, RS_B
	out PORT_LCD_B, temp
	sbi SETTING_B, EN_B
	cbi SETTING_B, EN_B
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
	out PORT_KEY,temp 
	in temp ,PIN_KEY 			; read input line
	ori temp ,0b11110000 	; mask upper bits
	cpi temp ,0b11111111 	; a key in this column pressed?
	
	brne KEY_ROW_FOUND 		; key found
	adiw ZL,4 				; column not found, point Z one row down

	; read column 2
	ldi temp ,0b10111111 		; PB6 = 0
	out PORT_KEY,temp 
	in temp ,PIN_KEY 			; read again input line
	ori temp ,0b11110000 	; mask upper bits
	cpi temp ,0b11111111 	; a key in this column?
	
	brne KEY_ROW_FOUND 		; key found
	adiw ZL,4 				; column not found, another four keys down

	; read column 3
	ldi temp ,0b11011111 		; PB5 = 0
	out PORT_KEY,temp 
	in temp ,PIN_KEY 			; read last line
	ori temp ,0b11110000 	; mask upper bits
	cpi temp ,0b11111111 	; a key in this column?

	brne KEY_ROW_FOUND 		; key found
	adiw ZL,4 				; column not found, another four keys down
	
	; read column 4
	ldi temp ,0b011101111 	; PB4 = 0
	out PORT_KEY,temp 
	in temp ,PIN_KEY 			; read last line
	ori temp ,0b11110000 	; mask upper bits
	cpi temp ,0b11111111 	; a key in this column?

	brne KEY_ROW_FOUND		; unexpected: no key in this column pressed
	rjmp NO_KEY

	KEY_ROW_FOUND: 			; column identified, now identify row
		lsr temp 			; shift a logic 0 in left, bit 0 to carry
		brcc KEY_FOUND 		; a zero rolled out, key is found
		adiw ZL,1 			; point to next key code of that column
		rjmp KEY_ROW_FOUND 	; repeat shift
KEY_FOUND: 				; pressed key is found 
	lpm 				; read key code to R0
	mov key, r0 		; countinue key processing

	ldi temp, 0x0F
	or temp, r0
	cpi temp, 0xFF
	breq MOVE_POINTER

	rcall Z_LINE1
	ld r0, Z 
	cp key, r0
	brne CHECK_LINE2
	rjmp MATCH

	CHECK_LINE2:
		rcall Z_LINE2
		ld r0, Z 
		cp key, r0
		brne CHECK_LINE3
		rjmp MATCH
	CHECK_LINE3:
		rcall Z_LINE3
		ld r0, Z 
		cp key, r0
		brne CHECK_LINE4
		rjmp MATCH
	CHECK_LINE4:
		rcall Z_LINE4
		ld r0, Z 
		cp key, r0
		brne NO_MATCH
		rjmp MATCH

MOVE_POINTER:
	mov temp, r0
	cpi temp, 0xFA
	breq POINTER_UP
	cpi temp, 0xFB
	breq POINTER_DOWN
	rjmp NO_KEY

	POINTER_UP:
		cpi pointer, 1
		breq TO_NO_KEY
		dec pointer
		
		cpi pointer, 1
		brne CEK_UP_2
		rcall SET_POINTER_1
		rcall DEL_POINTER_2
		TO_NO_KEY:
		rjmp NO_KEY

		CEK_UP_2:
		cpi pointer, 2
		brne CEK_UP_3
		rcall SET_POINTER_2
		rcall DEL_POINTER_3
		rjmp NO_KEY

		CEK_UP_3:
		rcall SET_POINTER_3
		rcall DEL_POINTER_4
		rjmp NO_KEY

	POINTER_DOWN:
		cpi pointer, 4
		breq NO_KEY
		inc pointer

		cpi pointer, 4
		brne CEK_DOWN_3
		rcall SET_POINTER_4
		rcall DEL_POINTER_3
		rjmp NO_KEY

		CEK_DOWN_3:
		cpi pointer, 3
		brne CEK_DOWN_2
		rcall SET_POINTER_3
		rcall DEL_POINTER_2
		rjmp NO_KEY

		CEK_DOWN_2:
		rcall SET_POINTER_2
		rcall DEL_POINTER_1
		rjmp NO_KEY

NO_MATCH:
	ldi temp, 0xC0
	rcall SET_CURSOR_POS_2
	ldi PA, 0x5F
	dec lives
	mov temp, lives

	cpi temp, 2
	breq LIVE_2
	cpi temp, 1
	breq LIVE_1
	cpi temp, 0
	brne NO_KEY
	rcall WRITE_FAST_2
	rcall WRITE_FAST_2
	rcall WRITE_FAST_2
	rjmp DEAD
	
	LIVE_1:
	rcall WRITE_FAST_2
	LIVE_2:
	rcall WRITE_FAST_2

	rjmp NO_KEY
MATCH:
	ldi temp, 0x0f
	out PORT_LED, temp
	inc score_satuan
	mov temp, score_satuan
	cpi temp, 0x3A
	brne DISP_SCORE
	ldi temp, 0x30
	mov score_satuan, temp
	inc score_puluhan
	mov temp, score_puluhan
	cpi temp, 0x3A
	brne DISP_SCORE
	ldi temp, 0x30
	mov score_puluhan, temp
	inc score_ratusan

	DISP_SCORE:
	ldi temp, 0x94
	rcall SET_CURSOR_POS_2
	mov PA, score_ratusan
	rcall WRITE_FAST_2
	mov PA, score_puluhan
	rcall WRITE_FAST_2
	mov PA, score_satuan
	rcall WRITE_FAST_2	
NO_KEY:
	clr temp
	out TCNT1L, temp
	out TCNT1H, temp
	
	pop ZL
	pop ZH
	pop r0
	pop temp
	out SREG, temp
	pop temp
	reti

; Pointer conf
	DEL_POINTER_1:
		ldi temp, 0x80
		rcall SET_CURSOR_POS
		ldi PA, 0x20
		rcall WRITE_FAST
		ret
	DEL_POINTER_2:
		ldi temp, 0xC0
		rcall SET_CURSOR_POS
		ldi PA, 0x20
		rcall WRITE_FAST
		ret
	DEL_POINTER_3:
		ldi temp, 0x94
		rcall SET_CURSOR_POS
		ldi PA, 0x20
		rcall WRITE_FAST
		ret
	DEL_POINTER_4:
		ldi temp, 0xD4
		rcall SET_CURSOR_POS
		ldi PA, 0x20
		rcall WRITE_FAST
		ret

	SET_POINTER_1:
		ldi temp, 0x80
		rcall SET_CURSOR_POS
		ldi PA, 0x3E
		rcall WRITE_FAST
		ret
	SET_POINTER_2:
		ldi temp, 0xC0
		rcall SET_CURSOR_POS
		ldi PA, 0x3E
		rcall WRITE_FAST
		ret
	SET_POINTER_3:
		ldi temp, 0x94
		rcall SET_CURSOR_POS
		ldi PA, 0x3E
		rcall WRITE_FAST
		ret
	SET_POINTER_4:
		ldi temp, 0xD4
		rcall SET_CURSOR_POS
		ldi PA, 0x3E
		rcall WRITE_FAST
		ret
	
DEAD:
	ldi ZH, high(2*dead_message)
	ldi ZL, low (2*dead_message)
	rcall CLEAR_LCD
	rcall LOADBYTE
	rcall ENDLESS_LOOP

Z_LINE1:
	ldi ZH, high(line1)
	ldi ZL, low (line1)
	ret
Z_LINE2:
	ldi ZH, high(line2)
	ldi ZL, low (line2)
	ret
Z_LINE3:
	ldi ZH, high(line3)
	ldi ZL, low (line3)
	ret
Z_LINE4:
	ldi ZH, high(line4)
	ldi ZL, low (line4)
	ret
		
ENDLESS_LOOP:	rjmp ENDLESS_LOOP

;data
	welcome_message:
		.db "SELAMAT DATANG DI"
		.db "NUMBER TILES !1!"
		.db 0
	askname_message:
		.db "MASUKKAN NAMA ANDA", 0
		.db 0
	level_message:
		.db "PILIH LEVEL AWAL"
		.db 0
	stage_message:
		.db "PLAYER : ",0,0,"SCORE ",0,"LIVES "
		.db 0
	dead_message:
		.db "YOU LOSE"
		.db 0
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
	.db 0x31, 0x32, 0x33, 0xFF
	.db 0x34, 0x35, 0x36, 0xFA
	.db 0x37, 0x38, 0x39, 0xFB
	.db 0xFF, 0x30, 0xFF, 0xFF
