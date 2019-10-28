/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* affichage message standard  */
/* affichage du registre x0 en base 2 */

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
szMess:          .asciz "Bonjour, le monde 64 bits s'ouvre à nous.\n"
sMessAffBin:     .ascii "Affichage x0 base 2 :\n"
sZoneBin:        .space 76,' '
                 .asciz "\n"
sMessAffHexa:     .ascii "Affichage x0 en hexa : "
sZoneHexa:        .space 20,' '
                 .asciz "\n"
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,iAdrszMess
    bl affichageMess
    mov x0,-1                   // verification -1
    bl affReg2
    bl affReg16
    mov  x0, xzr               // copie du registre zero
    mvn  x0, xzr
    bl affReg16
    //verif registres w0
    mov w0,63                   // registre w0 vs x0
    bl affReg16
    mov x1,255
    ubfx    x0, x1, 4, 1        // extraction du bit en position 4
    bl affReg2

100:                            // fin standard du programme
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0

iAdrszMess:   .quad szMess
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
    lsr x0,x0,x2                  // deplacement droite
    cmp x0,#10                 // >= 10 ?
    bge 2f                     // oui
    add x0,x0,#48                 // non c'est un chiffre
    b 3f
2:
    add x0,x0,#55                 // sinon c'est une lettre A-F
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
/******************************************************************/
/*     affichage d'un registre 64 bits en binaire                 */ 
/******************************************************************/
/* x0 est le registre à afficher */
affReg2:               
    stp x0,lr,[sp,-48]!        // save  registres
    stp x1,x2,[sp,32]          // save  registres
    stp x3,x4,[sp,16]          // save  registres
    ldr x1,iAdrsZoneBin        // zone reception
    mov x2,63                  // position bit de départ
    mov x3,0                   // position écriture caractère
    mov x5,1                   // valeur pour tester ubn bit
    mov x7,x0

1:                             // debut boucle
    lslv x6,x5,x2              // déplacement valeur de test à la position à tester
    tst x7,x6                  // test du bit à cette position
    bne 2f                     
    mov w4,#48                 // bit egal à zero
    b 3f
2:
    mov w4,#49                 // bit egal à un
3:
    strb w4,[x1,x3]            // caractère ascii ->  zone d'affichage
    sub x2,x2,#1               // decrement pour bit suivant
    add x3,x3,#1               // + 1 position affichage caractère
    and x4,x2,#7               // extraction 3 derniers bits du compteur
    cmp x4,#7                  // egaux à 111 ?
    bne 4f
    add x3,x3,#1               // oui on ajoute un blanc 
4:
    cmp x2,#0                  // 64 bits analysés ?
    bge 1b                     // non -> boucle
    ldr x0,iAdrsZoneMessBin    // adresse du message résultat
    bl affichageMess           // affichage message
100:                           // fin standard de la fonction
    ldp x3,x4,[sp,16]          // restaur des  2 registres
    ldp x1,x2,[sp,32]          // restaur des  2 registres
    ldp x0,lr,[sp],48          // restaur des  2 registres
    ret    
iAdrsZoneBin:          .quad sZoneBin       
iAdrsZoneMessBin:      .quad sMessAffBin
/******************************************************************/
/*     Affichage d une chaine avec calcul de sa longueur          */ 
/******************************************************************/
/* x0 contient l'adresse du texte (chaine terminée par zero) */
affichageMess:
    stp x2,lr,[sp,-32]!        // save  registres
    stp x1,x8,[sp,16]          // save  registres
    mov x2,#0                  // compteur taille
1:                             // boucle calcul longueur chaine
    ldrb w1,[x0,x2]            // lecture un octet
    cmp w1,#0                  // fin de chaine si zéro
    beq 2f
    add x2,x2,#1
    b 1b
2:                             // ici x2 contient la longueue de la chaine
    mov x1,x0                  // adresse du texte
    mov x0,#STDOUT             // sortie Linux standard
    mov x8, #WRITE             // code call system "write" */
    svc #0                     // call systeme Linux
    ldp x1,x8,[sp,16]          // restaur des  2 registres
    ldp x2,lr,[sp],32          // restaur des  2 registres
    ret                        // retour adresse lr x30
