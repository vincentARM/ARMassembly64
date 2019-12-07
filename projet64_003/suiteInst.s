/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* affichage paramètre ligne commande   */

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
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    mov x29,sp                   // recup adresse pile
    ldr x2,[x29],8               // recup nombre de paramètres et avance de 8 octets
1:
    ldr x0,[x29],8               // recup adresse de chaque parametre
    bl affichageMess             // et affichage
    ldr x0,qAdrszRetourLigne
    mov x1,LGRETLIGNE
    bl affichageMessSP
    subs x2,x2,1                // decremente le nombre de parametre
    bgt 1b                      // et boucle si plus grand que zero
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    affichelib exempleTRN1
    ldr x0,qVal1
    mov v0.d[0],x0
    ldr x1,qVal2
    mov v1.d[0],x1
    afficheLib TRN1_Octets
    trn1 v2.8B,v1.8B,v0.8B    // met les octets pairs de v0 dans impairs de v1
    mov x2,v2.d[0]
    affregtit resultat_octets 0
    trn1 v2.8B,v0.8B,v1.8B   // met les octets pairs de v1 dans impairs de v0
    mov x2,v2.d[0]
    affregtit resultat_octets1 0
    afficheLib TRN2_Octets
    trn2 v2.8B,v1.8B,v0.8B   // met les octets impairs de v0 dans les pairs de v1
    mov x2,v2.d[0]
    affregtit TRN2_octets 0
    trn2 v2.8B,v0.8B,v1.8B   // et inversement
    mov x2,v2.d[0]
    affregtit TRN2_octets1 0

    afficheLib mots
    trn1 v2.2S,v1.2S,v0.2S   // met les 4 octets de fin de v0 dans les 4 premiers
    mov x2,v2.d[0]           // octets de V1
    affregtit  TRN1_mots 0
    afficheLib TRN2_mots
    trn2 v2.2S,v1.2S,v0.2S
    mov x2,v2.d[0]
    affregtit TRN2_mots 0
    afficheLib TRN1_16bits
    trn1 v2.4h,v0.4h,v1.4h
    mov x2,v2.d[0]
    affregtit TRN1_16bits 0
    afficheLib TRN2_16bits
    trn2 v2.4h,v1.4h,v0.4h
    mov x2,v2.d[0]
    affregtit TRN2_16bits 0
    afficheLib TRN1_doublemot
    trn1 v2.2D,v0.2D,v1.2D
    mov x2,v2.d[0]
    mov x3,v2.d[1]
    affregtit TRN1_doublemot 0
    afficheLib abs
    ldr x0,mask1 
    mov v0.d[0],x0
    abs v1.4h,v0.4h
    mov x1,v1.d[0]
    affregtit testABS1 0
    abs v1.2s,v0.2s
    mov x1,v1.d[0]
    affregtit testABS2 0
    abs v1.8b,v0.8b
    mov x1,v1.d[0]
    affregtit testABS3 0
    afficheLib ADDP          // additionne 2 valeurs successives
    ldr x0,qVal1
    mov v0.d[0],x0
    ldr x1,qVal2
    mov v1.d[0],x1
    addp v2.8b,v1.8b,v0.8B
    mov x2,v2.d[0]
    affregtit testADDP1 0
    afficheLib ADDV
    addv b2,v1.16b           // registre b2 !!!!
    //mov x2,v2.d[0]
    affregtit testAFFV1 0
    afficheLib BSL           // suivant chaque bit du masque
    ldr x2,mask3             // met le bit correspondant de v1 si 1
    mov v2.d[0],x2           // ou le bit correspondant de v0 si 0
    bsl v2.8b,v1.8b,v0.8b      //
    mov x2,v2.d[0]
    affregtit testBSL1 0
    afficheLib CNT            // compte les bits à 1 de chaque octet
    cnt v3.8b,v2.8b
    mov x3,v3.d[0]
    affregtit testCNT1 0
    afficheLib DUP
    dup v2.8b,v1.b[5]         // duplique le 5 ieme octet de v1
    mov x2,v2.d[0]            // dans les 8 octets de v2
    affregtit testDUP1 0
    mov x6,8
    dup v2.8b,w6              // duplique w6 (x6 non autorisé)
    mov x2,v2.d[0]            // dans les 8 octets de v2
    affregtit testDUP2 0
    afficheLib EXT
    ext v2.8b,v1.8b,v0.8b,3   // duplique 3 derniers octets de V0 et 5 premiers octets de v1
    mov x2,v2.d[0]            // dans les 8 octets de v2 
    affregtit testEXT1 0
    afficheLib INS
    ins v2.8b[4],v0.8b[1]     // equivalent au mov
    mov x2,v2.d[0]           
    affregtit testINS 0
    afficheLib SHL          // voir aussi SHR pour la droite 
    shl v2.8b,v0.8b,2       // multiplie tous les octets par 4
    mov x2,v2.d[0]           // 
    affregtit testSHL 0
    afficheLib SLI           // voir aussi SRI pour la droite
    movi v2.8b,0xF
    sli v2.8b,v0.8b,2       // deplace tous les octets de 2 positions a gauche
    mov x2,v2.d[0]          // et complete avec les bits précedents
    affregtit testSLI 0
    afficheLib tri

    mov v1.d[0],xzr
    mov v2.d[0],xzr
    ldr x3,mask2              // extrait les demioctets pairs
    and x1,x0,x3
    mov v1.d[0],x1
    ldr x3,mask1             // extrait les demioctets impairs
    and x2,x0,x3
    lsr x2,x2,4              // decalage demi octet droite
    mov v2.d[0],x2
    trn2 v0.8b,v1.8b,v2.8b
    mov x4,v0.d[0]
    mov x5,v0.d[1]
    affregtit calcul1 0
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
qVal1:                   .quad 0x0102030405060708
qVal2:                   .quad 0x1112131415161718
mask1:                   .quad 0xF0F0F0F0F0F0F0F0
mask2:                   .quad 0x0F0F0F0F0F0F0F0F
mask3:                   .quad 0xFF00FF00FF00FF00


