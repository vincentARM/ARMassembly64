/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* pour test macro et routines affichage  */
/* et test des instructions en assembleur 64 bits */

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
szMessFinPgm:          .asciz "Fin ok du programme.\n"
qVal:                    .8byte 12345678901234         // pour verif pseudo instruction
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
//iZonesTest:         .skip 8 * 20
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm    // message de début
    bl affichageMess
    affichelib Exemple
    mov x0,0xFFFFFFFFFFFF        // valeur de + de 32 bits
    mov x1,1 << 21               //> déplacement 1 bit en position 21
    mov x2,0b11                  // 2 bits
    mov x3,x2,lsl 5              // deplacement en position 5
    mov x4,0xFFFFFFFFFFFF
    movk x4,#5,lsl 16            // insertion sans raz des bits précedents
    affregtit verifmov 0
    mov x5,0xFFFFFFFFFFFF
    movz x5,#5,lsl 16            // insertion avec raz
    mov x6,x0
    mov w7,0x123
    mov w6,w7                   // pour verifier ce que devient la partie haute
    mov x8,10                   // pour verifier valeurs inverses de 10
    movn x9,10                  // exact
    mvn  x10,x8                 // fausse
    affregtit verifmove1 5
    mov x11,-10               // valeur exacte de - 10
    add x12,x10,20             // ce calcul est faux !!
    mov x13, 12
    add x14, x13, w8, UXTB #2   // = x13 +(w8 * 4)
    affregtit verifmove2 10
    affichelib verifbzero      // pour test des instructions branch si zero ou non
    mov x0,0
    cbnz x0,1f
    cbz  x0,2f
1:
    affichelib nonzero
    b 3f
2:
    affichelib egalazero
3:
    mov x0,0b10101            // pour verification des test avec branch
    tbnz x0,0b100,4f          // essayer avec x0,0b11011    le 3ième bit est bien à zero
    tbz  x0,0b100,5f
4:
    affichelib tbnznonzero
    b 6f
5:
    affichelib tbegalazero
6:
    affregtit  verifappel 0
    mov x4,sp
    bl testRoutine
    mov x5,sp
    affregtit  verifappelret 0

    ldr x0,qAdrszMessFinPgm     // message de fin
    bl affichageMess
100:                            // fin standard du programme
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
//iAdriZonesTest:  .quad iZonesTest
/******************************************************************/
/*     test routine          */ 
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

