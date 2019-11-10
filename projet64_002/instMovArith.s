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
szZoneRec1:         .skip 30
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    affichelib casdumov_label
    mov x0,qAdrszMessDebutPgm    // recupère le déplacement depuis le debut du code
    affregtit testregistre 0
    adr x1,.
    adr x2,qAdrszMessDebutPgm
    sub x3,x2,x1
    affregtit testregistre1 0
    mov x0,szMessFinPgm         // pas d'erreur de compilation !! 
    affregtit verif_mov-label_data 0
    ldr x1,qAdrszMessFinPgm     // x0 contient le deplacement du début de zone
    ldr x2,=.data               // à partir de la data !!!!
    sub x3,x1,x2
   affregtit verif_mov-label_data1 0
    mov x0,0xFFFF               // valeur maxi du mov
    affregtit testregistre3 0
    movk x0,0x1234, lsl 48      // chargement d'une constante de 64 bits
    movk x0,0x5678, lsl 32      // avec movk
    movk x0,0x9ABC, lsl 16
    movk x0,0xDEF0, lsl 0
     affregtit testregistre3 0
    mov x0,5
    //movn x0,x0                // interdit
    movn x0,5                   // ok mais attention ce n'est pas egal à -5
    affregtit not 0
    mov x0,5
    neg x0,x0                   // ici c'est egal à -5 
    affregtit neg 0
    add x0,x0,10                // addition
    affregtit addition 0
    mov x0,1<<63 - 1          // valeur maxi signée positive
    ldr x1,qAdrszZoneRec1  // pour affichage du résultat en décimal signé
    bl conversion10S
    mov x1,x0
    ldr x0,qAdrszZoneRec1
    bl affichageMessSP
    ldr x0,qAdrszRetourLigne
    mov x1,1
    bl affichageMessSP
    mov x1,1<<63 - 1      // valeur maxi signée positive1         
    adds x0,x1,1          // addition de 1 avec maj du registre d'état 
    affetattit addition1  // affichage registre d'état : le flag overflow est à 1
    affregtit addition1 0
    ldr x1,qAdrszZoneRec1  // pour affichage du résultat en décimal signé
    bl conversion10S       
    mov x1,x0
    ldr x0,qAdrszZoneRec1  // et le résultat est negatif ce qui est faux !!!
    bl affichageMessSP
    ldr x0,qAdrszRetourLigne
    mov x1,1
    bl affichageMessSP

    // Soustraction
    mov x1,2
    sub x0,x0,x1
    affregtit soustraction 0
    mov x1,5
    mov x2,4
    mov x3,3
    madd x0,x1,x2,x3            // = (x1 * x2)+ x3
    affregtit multiplication 0
    mov w1,-4
    mov w2,-8
    umull x0,w1,w2
    affregtit multiplicationnonsigne32bits 0
    smull x0,w1,w2
    affregtit multiplicationsigne32bits 0
    /* detection overflow */
    mov x0,1<<63 - 1      // valeur maxi signée positive1
    mov x1,1<<63 - 1      // valeur maxi signée positive1
    mul x2,x0,x1          // partie basse
    smulh x4,x0,x1        // parie haute
    affregtit multiplicationoverflow 0
    mov x0,1<<32 - 1      // valeur signée positive
    mov x1,1<<32 - 1      // valeur signée positive
    mul x2,x0,x1          // partie basse
    smulh x4,x0,x1        // parie haute
    affregtit multiplicationNonoverflow 0
    mov x0,1<<32          // valeur signée positive
    mov x1,1<<32           // valeur signée positive
    mul x2,x0,x1          // partie basse
    smulh x4,x0,x1        // partie haute
    affregtit multiplicationoverflow 0

100:                            // fin standard du programme
    ldr x0,qAdrszMessFinPgm     // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdriZonesTest:          .quad qZonesTest
qAdrszZoneRec1:          .quad szZoneRec1
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

