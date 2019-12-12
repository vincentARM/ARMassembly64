/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* test tri 16 octets avec instruction SIMD asm 64 bits  */
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
.align 4

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


    /*tri 16 octets */
    affichelib tri16octets
    mov x0,0x0201
    movk x0,0x0403,lsl 16
    movk x0,0x0605,lsl 32
    movk x0,0x0807,lsl 48
    mov x1,0x1009
    movk x1,0x1211,lsl 16
    movk x1,0x1413,lsl 32
    movk x1,0x1615,lsl 48
    bl tri16Octets
    mov x2,x1
    ldr x1,qAdrsBuffer
    bl conversionHexa
    mov x0,x2
    add x1,x1,16
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit afftri16octets x0 4

    ldr x0,qVal1
    ldr x1,qVal4
    bl tri16Octets
    mov x2,x1
    ldr x1,qAdrsBuffer
    bl conversionHexa
    mov x0,x2
    add x1,x1,16
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit afftri16octets1 x0 4

    ldr x0,qVal5
    ldr x1,qVal6
    bl tri16Octets
    mov x2,x1
    ldr x1,qAdrsBuffer
    bl conversionHexa
    mov x0,x2
    add x1,x1,16
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit afftri16octets2 x0 4

    ldr x0,qVal7
    ldr x1,qVal8
    bl tri16Octets
    mov x2,x1
    ldr x1,qAdrsBuffer
    bl conversionHexa
    mov x0,x2
    add x1,x1,16
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit afftri16octets3 x0 4



100:                            // fin standard du programme
    ldr x0,qAdrszMessFinPgm     // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0

