/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* affichage message standard  */

/************************************/
/* Constantes                       */
/************************************/
.equ STDOUT, 1     // Linux output console
.equ EXIT,   93     // Linux syscall 64 bits
.equ WRITE,  64     // Linux syscall 64 bits
/*********************************/
/* Initialized data              */
/*********************************/
.data
szMess:   .asciz "Bonjour, le monde 64 bits s'ouvre à nous.\n"
.equ LGMESS, . - szMess
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                           // entry of program 

    ldr x1,iAdrszMess
    mov x0, #1                  // STDOUT 
    mov x2,#LGMESS              // longueur du message
    mov x8, 64                  // system call 'write'
    svc #0
    mov x0,5                    // code retour
    mov x8,93                   // system call "Exit"
    svc #0

iAdrszMess:   .quad szMess
