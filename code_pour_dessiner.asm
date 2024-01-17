; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XNextEvent

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern printf
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1

global main

section .bss
display_name:	resq	1
screen:			resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1
image_x: resd 1
image_y: resd 1
c_r: resd 1
c_i: resd 1
z_r: resd 1
z_i: resd 1
i: resd 1
x: resd 1
y: resd 1
tmp: resd 1

section .data

zero: dd 0.0
two: dd 2.0
four: dd 4.0
x1f: dd -2.1
x2f: dd 0.6
y1f: dd -1.2
y2f: dd 1.2

event: times 24 dq 0

x1:	dd	0
x2:	dd	0
y1:	dd	0
y2:	dd	0
zoom: dd 100.0
max_iter: dd 50

section .text
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
xor     rdi,rdi
call    XOpenDisplay	; Création de display
mov     qword[display_name],rax	; rax=nom du display

; display_name structure
; screen = DefaultScreen(display_name);
mov     rax,qword[display_name]
mov     eax,dword[rax+0xe0]
mov     dword[screen],eax

mov rdi,qword[display_name]
mov esi,dword[screen]
call XRootWindow
mov rbx,rax

mov rdi,qword[display_name]
mov rsi,rbx
mov rdx,10
mov rcx,10
mov r8,400	; largeur
mov r9,400	; hauteur
push 0xFFFFFF	; background  0xRRGGBB
push 0x00FF00
push 1
call XCreateSimpleWindow
mov qword[window],rax

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,131077 ;131072
call XSelectInput

mov rdi,qword[display_name]
mov rsi,qword[window]
call XMapWindow

mov rsi,qword[window]
mov rdx,0
mov rcx,0
call XCreateGC
mov qword[gc],rax

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov rdx,0x000000	; Couleur du crayon
call XSetForeground

boucle: ; boucle de gestion des évènements
mov rdi,qword[display_name]
mov rsi,event
call XNextEvent

cmp dword[event],ConfigureNotify	; à l'apparition de la fenêtre
je dessin							; on saute au label 'dessin'

cmp dword[event],KeyPress			; Si on appuie sur une touche
je closeDisplay						; on saute au label 'closeDisplay' qui ferme la fenêtre
jmp boucle

;#########################################
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
dessin:



;couleur du dessin
mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0x000000	; Couleur du crayon ; noir
call XSetForeground

;taille de l'image
movss xmm1,[x2f]
subss xmm1,[x1f]
mulss xmm1, dword[zoom]
cvtss2si eax,xmm1
mov dword[image_x], eax
movss xmm1,[y2f]
subss xmm1,[y1f]

mulss xmm1, dword[zoom]
cvtss2si eax,xmm1

mov dword[image_y], eax

mov dword[x],0
BoucleX:
mov dword[y],0
BoucleY:

;calcul de c_r
cvtsi2ss xmm1,dword[x]
movss xmm2,dword[zoom]
divss xmm1,xmm2
addss xmm1,dword[x1f]
movss dword[c_r],xmm1

;calcul de c_i
cvtsi2ss xmm1,dword[y]
movss xmm2,dword[zoom]
divss xmm1,xmm2
addss xmm1,dword[y1f]
movss dword[c_i],xmm1

;initialisation des variables à 0
movss xmm1,dword[zero]
movss dword[z_r],xmm1
movss dword[z_i],xmm1
mov dword[i],0

BoucleCalcul:

;Calcul de z_r
movss xmm1, dword[z_r]
movss dword[tmp], xmm1
mulss xmm1,xmm1
movss xmm2, dword[z_i]
mulss xmm2, xmm2
subss xmm1,xmm2
addss xmm1,dword[c_r]
movss dword[z_r], xmm1

;Calcul de z_i
movss xmm1, dword[z_i]
mulss xmm1, dword[two]
mulss xmm1, dword[tmp]
addss xmm1, dword[c_i]
movss dword[z_i], xmm1

inc dword[i]

movss xmm1, dword[z_r]
mulss xmm1,xmm1
movss xmm2, dword[z_i]
mulss xmm2, xmm2
addss xmm1,xmm2
ucomiss xmm1,dword[four]
ja FinCalcul


mov eax,dword[i]
cmp eax, dword[max_iter]
jb BoucleCalcul
mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x]	; coordonnée source en x
mov r8d,dword[y]	; coordonnée source en y
mov r9d,dword[x]	; coordonnée destination en x
push qword[y]		; coordonnée destination en y
call XDrawLine



FinCalcul:




inc dword[y]
mov eax, dword[image_y]
cmp eax,dword[y]
ja BoucleY

inc dword[x]
mov eax, dword[image_x]
cmp eax,dword[x]
ja BoucleX


jmp flush

flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	
