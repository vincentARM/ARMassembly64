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
    mov x1,5
    mov x0,x1                   // verification registre x1 OK
    bl affReg2
    ldr x0,iAdrszMess
    bl affichageMess
    mov x0,x1                   // x1 est-il bien sauvegardé et restauré ?
    bl affReg2
    //verif registres w0
    mov w0,63                   // registre w0 vs x0
    bl affReg2

100:                            // fin standard du programme
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0

iAdrszMess:   .quad szMess
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
