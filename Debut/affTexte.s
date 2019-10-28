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
main:                                          // entry of program 
    // premier affichage
    ldr x1,iAdrszMess
    mov x0, #1                  // STDOUT 
    mov x2,#LGMESS              // longueur du message
    mov x8, 64                  // system call 'write'
    svc #0
    // 2ième affichage par la routine
    ldr x0,iAdrszMess
    bl affichageMess

100:                            // fin standard
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0

iAdrszMess:   .quad szMess

/******************************************************************/
/*     affichage texte avec calcul de la longueur                */ 
/******************************************************************/
/* x0 contient l' addresse du message */
affichageMess:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    mov x2,#0                  // compteur taille
1:                             // boucle calcul longueur chaine
    ldrb w1,[x0,x2]            // lecture un octet
    cmp w1,#0                  // fin de chaine si zéro
    beq 2f
    add x2,x2,#1
    b 1b
2:
    mov x1,x0                  // adresse du texte
    mov x0,#STDOUT             // sortie Linux standard
    mov x8, #WRITE             // code call system "write" */
    svc #0                     // call systeme Linux
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
