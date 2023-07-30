;=========================================================
; Coded by Sergey Roiz on 21th of March 2002
; This is my second serious program on assembler
; You can express yor opinion or any ideas by writing me. 
; e-mail: flameasm@yandex.ru
;=========================================================
	.model small
	.stack 100h
	.data
;---------------------------------------------------------
palette     label   byte
	i=0
	rept    8
	db      0, 0, i*2
	i=i+1
endm
	i=0
	rept    8
	db      i*2, 0, 16-2*i
	i=i+1
endm
	i=0
	rept    16
	db      16+47*i/16, 0, 0
	i=i+1
endm
	i=0
	rept    48
	db      63, 21*i/16, 0
	i=i+1
endm
	i=0
	rept    48
	db      63, 63, 21*i/24
	i=i+1
endm
	db      179*3	dup(63)
;--------------------------------------------------------
buffer	db	320*200	dup(0)	;screen buffer
;--------------------------------------------------------
seed	dw	1
;--------------------------------------------------------
exit_msg	db	" Coded by Sergey Roiz on 21th of March 2002", 13, 10
		db	" e-mail: flameasm@yandex.ru", 13, 10, '$'
;--------------------------------------------------------
	.code
	.386		;for shl reg, n, where n > 1
start:
;-set 640*480*256 video mode-----------------------------
	mov ax, 4F02h
	mov bx, 0101h
	int 10h
;-------set new palette----------------------------------
	mov ax, @data               
	mov ds, ax
	mov dx, 03C8h
	xor al,al
	out dx,al
	inc dx
	mov cx, 256*3
	mov si, offset palette
set_pal:
	mov al, [si]
	out dx, al
	inc si
	dec cx
	jnz set_pal
;-------get seed-----------------------------------------
	mov ax, 0040h
	mov es, ax
	mov ax, es:[006Ch]
	mov seed, ax
;--------------------------------------------------------
	mov ax, 0A000h
	mov es, ax	
;-------while not esc pressed----------------------------
main:
;-------generate one bar of fire-------------------------
	mov di, offset buffer
	add di, 320*198
	mov dx, 320
gen_bar:
;-------random-------------------------------------------
	mov ax, seed
	mov cx, 8
new_bit:
	mov bx, ax
	and bx, 002Dh
	xor bh, bl
	clc
	jpe shift
	stc
shift:	rcr ax, 1
	dec cx
	jnz new_bit
	mov seed, ax
;--------------------------------------------------------
	mov [di], ax
	inc di
	dec dx
	jnz gen_bar
;-------blur this bar------------------------------------
	mov di, offset buffer
	add di, 320*198
	mov dx, 320
	xor bx, bx
blur_bar:
	xor ax, ax
	add al, [di]
	adc ah, bl
	add al, [di-1]
	adc ah, bl
	add al, [di+1]
	adc ah, bl
	add al, [di+2]
	adc ah, bl
	shr ax, 2
	mov [di], al
	inc di
	dec dx
	jnz blur_bar
;-------blur fire----------------------------------------
	mov si, offset buffer
	add si, 321
	mov cx, 320*199-2      
	xor bx, bx
blur_fire:
	xor     ax, ax
	add     al, [si+321]
	adc     ah, bl
	add     al, [si+319]
	adc     ah, bl
	add     al, [si-1]
	adc     ah, bl
	add     al, [si+1]
	adc     ah, bl
	ifdef   eight
	add     al, [si-321]
	adc     ah, bl
	add     al, [si+321]
	adc     ah, bl
	add     al, [si-319]
	adc     ah, bl
	add     al, [si+319]
	adc     ah, bl
	shr     ax, 3
	else
	shr     ax, 2
	endif
	test ax, ax
	jz skip
	dec     al
skip:
	mov     [si-320], al
	inc     di
	inc     si
	dec     cx
	jnz blur_fire    
;-------pause--------------------------------------------
	mov dx, 5000
	mov ah, 86h
	int 15h
;-------wait retrace-------------------------------------
	mov dx, 03DAh
vrtl1:
	in al, dx
	test al, 8
	jnz vrtl1
vrtl2:
	in al, dx
	test al, 8
	jnz vrtl2
;-------swap_buffers-------------------------------------
	mov ax, 4F05h
	xor bx, bx
	mov dx, 1
	int 10h

	mov si, offset buffer
	mov cx, 20800
	xor bx, bx
	mov di, 24224
second_bank:
	mov al, ds:[si]
	mov es:[di], al
	inc bx
	cmp bx, 320
	jnz skip1
 	xor bx, bx
	add di, 320
skip1:
	inc si
	inc di
	dec cx
	jnz second_bank

	mov ax, 4F05h
	xor bx, bx
	mov dx, 2
	int 10h

	mov cx, 32640
	xor bx, bx
	mov di, 288
third_bank:
	mov al, ds:[si]
	mov es:[di], al
	inc bx
	cmp bx, 320
	jnz skip2
 	xor bx, bx
	add di, 320
skip2:
	inc si
	inc di
	dec cx
	jnz third_bank

	mov ax, 4F05h
	xor bx, bx
	mov dx, 3
	int 10h

	mov cx, 10676
	xor bx, bx
	mov di, 32
fourth_bank:
	mov al, ds:[si]
	mov es:[di], al
	inc bx
	cmp bx, 320
	jnz skip3
 	xor bx, bx
	add di, 320
skip3:
	inc si
	inc di
	dec cx
	jnz fourth_bank
;-------check if last key was esc------------------------
	in al, 60h
	cmp al, 81h
	jnz main
;-------return to text video mode------------------------
	mov ax, 0003h
	int 10h
;-------print exit message-------------------------------
	mov ah, 9
	mov dx, offset exit_msg
	int 21h
;-------exit to dos--------------------------------------
	mov ax, 4C00h
	int 21h
end start
 