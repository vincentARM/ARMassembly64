/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* calcul inverse racine carre float programme asm 64 bits  */
/* voir Wikipedia */
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
sBuffer:             .skip 80
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                               // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    affichelib Exemple
    
    fmov d0,0.15625             // valeur immediate en float
    //fmov d0,4.0                   // test N° 2
    bl calculInvRac
    ldr x1,qAdrsBuffer
    bl convertirFloatDP           // appel conversion du registre d0
    ldr x0,qAdrsBuffer
    bl affichageMess
    ldr x0,qAdrszRetourLigne
    bl affichageMess
    
100:                               // fin standard du programme
    ldr x0,qAdrszMessFinPgm        // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                       // code retour
    mov x8,EXIT                    // system call "Exit"
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdrsBuffer:             .quad sBuffer
/************************************************************/
/*     Calcul inverse racine carrée                         */
/********************************************* **************/
// d0 contient la valeur de départ
// d0 retourne l inverse de la racine carrée
calculInvRac:
    stp x0,lr,[sp,-16]!         // save  registres
    str x1,[sp,-16]!            // save  registres
    str d1,[sp,-16]!            // save  registres
    stp d2,d3,[sp,-16]!         // save  registres
    fmov d1,0.5                 // charge la constante
    fmul d1,d1,d0               // multiplié par la valeur
    fmov x0,d0                  // pas joli !!
    lsr x0,x0,1                 // mais permet de décaler d une position à droite
    ldr x1,qNombreMagique
    sub x1,x1,x0                // enleve le résultat précédent
    fmov d2,x1                  // pas joli non plus !!
    fmul d0,d1,d2               // iteration 1
    fmul d0,d0,d2
    fmov d3,1.5
    fsub d0,d3,d0
    fmul d2,d0,d2
                                // iteration 2
    fmul d0,d1,d2
    fmul d0,d0,d2
    fsub d0,d3,d0
    fmul d0,d0,d2
100:
    ldp d2,d3,[sp],16           // restaur des  2 registres
    ldr d1,[sp],16              // restaur  registre
    ldr x1,[sp],16              // restaur  registre
    ldp x0,lr,[sp],16           // restaur des  2 registres
    ret                         // retour adresse lr x30
qNombreMagique:    .quad 0x5fe6eb50c7b537a9
