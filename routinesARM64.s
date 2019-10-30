/* Routines pour assembleur arm 64 bits raspberry */
/*******************************************/
/* CONSTANTES                              */
/*******************************************/
.include "constantesARM64.inc"
.equ LGZONEADR,   50
.data
sMessAffBin:     .ascii "Affichage x0 base 2 : "
sLibBin:         .fill LGZONEADR, 1, ' '
                 .ascii "\n"
sZoneBin:        .space 76,' '
                 .asciz "\n"
szMess1:         .asciz "OK\n"
.text
.global affichageMess,affichageReg2
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
/******************************************************************/
/*     affichage d'un registre 64 bits en binaire                 */ 
/******************************************************************/
/* x0 est le registre à afficher */
/* x1 contient le libellé       */
affichageReg2:
    stp x0,lr,[sp,-80]!        // save  registres
    stp x7,x8,[sp,64]          // save  registres
    stp x5,x6,[sp,48]          // save  registres
    stp x1,x2,[sp,32]          // save  registres
    stp x3,x4,[sp,16]          // save  registres
    ldr x3,iAdrsLibBin         // adresse de stockage du resultat
    mov x2,#0
1:                             // boucle copie
    ldrb w4,[x1,x2]            // charge un octet
    cmp w4,#0                  // zéro ?
    beq 2f                     // oui -> fin boucle
    strb w4,[x3,x2]            // stocke dans zone affichage
    add x2,x2,#1               // increment indice
    cmp x2,#LGZONEADR          // longueur maxi ?
    ble 1b                     // non -> boucle
2:

    ldr x1,iAdrsZoneBin        // zone reception
    mov x2,63                  // position bit de départ
    mov x3,0                   // position écriture caractère
    mov x5,1                   // valeur pour tester ubn bit
    mov x4,x0
    mov x7,48
    mov x8,49

3:                             // debut boucle
    lslv x6,x5,x2              // déplacement valeur de test à la position à tester
    tst x4,x6                  // test du bit à cette position
    csel  x6,x7,x8,eq
    strb w6,[x1,x3]            // caractère ascii ->  zone d'affichage
    sub x2,x2,#1               // decrement pour bit suivant
    add x3,x3,#1               // + 1 position affichage caractère
    and x6,x2,#7               // extraction 3 derniers bits du compteur
    cmp x6,#7                  // egaux à 111 ?
    bne 4f
    add x3,x3,#1               // oui on ajoute un blanc 
4:
    cmp x2,#0                  // 64 bits analysés ?
    bge 3b                     // non -> boucle
    ldr x0,iAdrsZoneMessBin    // adresse du message résultat
    bl affichageMess           // affichage message
100:                           // fin standard de la fonction
    ldp x3,x4,[sp,16]          // restaur des  2 registres
    ldp x1,x2,[sp,32]          // restaur des  2 registres
    ldp x5,x6,[sp,48]          // restaur des  2 registres
    ldp x7,x8,[sp,64]          // restaur des  2 registres
    ldp x0,lr,[sp],80          // restaur des  2 registres
    ret    
iAdrsZoneBin:          .quad sZoneBin       
iAdrsZoneMessBin:      .quad sMessAffBin
iAdrsLibBin:     .quad sLibBin