qAdrszMessDebutPgm:       .quad szMessDebutPgm
qAdrszMessFinPgm:         .quad szMessFinPgm
qAdrszRetourLigne:        .quad szRetourLigne
qAdrsBuffer:              .quad sBuffer
qVal1:                    .quad 0x0102030405060708
qVal2:                    .quad 0x0802070306040501
qVal3:                    .quad 0x4547424449424E51
qVal4:                    .quad 0x0910111213141516
qVal5:                    .quad 0x0103090705121613
qVal6:                    .quad 0x0204080611101514
qVal7:                    .quad 0x1203091605020105
qVal8:                    .quad 0x1304110000000000
/******************************************************************/
/*     tri 16 octets                                              */ 
/******************************************************************/
/* x0 contient 8 octets de la valeur à trier   */
/* x1 contient les autres 8 octets             */
/* x0 et x1 retournent la valeur trie */
/* attention les registres v ne sont pas sauvegardés */
tri16Octets:                             // fonction
    stp x1,lr,[sp,-16]!                  // save  registres
    stp x2,x3,[sp,-16]!                  // save  registres
    mov v0.D[0],x0                       // copie dans registre vecteurs
    mov v1.D[0],x1                       // copie dans registre vecteurs
    cmgt v3.8b,v0.8b,v1.8b               // comparaison des 2 vecteurs 1
    mov v4.8b, v0.8b
    mov v5.8b, v1.8b
    bit v4.8b,v1.8b,v3.8b                 // inversion valeur en fonction du test
    bit v5.8b,v0.8b,v3.8b  
                                         // ici 8 listes triées de 2 valeurs
    ldr d6,qValIndexP2V0                 // chargement des données de recomposition
    tbl v0.8b,{v4.16b,v5.16b},v6.8b      // recomposition v0
    ldr d6,qValIndexP2V1                 // chargement des données de recomposition
    tbl v1.8b,{v4.16b,v5.16b},v6.8b      // recomposition V1

    cmgt v3.8b,v0.8b,v1.8b          //cmp 2
    mov v4.8b, v0.8b
    mov v5.8b, v1.8b
    bit v4.8b,v1.8b,v3.8b  
    bit v5.8b,v0.8b,v3.8b 

    mov v0.8b,v4.8b
    ldr d6,qValIndexP3V1                 // chargement des données de recomposition
    tbl v1.8b,{v4.16b,v5.16b},v6.8b      // recomposition V1

    cmgt v3.8b,v0.8b,v1.8b               // cmp 3
    mov v4.8b, v0.8b
    mov v5.8b, v1.8b
    bit v4.8b,v1.8b,v3.8b  
    bit v5.8b,v0.8b,v3.8b 
                                         // ici 4 listes triées de 4 valeurs
    ldr d6,qValIndexP4V0                 // chargement des données de recomposition
    tbl v0.8b,{v4.16b,v5.16b},v6.8b      // recomposition v0
    ldr d6,qValIndexP4V1                 // chargement des données de recomposition
    tbl v1.8b,{v4.16b,v5.16b},v6.8b      // recomposition V1

    cmgt v3.8b,v0.8b,v1.8b               // cmp 4
    mov v4.8b, v0.8b
    mov v5.8b, v1.8b
    bit v4.8b,v1.8b,v3.8b
    bit v5.8b,v0.8b,v3.8b

    mov v0.8b,v4.8b
    ldr d6,qValIndexP5V1                 // chargement des données de recomposition
    tbl v1.8b,{v4.16b,v5.16b},v6.8b      // recomposition V1

    cmgt v3.8b,v0.8b,v1.8b               // cmp 5
    mov v4.8b, v0.8b
    mov v5.8b, v1.8b
    bit v4.8b,v1.8b,v3.8b  
    bit v5.8b,v0.8b,v3.8b 

    ldr d6,qValIndexP6V0                 // chargement des données de recomposition
    tbl v0.8b,{v4.16b,v5.16b},v6.8b      // recomposition v0
    ldr d6,qValIndexP6V1                 // chargement des données de recomposition
    tbl v1.8b,{v4.16b,v5.16b},v6.8b      // recomposition V1

    cmgt v3.8b,v0.8b,v1.8b               // cmp 6   
    mov v4.8b, v0.8b
    mov v5.8b, v1.8b
    bit v4.8b,v1.8b,v3.8b  
    bit v5.8b,v0.8b,v3.8b  
                                         // 2 listes trié de 8 valeurs
    ldr d6,qValIndexP7V0                 // chargement des données de recomposition
    tbl v0.8b,{v4.16b,v5.16b},v6.8b      // recomposition v0
    ldr d6,qValIndexP7V1                 // chargement des données de recomposition
    tbl v1.8b,{v4.16b,v5.16b},v6.8b      // recomposition V1
                                        // remises dans le bon ordre 

    cmgt v3.8b,v0.8b,v1.8b        // cmp 7
    mov v4.8b, v0.8b
    mov v5.8b, v1.8b
    bit v4.8b,v1.8b,v3.8b  
    bit v5.8b,v0.8b,v3.8b 

    mov v0.8b,v4.8b
    ldr d6,qValIndexP8V1                // chargement des données de recomposition
    tbl v1.8b,{v4.16b,v5.16b},v6.8b      // recomposition V1

    cmgt v3.8b,v0.8b,v1.8b        // cmp 8
    mov v4.8b, v0.8b
    mov v5.8b, v1.8b
    bit v4.8b,v1.8b,v3.8b  
    bit v5.8b,v0.8b,v3.8b 

    ldr d6,qValIndexP9V0                // chargement des données de recomposition
    tbl v0.8b,{v4.16b,v5.16b},v6.8b      // recomposition v0
    ldr d6,qValIndexP9V1                // chargement des données de recomposition
    tbl v1.8b,{v4.16b,v5.16b},v6.8b      // recomposition V1

    cmgt v3.8b,v0.8b,v1.8b        // cmp 9
    mov v4.8b, v0.8b
    mov v5.8b, v1.8b
    bit v4.8b,v1.8b,v3.8b  
    bit v5.8b,v0.8b,v3.8b 

    ldr d6,qValIndexP10V0                // chargement des données de recomposition
    tbl v0.8b,{v4.16b,v5.16b},v6.8b      // recomposition v0
    ldr d6,qValIndexP10V1                // chargement des données de recomposition
    tbl v1.8b,{v4.16b,v5.16b},v6.8b      // recomposition V1

    cmgt v3.8b,v0.8b,v1.8b        // cmp 10
    mov v4.8b, v0.8b
    mov v5.8b, v1.8b
    bit v4.8b,v1.8b,v3.8b  
    bit v5.8b,v0.8b,v3.8b 

    ldr d6,qValIndexFinV0                // chargement des données de recomposition
    tbl v0.8b,{v4.16b,v5.16b},v6.8b      // recomposition finale V0
    ldr d6,qValIndexFinV1                // chargement des données de recomposition
    tbl v1.8b,{v4.16b,v5.16b},v6.8b      // recomposition finale V1

    mov x0,v0.d[0]
    mov x1,v1.d[0]
100:
    ldp x2,x3,[sp],16                    // restaur des  2 registres
    ldp x4,lr,[sp],16                    // restaur des  2 registres
    ret                                  // retour adresse lr x30
qValIndexP2V0:             .quad 0x0717051503130111
qValIndexP2V1:             .quad 0x0616041402120010

qValIndexP3V1:             .quad 0x1617141512131011

qValIndexP4V0:             .quad 0x0706161703021213
qValIndexP4V1:             .quad 0x0504141501001011

qValIndexP5V1:             .quad 0x1514171611101312

qValIndexP6V0:             .quad 0x0706041403020010
qValIndexP6V1:             .quad 0x1605151712011113

qValIndexP7V0:             .quad 0x0706160515041417
qValIndexP7V1:             .quad 0x0302120111001013
qValIndexP8V1:             .quad 0x1312111017161514
qValIndexP9V0:             .quad 0x0706050401001110
qValIndexP9V1:             .quad 0x1514030213121716
qValIndexP10V0:            .quad 0x0706041402120010
qValIndexP10V1:            .quad 0x1605150313011117
qValIndexFinV0:            .quad 0x0706160515041403
qValIndexFinV1:            .quad 0x1302120111001017
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

