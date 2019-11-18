/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* instructions SIMD asm 64 bits  */

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
    affichelib Exemple
    movi v2.8b,10             // met 10 dans chaque octet du registre
    mov v1.b[1],v2.b[2]       // met l' octet N° 2 dans l'octet N°1 
    mov x0,v1.D[0]            // met le registre v1 partie basse  dans r0
    mov x1,v2.D[0]
    affregtit registreX0X1 0
    mov w2,v2.s[1]
    affregtit registreX2 0
    movi v3.8b,5              // on met 5 dans tous les octets
    add v0.8b,v2.8b,v3.8b     // addition de tous les octets
    mov x4,v0.D[0]
    affregtit  registreX4 0
    affichelib conversionHexa
    mov x4,0xDEF0
    movk x4,0x9ABC, lsl 16
    movk x4,0x5678, lsl 32
    movk x4,0x1234,lsl 48     // registre départ
    ldr x5,mask2              // extrait les demioctets pairs
    and x3,x4,x5
    mov v3.D[0],x3            // copie dans registre vecteurs
    mov v6.b[0],v3.B[0]       // et eclatement sur registres 128 bits
    mov v6.b[2],v3.B[1]
    mov v6.b[4],v3.B[2]
    mov v6.b[6],v3.B[3]
    mov v6.b[8],v3.B[4]
    mov v6.b[10],v3.B[5]
    mov v6.b[12],v3.B[6]
    mov v6.b[14],v3.B[7]
    ldr x5,mask1             // extrait les demioctets impairs
    and x3,x4,x5
    lsr x3,x3,4              // decalage demi octet droite
    mov v3.D[0],x3           // copie dans registre vecteurs
    mov v6.b[1],v3.B[0]      // et eclatement dans registre 128 bits
    mov v6.b[3],v3.B[1]
    mov v6.b[5],v3.B[2]
    mov v6.b[7],v3.B[3]
    mov v6.b[9],v3.B[4]
    mov v6.b[11],v3.B[5]
    mov v6.b[13],v3.B[6]
    mov v6.b[15],v3.B[7]
    movi v8.16b,0x9           // charge la valeur 9 dans les 16 octets
    cmgt v5.16b,v6.16b,v8.16b // compare si chaque octet est superieur à 9
    movi v8.16b,0x30          // valeur 0 pour chiffre 0 à 9
    movi v9.16b,0x37          // pour chiffre A à F 
    bit  v8.16b,v9.16b,v5.16b // remplace la valeur 30 par 37 pour tous les octets >
    add v7.16b,v6.16b,v8.16b  // addition pour conversion ascii
    mov x7,v7.D[1]            // recupération partie haute des 16 octets
    rev x7,x7                 // inversion des octets
    mov x8,v7.D[0]            // récuperation partie basse
    rev x8,x8                 // inversion des octets
    ldr x0,qAdrsBuffer
    stp x7,x8,[x0]            // stockage des 2 registres en mémoire

    mov x3,v3.D[0]            // pour verification intermédiaire
    mov x5,v5.D[0]
    mov x6,v6.D[0]
    mov x7,v7.D[0]
    mov x8,v8.D[0]
    affregtit registre>x2 3
    ldr x0,qAdrsBuffer
    affmemtit affresult x0 2

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
mask1:                   .quad 0xF0F0F0F0F0F0F0F0
mask2:                   .quad 0x0F0F0F0F0F0F0F0F
//valZero:                 .quad 0x3030303030303030
qAdrsBuffer:             .quad sBuffer


