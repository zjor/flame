;=========================================================
; Coded by Sergey Roiz on 21th of March 2002
; This is my first serious program on assembler
; You can express yor opinion or any ideas by writing me. 
; e-mail: flameasm@yandex.ru
;=========================================================
	.model small
	.stack 100h
	.data
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
buffer	db	320*200	dup(0)
seed	dw	1
exit_msg	db	" Coded by Sergey Roiz on 21th of March 2002", 13, 10
		db	" e-mail: flameasm@yandex.ru", 13, 10, '$'
	.code
	.386
start:
;set 320*200*256 video mode
	mov ax, 0013h
	int 10h
;set new palette
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
	mov ax, 0040h
	mov es, ax
	mov ax, es:[006Ch]
	mov seed, ax
	mov ax, 0A000h
	mov es, ax	
;while not esc pressed
main:
;generating fire 
	mov di, offset buffer
	add di, 320*198
	mov dx, 320
gen_fire:
;random
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

	mov [di], ax
	inc di
	dec dx
	jnz gen_fire

;bluring line
	mov di, offset buffer
	add di, 320*198+1
	mov dx, 320-2
blur_line:
	xor ax, ax
	xor bx, bx
	mov al, [di-1]
	mov bl, [di]
	add ax, bx
	mov bl, [di+1]
	add ax, bx
	mov bl, [di+2]
	add ax, bx
	shr ax, 2
	mov [di], al
	inc di
	dec dx
	jnz blur_line
;blur fire
	mov si, offset buffer
	add si, 321
	mov cx, 320*199      
	xor bx, bx
	align 2
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
	align   2
skip:
	mov     [si-320], al
	inc     di
	inc     si
	dec     cx
	jnz blur_fire    

;pause
	mov dx, 10000
	mov ah, 86h
	int 15h
	mov dx, 03DAh
vrtl1:
	in al, dx
	test al, 8
	jnz vrtl1
vrtl2:
	in al, dx
	test al, 8
	jnz vrtl2
	mov si, offset buffer
	xor di, di
	mov cx, 320*100
	rep movsw
;check if last key was esc
	in al, 60h
	cmp al, 81h
	jnz main
;return text video mode
	mov ax, 0003h
	int 10h
;print exit message
	mov ah, 9
	mov dx, offset exit_msg
	int 21h
;exit to dos
	mov ax, 4C00h
	int 21h
end start
 