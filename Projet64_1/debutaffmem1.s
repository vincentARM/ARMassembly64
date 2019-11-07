/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* test macros affichage zone mémoire asm 64 bits  */

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
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
qZonesTest:         .skip 8 * 20
szZoneConv:        .skip 20
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    affichelib DebutPile
    mov x0,sp
    bl affReg16
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    affichelib Exemple
    adr x0,qAdrszMessDebutPgm
    affmemtit debut x0 4
    mov x0,0xFFF
    mov x1,0x1111
    mov x2,0x2222
    affregtit testregistre2 0

    adr x0,testRoutine
    affmemtit debut1XXXXXXXXXXXX x0 4

    adrp x0,testRoutine
    affmemtit debut2 x0 4

    adr x0,.text
    //sub x0,x0,4           // adresse inaccessible 
    affmemtit debut3123456789123456789123456789123456789123456789 x0 4
    affbintit testlibellelong
    affbintit test12
    affichelib FinPile
    mov x0,sp
    bl affReg16
100:                            // fin standard du programme
    ldr x0,qAdrszMessFinPgm     // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdriZonesTest:          .quad qZonesTest

/******************************************************************/
/*     test routine                                               */ 
/******************************************************************/
testRoutine:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    affichelib routine
    mov x0,0x100
    mov x2,0x200
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

