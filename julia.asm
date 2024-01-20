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
line: resd 1
col: resd 1
stock: resd 1
i: resd 1
x: resd 1
y: resd 1
color: resd 1

section .data


zss: dd 255.0
zero: dd 0.0
two: dd 2.0
four: dd 4.0
a: dd -0.5
b: dd 0.6
taille: dd 400.0
xmin: dd -1.25
xmax: dd 1.25
ymin: dd -1.25
ymax: dd 1.25
event: times 24 dq 0
max_iter: dd 200

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





mov dword[line],0
BoucleX:
mov dword[col],0
BoucleY:

mov dword[i],1

;calcul de x
cvtsi2ss xmm1,dword[col]
movss xmm2,dword[xmax]
subss xmm2, dword[xmin]
mulss xmm1, xmm2
divss xmm1, dword[taille]
addss xmm1,dword[xmin]
movss dword[x],xmm1

;calcul de y
cvtsi2ss xmm1,dword[line]
movss xmm2,dword[ymax]
subss xmm2, dword[ymin]
mulss xmm1, xmm2
divss xmm1, dword[taille]
movss xmm0,dword[ymax]
subss xmm0, xmm1
movss dword[y],xmm0



BoucleTant:

movss xmm1, dword[x]
mulss xmm1,xmm1
movss xmm2, dword[y]
mulss xmm2, xmm2
addss xmm1,xmm2
ucomiss xmm1,dword[four]
ja DessinCouleur


mov eax,dword[i]
cmp eax, dword[max_iter]
ja DessinNoir


;calcul de x
movss xmm0,dword[x]
movss dword[stock], xmm0
mulss xmm0, xmm0
movss xmm1, dword[y]
mulss xmm1, xmm1
subss xmm0, xmm1
addss xmm0, dword[a]
movss dword[x],xmm0

;calcul de y
movss xmm0, dword[y]
mulss xmm0, dword[two]
mulss xmm0, dword[stock]
addss xmm0, dword[b]
movss dword[y], xmm0

inc dword[i]

jmp BoucleTant

DessinNoir:

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0x000000	; Couleur du crayon ; noir
call XSetForeground




jmp FinCalcul

DessinCouleur:

mov dword[stock], 4
mov eax, dword[i]
mul dword[stock]
mov dword[stock], 256
div dword[stock]
mov [color+2], dl

mov eax, dword[i]
add eax, eax
cmp eax,255
jbe AssezPetit
mov eax, 255
AssezPetit:
mov [color+1], al

mov dword[stock], 6
mov eax, dword[i]
mul dword[stock]
mov dword[stock], 256
div dword[stock]
mov [color], dl

mov byte[color+3], 0

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov rdx,0
mov edx,dword[color]	; Couleur du crayon
call XSetForeground

FinCalcul:





mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[col]	; coordonnée source en x
mov r8d,dword[line]	; coordonnée source en y
mov r9d,dword[col]	; coordonnée destination en x
push qword[line]		; coordonnée destination en y
call XDrawLine



inc dword[col]
cvtss2si eax, dword[taille]
cmp eax,dword[col]
ja BoucleY

inc dword[line]
cmp eax,dword[line]
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
	
