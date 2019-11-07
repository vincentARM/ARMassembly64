/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* conversion décimale d'un registre 64 bits  */

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
szZonesConv:         .skip 21       // pour non signée
szZonesConvS:        .skip 22       // pour signée
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    /* test valeur normale */
    mov x0,#1234                // valeur à convertir
    ldr x1,qAdrszZonesConv      // adresse zone receptrice
    bl conversion10
    affmemtit retour x1  2
    affregtit retour 0
    mov x1,x0                   // longueur zone
    ldr x0,qAdrszZonesConv      // adresse zone receptrice
    bl affichageMessSP
    ldr x0,qAdrszRetourLigne
    mov x1,LGRETLIGNE
    bl affichageMessSP
    /* test plus grande valeur */
    mov x0,-1
    ldr x1,qAdrszZonesConv
    bl conversion10
    affmemtit retour x1  2
    affregtit retour 0
    mov x1,x0
    ldr x0,qAdrszZonesConv
    bl affichageMessSP
    ldr x0,qAdrszRetourLigne
    mov x1,LGRETLIGNE
    bl affichageMessSP
    /* test zero   */
    mov x0,0
    ldr x1,qAdrszZonesConv
    bl conversion10
    affmemtit retour x1  2
    affregtit retour 0
    mov x1,x0
    ldr x0,qAdrszZonesConv
    bl affichageMessSP
    ldr x0,qAdrszRetourLigne
    mov x1,LGRETLIGNE
    bl affichageMessSP

    /* TEST VALEURS SIGNEES  */
    /* test valeur normale */
    mov x0,1234                // valeur à convertir
    ldr x1,qAdrszZonesConv      // adresse zone receptrice
    bl conversion10S
    affmemtit retour x1  2
    affregtit retour 0
    mov x1,x0                   // longueur zone
    ldr x0,qAdrszZonesConv      // adresse zone receptrice
    bl affichageMessSP
    ldr x0,qAdrszRetourLigne
    mov x1,LGRETLIGNE
    bl affichageMessSP
    mov x0,-12345                // valeur à convertir
    ldr x1,qAdrszZonesConv      // adresse zone receptrice
    bl conversion10S
    affmemtit retour x1  2
    affregtit retour 0
    mov x1,x0                   // longueur zone
    ldr x0,qAdrszZonesConv      // adresse zone receptrice
    bl affichageMessSP
    ldr x0,qAdrszRetourLigne
    mov x1,LGRETLIGNE
    bl affichageMessSP
    /* test plus grande valeur */
    mov x0,-1
    ldr x1,qAdrszZonesConv
    bl conversion10S
    affmemtit retour x1  2
    affregtit retour 0
    mov x1,x0
    ldr x0,qAdrszZonesConv
    bl affichageMessSP
    ldr x0,qAdrszRetourLigne
    mov x1,LGRETLIGNE
    bl affichageMessSP
    /* test zero   */
    mov x0,0
    ldr x1,qAdrszZonesConv
    bl conversion10S
    affmemtit retour x1  2
    affregtit retour 0
    mov x1,x0
    ldr x0,qAdrszZonesConv
    bl affichageMessSP
    ldr x0,qAdrszRetourLigne
    mov x1,LGRETLIGNE
    bl affichageMessSP

100:                            // fin standard du programme
    ldr x0,qAdrszMessFinPgm     // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszZonesConv:         .quad szZonesConv
qAdrszZonesConvS:        .quad szZonesConvS
qAdrszRetourLigne:       .quad szRetourLigne
/******************************************************************/
/*     conversion décimale non signée                             */ 
/******************************************************************/
/* x0 contient la valeur à convertir  */
/* x1 contient la zone receptrice  longueur >= 21 */
/* la zone recptrice contiendra la chaine ascii cadrée à gauche */
/* et avec un zero final */
/* x0 retourne la longueur de la chaine sans le zero */
.equ LGZONECONV,   20
conversion10:
    stp x5,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    mov x4,#LGZONECONV        // position dernier chiffre
    mov x5,#10                // conversion decimale
1:                            // debut de boucle de conversion
    mov x2,x0                 // copie nombre départ ou quotients successifs
    udiv x0,x2,x5             // division par le facteur de conversion
    msub x3,x0,x5,x2           //calcul reste
    add x3,x3,#48              // car c'est un chiffre
    sub x4,x4,#1              // position précedente
    strb w3,[x1,x4]           // stockage du chiffre
    cbnz x0,1b                 // arret si quotient est égale à zero
    //affmemtit routine x1 2
    mov x2,LGZONECONV          // calcul longueur de la chaine (20 - dernière position)
    sub x0,x2,x4               // car pas d'instruction rsb en 64 bits
                               // mais il faut déplacer la zone au début
    cbz x4,3f                  // si pas complète
    mov x2,0                   // position début  
2:    
    ldrb w3,[x1,x4]            // chargement d'un chiffre
    strb w3,[x1,x2]            // et stockage au debut
    add x4,x4,#1               // position suivante
    add x2,x2,#1               // et postion suivante début
    cmp x4,LGZONECONV - 1      // fin ?
    ble 2b                     // sinon boucle
3: 
    mov w3,0
    strb w3,[x1,x2]             // zero final
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x5,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     conversion décimale signée                             */ 
/******************************************************************/
/* x0 contient la valeur à convertir  */
/* x1 contient la zone receptrice  longueur >= 21 */
/* la zone recptrice contiendra la chaine ascii cadrée à gauche */
/* et avec un zero final */
/* x0 retourne la longueur de la chaine sans le zero */
.equ LGZONECONV,   21
conversion10S:
    stp x5,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    cmp x0,0
    bge 11f
    mov x3,'-'
    mvn x0,x0
    add x0,x0,1
    b 12f
11:
    mov x3,'+'
12:
    strb w3,[x1]
    mov x4,#LGZONECONV        // position dernier chiffre
    mov x5,#10                // conversion decimale
1:                            // debut de boucle de conversion
    mov x2,x0                 // copie nombre départ ou quotients successifs
    udiv x0,x2,x5             // division par le facteur de conversion
    msub x3,x0,x5,x2           //calcul reste
    add x3,x3,#48              // car c'est un chiffre
    sub x4,x4,#1              // position précedente
    strb w3,[x1,x4]           // stockage du chiffre
    cbnz x0,1b                 // arret si quotient est égale à zero
    mov x2,LGZONECONV          // calcul longueur de la chaine (21 - dernière position)
    sub x0,x2,x4               // car pas d'instruction rsb en 64 bits
                               // mais il faut déplacer la zone au début
    cmp x4,1
    beq 3f                     // si pas complète
    mov x2,1                   // position début  
2:    
    ldrb w3,[x1,x4]            // chargement d'un chiffre
    strb w3,[x1,x2]            // et stockage au debut
    add x4,x4,#1               // position suivante
    add x2,x2,#1               // et postion suivante début
    cmp x4,LGZONECONV - 1      // fin ?
    ble 2b                     // sinon boucle
3: 
    mov w3,0
    strb w3,[x1,x2]             // zero final
    add x0,x0,1                // longueur chaine doit tenir compte du signe
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x5,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
