/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* pour test macro et routines  */

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
szMess:          .asciz "Bonjour, le monde 64 bits s'ouvre à nous.\n"

sMessAffHexa:    .ascii "Affichage x0 en hexa : "
sZoneHexa:       .space 20,' '
                 .asciz "\n"
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
iZonesTest:         .skip 8 * 20
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    mov x0,sp
    bl affReg16
    affichelib Adressepile
    mov x0,sp
    bl affReg16
    ldr x0,iAdrszMess
    bl affichageMess

    affichelib verifinststp
    ldr x5,iAdriZonesTest
    add x5,x5,80
    mov x0,x5
    bl affReg16
    mov x1,#10
    mov x2,#20
    stp x1,x2,[x5,-32]!
    mov x0,x5
    bl affReg16
    ldr x0,[x5]
    bl affReg16
    ldr x0,[x5,8]
    bl affReg16
    mov x0,x5
    bl affReg16
    ldp x1,x2,[x5],32
    mov x0,x5
    bl affReg16
    // test des move
    movz x0,#0xF
    movk x0,#5,lsl 16
    movk x0,010,lsl 32
    affbintit verifmovk
    bl affReg16
    movn x0,4
    affbintit verifmovn
    // Adresse de la pile en fin de programme pour vérification
    affichelib Adressepile
    mov x0,sp
    bl affReg16
100:                            // fin standard du programme
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0

iAdrszMess:      .quad szMess
iAdriZonesTest:  .quad iZonesTest
/******************************************************************/
/*     Converting a register to hexadecimal                      */ 
/******************************************************************/
/* r0 contains value and r1 address area   */
affReg16:
    stp x0,lr,[sp,-48]!        // save  registres
    stp x1,x2,[sp,32]          // save  registres
    stp x3,x4,[sp,16]          // save  registres
    ldr x1,iAdrsZoneHexa       // zone reception
    mov x2,#60                 // start bit position
    mov x4,#0xF000000000000000         // masque
    mov x3,x0                  // save entry value
1:                             // start loop
    and x0,x3,x4               // valeur du registre and du masque
    lsr x0,x0,x2               // deplacement droite
    cmp x0,#10                 // >= 10 ?
    bge 2f                     // oui
    add x0,x0,#48              // non c'est un chiffre
    b 3f
2:
    add x0,x0,#55              // sinon c'est une lettre A-F
3:
    strb w0,[x1],#1            // stocke le chiffre  et + 1 dans la pointeur
    lsr x4,x4,#4                  // deplace le masque de  4 positions
    subs x2,x2,#4                 // decrement compteur de 4 bits <= zero  ?
    bge 1b                     // non -> boucle
    ldr x0,iAdrsMessAffHexa    // adresse du message résultat
    bl affichageMess           // affichage message
100:                           // fin standard de la fonction
    ldp x3,x4,[sp,16]          // restaur des  2 registres
    ldp x1,x2,[sp,32]          // restaur des  2 registres
    ldp x0,lr,[sp],48          // restaur des  2 registres
    ret    
iAdrsMessAffHexa:      .quad sMessAffHexa
iAdrsZoneHexa:         .quad sZoneHexa


