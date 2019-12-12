/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* test tri 4 octets avec instruction SIMD asm 64 bits  */
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
//qwDebut:    .skip 16
//qwFin:      .skip 16
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
    mov x0,0x0201
    movk x0,0x0403,lsl 16
    affichelib tri4octets
    bl tri4Octets
    ldr x1,qAdrsBuffer
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit affresult x0 2
    mov x0,0x0301
    movk x0,0x0204,lsl 16
    bl tri4Octets
   ldr x1,qAdrsBuffer
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit affresult1 x0 2
    mov x0,0x0402
    movk x0,0x0301,lsl 16
    bl tri4Octets
   ldr x1,qAdrsBuffer
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit affresult1 x0 2
    mov x0,0x0304
    movk x0,0x0102,lsl 16
    bl tri4Octets
   ldr x1,qAdrsBuffer
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit affresult1 x0 2
    mov x0,0x0401
    movk x0,0x0203,lsl 16
    bl tri4Octets
   ldr x1,qAdrsBuffer
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit affresult1 x0 2



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
qVal4:                    .quad 0x0910111213141516
qVal5:                    .quad 0x0103090705121613
qVal6:                    .quad 0x0204080611101514

/******************************************************************/
/*     tri 4 octets     OK                                        */ 
/******************************************************************/
/* x0 contient la valeur à trier   */
/* x0 retourne la valeur trie */
/* attention les registres v ne sont pas sauvegardés */
tri4Octets:                    // fonction
    stp x1,lr,[sp,-16]!        // save  registres
    mov v0.D[0],x0            // copie dans registre vecteurs
    movi v1.2s,0
    movi v2.2s,0
    mov v1.h[0],v0.h[1]       // découpe 1
    mov v2.h[0],v0.h[0]
    cmgt v3.8b,v1.8b,v2.8b    // comparaison 1
    mov v4.8b, v1.8b
    mov v5.8b, v2.8b
    bit v4.8b,v2.8b,v3.8b     // echange en fonction du résultat
    bit v5.8b,v1.8b,v3.8b  
    zip1 v0.8b,v5.8b,v4.8b
    mov v1.h[0],v0.h[1]       // découpe 2
    mov v2.h[0],v0.h[0]
    cmgt v3.8b,v1.8b,v2.8b   // comparaison 2 
    mov v4.8b, v1.8b
    mov v5.8b, v2.8b
    bit v4.8b,v2.8b,v3.8b  
    bit v5.8b,v1.8b,v3.8b  
    mov v1.8b,v4.8b
    mov v2.b[0],v5.b[1]       // découpe 3
    mov v2.b[1],v5.b[0]
    cmgt v3.8b,v1.8b,v2.8b   // comparaison 3
    mov v4.8b, v1.8b
    mov v5.8b, v2.8b
    bit v4.8b,v2.8b,v3.8b  
    bit v5.8b,v1.8b,v3.8b  
    mov v0.b[0],v5.b[1]       // recomposition finale
    mov v0.b[1],v5.b[0]
    mov v0.b[2],v4.b[0]
    mov v0.b[3],v4.b[1]
    mov x0,v0.d[0]
100:
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30


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

