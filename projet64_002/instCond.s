/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* squelette programme asm 64 bits  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*********************************/
/* Initialized data              */
/*********************************/
.data
szMessDebutPgm:          .asciz "Début programme.\n"
.equ LGMESSDEBUT,        . - szMessDebutPgm
szMessFinPgm:            .asciz "Fin ok du programme.\n"
.equ LGMESSFIN,          . - szMessFinPgm
szRetourLigne:            .asciz "\n"
.equ LGRETLIGNE,         . - szRetourLigne
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
qZonesTest:         .skip 8 * 20
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    affichelib Exemple
    mov x0,#1
    mov x1,#2
    mov x2,#4
    cmp x0,#2                 // ou mettre 1
    csel x0,x1,x2,eq
    affetattit verifetat1
    affregtit testregistre1 0
    mov x0,#1
    mov x1,#3
    cmp x0,#1                // ou mettre 1
    cinc x0,x1,eq            // si egal x0 = x1 + 1 sinon x0 = x1
    affetattit verifetat2
    affregtit testregistre2 0
    mov x0,#1
    mov x1,#2
    mov x2,#4
    cmp x0,#1                 // ou mettre 1
    csinc x0,x1,x2,eq         // si egal x0 = x2 + 1 sinon x0 = x1
    affetattit verifetat3
    affregtit testregistre3 0
    mov x0,-4                 // calcul valeur absolue
    cmp x0,0                  // en 2 instructions
    cneg x0,x0,lt
    affregtit testvaleurabsolue 0

    mov x0,4                 // faire varier de 0 à 5
    mov x1,1                 // borne inférieure
    mov x2,4                 // borne superieure
    cmp x0,x1
    ccmp x0,x2,0,ge          // verifie que x1 <= x0 <= x2
    bgt 1f
    affetattit veriftrue     
    affregtit testregistre4 0
    b 2f
1:
   affetattit veriffalse
2:
    mov x0,1                 // faire varier de 0 à 5
    mov x1,1                 // borne inférieure
    mov x2,4                 // borne superieure
    cmp x0,x1
    ccmp x0,x2,0,gt         // verifie que x1 < x0 < x2
    bge 3f
    affetattit veriftrue5     
    affregtit testregistre5 0
    b 4f
3:
   affetattit veriffals5
4:
100:                           // fin standard du programme
    ldr x0,qAdrszMessFinPgm    // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                   // code retour
    mov x8,EXIT                // system call "Exit"
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne


