/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* test tri 8 octets  avec instruction SIMD asm 64 bits  */
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
szMessErreurGen:            .asciz "Erreur rencontrée :\n"

/*********************************/
/* UnInitialized data            */
/*********************************/
.bss
sBuffer:             .skip 100
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP

    /***************************************/
    affichelib tri8octets
    mov x0,0x0201
    movk x0,0x0403,lsl 16
    movk x0,0x0605,lsl 32
    movk x0,0x0807,lsl 48
    bl tri8Octets
    ldr x1,qAdrsBuffer
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit afftri8_1 x0 2

    ldr x0,qVal1
    bl tri8Octets
    ldr x1,qAdrsBuffer
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit afftri8_2 x0 2

    ldr x0,qVal2
    bl tri8Octets
    ldr x1,qAdrsBuffer
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit afftri8_3 x0 2

    ldr x0,qVal3
    bl tri8Octets
    ldr x1,qAdrsBuffer
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit afftri8_4 x0 2

    ldr x0,qVal4
    bl tri8Octets
    ldr x1,qAdrsBuffer
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit afftri8_4 x0 2

    ldr x0,qVal5
    bl tri8Octets
    ldr x1,qAdrsBuffer
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit afftri8_5 x0 2

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
qAdrsBuffer:                .quad sBuffer
qVal1:                    .quad 0x0102030405060708
qVal2:                    .quad 0x0802070306040501
qVal3:                    .quad 0x4547424449424E51
qVal4:                    .quad 0x0906010307040608
qVal5:                    .quad 0x0103090705121613
qVal6:                    .quad 0x0204080611101514


/******************************************************************/
/*     tri 8 octets     OK                                         */ 
/******************************************************************/
/* x0 contient la valeur à trier   */
/* x0 retourne la valeur triée */
/* attention les registres v ne sont pas sauvegardés */
tri8Octets:                    // fonction
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    mov v0.D[0],x0              // copie dans registre vecteurs
    movi v1.2s,0
    movi v2.2s,0
    mov v1.s[0],v0.s[1]         // eclatement des 8 octets sur 2 vecteurs
    mov v2.s[0],v0.s[0]
    cmgt v3.8b,v1.8b,v2.8b      // comparaison des 2 vecteurs 1
    mov v4.8b, v1.8b
    mov v5.8b, v2.8b
    bit v4.8b,v2.8b,v3.8b       // inversion valeur en fonction du test
    bit v5.8b,v1.8b,v3.8b  

    mov v1.b[3],v4.b[3]          // ici 4 listes tries de 2 valeurs 
    mov v1.b[2],v5.b[3]
    mov v1.b[1],v4.b[1]
    mov v1.b[0],v5.b[1]
    mov v2.b[3],v4.b[2]
    mov v2.b[2],v5.b[2]
    mov v2.b[1],v4.b[0]
    mov v2.b[0],v5.b[0]
    cmgt v3.8b,v1.8b,v2.8b          //cmp 2
    mov v4.8b, v1.8b
    mov v5.8b, v2.8b
    bit v4.8b,v2.8b,v3.8b  
    bit v5.8b,v1.8b,v3.8b 

    mov v1.b[3],v4.b[3]
    mov v1.b[2],v5.b[3]
    mov v1.b[1],v4.b[1]
    mov v1.b[0],v5.b[1]
    mov v2.b[3],v5.b[2]
    mov v2.b[2],v4.b[2]
    mov v2.b[1],v5.b[0]
    mov v2.b[0],v4.b[0]
    cmgt v3.8b,v1.8b,v2.8b          // cmp 3
    mov v4.8b, v1.8b
    mov v5.8b, v2.8b
    bit v4.8b,v2.8b,v3.8b  
    bit v5.8b,v1.8b,v3.8b 

    mov v1.b[3],v4.b[3]              //ici 2 listes triées de 4 valeurs
    mov v1.b[2],v4.b[2]
    mov v1.b[1],v5.b[2]
    mov v1.b[0],v5.b[3]
    mov v2.b[3],v4.b[1]
    mov v2.b[2],v4.b[0]
    mov v2.b[1],v5.b[0]
    mov v2.b[0],v5.b[1]
    cmgt v3.8b,v1.8b,v2.8b          // cmp 4
    mov v4.8b, v1.8b
    mov v5.8b, v2.8b
    bit v4.8b,v2.8b,v3.8b  
    bit v5.8b,v1.8b,v3.8b 

    mov v1.S[0],v4.S[0]
    mov v2.b[3],v5.b[1]
    mov v2.b[2],v5.b[0]
    mov v2.b[1],v5.b[3]
    mov v2.b[0],v5.b[2]
    cmgt v3.8b,v1.8b,v2.8b        // cmp 5
    mov v4.8b, v1.8b
    mov v5.8b, v2.8b
    bit v4.8b,v2.8b,v3.8b  
    bit v5.8b,v1.8b,v3.8b 

    mov v1.b[3],v4.b[3]
    mov v1.b[2],v4.b[2]
    mov v1.b[1],v4.b[0]
    mov v1.b[0],v5.b[0]

    mov v2.b[3],v5.b[2]
    mov v2.b[2],v4.b[1]
    mov v2.b[1],v5.b[1]
    mov v2.b[0],v5.b[3]
    cmgt v3.8b,v1.8b,v2.8b        // comparaison 6
    mov v4.8b, v1.8b
    mov v5.8b, v2.8b
    bit v4.8b,v2.8b,v3.8b  
    bit v5.8b,v1.8b,v3.8b 

    ldr d6,qValIndex8F                // chargement des données de recomposition
    tbl v0.8b,{v4.16b,v5.16b},v6.8b   // recomposition finale
    mov x0,v0.d[0]                    // retour valeurs triées
100:
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qValIndex8F:           .quad 0x0302120111001013

/******************************************************************/
/*     conversion hexa avec instructions SIMD                                              */ 
/******************************************************************/
/* x0 contient la valeur à convertir   */
/* x1 l'adresse de la zone receptrice */
/* attention les registres v ne sont pas sauvegardés */
conversionHexa:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    rev x0,x0                  // inversion des octets
    ldr x3,mask2               // extrait les demioctets pairs
    and x2,x0,x3
    mov v2.D[0],x2            // copie dans registre vecteurs
    ldr x3,mask1             // extrait les demioctets impairs
    and x2,x0,x3
    lsr x2,x2,4              // decalage demi octet droite
    mov v3.D[0],x2           // copie dans registre vecteurs
    zip2 v4.8b,v3.8b,v2.8b   // entrelace les parties hautes de v2 et v3
    zip1 v1.8b,v3.8b,v2.8b   // entrelace les parties basses de v2 et v3
    mov  v1.d[1],v4.d[0]     // recopie dans partie haute registre 128 bits
    movi v2.16b,0x9           // charge la valeur 9 dans les 16 octets
    cmgt v3.16b,v1.16b,v2.16b // compare si chaque octet est superieur à 9
    movi v2.16b,0x30          // valeur 0 pour chiffre 0 à 9
    movi v4.16b,0x37          // pour chiffre A à F 
    bit  v2.16b,v4.16b,v3.16b // remplace la valeur 30 par 37 pour tous les octets >
    add v3.16b,v1.16b,v2.16b  // addition pour conversion ascii
    str q3,[x1]               // stockage registre 128 en mémoire

100:
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
mask1:                   .quad 0xF0F0F0F0F0F0F0F0
mask2:                   .quad 0x0F0F0F0F0F0F0F0F

