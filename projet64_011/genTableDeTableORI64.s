/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* Génération de la table des puissance de 10 pour grisu asm 64 bits  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"

.equ BIAS,     1075
.equ MAXIP, 342
.equ MAXI, 309
.equ MINI, 289
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*******************************************/
/* Structures                               */
/********************************************/
/* structure diy_fp   */
    .struct  0
diy_fp_f:                         // significant
    .struct  diy_fp_f + 8
diy_fp_e:                         // exposant
    .struct  diy_fp_e + 8
diy_fp_fin: 
/*********************************/
/* Initialized data              */
/*********************************/
.data
szMessDebutPgm:          .asciz "Début programme.\n"
.equ LGMESSDEBUT,        . - szMessDebutPgm
szMessFinPgm:            .asciz "Fin ok du programme.\n"
.equ LGMESSFIN,          . - szMessFinPgm
szMessErrSous:            .asciz "Erreur lors de la soustraction.\n"
.equ LGMESSERRSOUS,          . - szMessErrSous
szRetourLigne:            .asciz "\n"
.equ LGRETLIGNE,         . - szRetourLigne
szMessValeur:             .asciz "  .quad  0x@, @  // poste @ \n"

//dfTest1:                 .double 0f314116E-5
//dfTest1:                 .double 0f10E19       //  10E3 OK 10E11
dfTest1:                 .double 0f10E-289
dfTest2:                 .double 0f10E20

.include "TableOriginePuis10.inc"
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
sZoneConv:          .skip 24
qZonesTest:         .skip 40
diyValeur1:         .skip diy_fp_fin
diyValeurExt:       .skip diy_fp_fin
diyResult:         .skip diy_fp_fin
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    affichelib GenerationTable
    mov x6,0
    ldr x5,qAdrTableOrigine
1:

    ldr x0,[x5,x6,lsl 3]
    bl affichagePoste
    add x6,x6,1
    cmp x6,NBPOSTETABLEORI10
    ble 1b
   
    
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
//qAdrqZonesTest:          .quad qZonesTest
qAdrdiyValeur1:          .quad diyValeur1
qAdrdfTest1:             .quad dfTest1
qAdrdfTest2:             .quad dfTest2
qAdrszMessValeur:        .quad szMessValeur
qAdrsZoneConv:           .quad sZoneConv
qAdrTableOrigine:        .quad TableOriginePuis10
/******************************************************************/
/*     conversion double -> diy_fp                                               */ 
/******************************************************************/
/* x0 contient le nombre   */
/* x1 contient l'adresse de la structure   */
conversionDiy_fp:
    stp x2,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    and x2,x0,0xFFFFFFFFFFFFF  // significant
    and x3,x0,0x7FF<<52        // exposant
    lsr x3,x3,52   
    cmp x3,0
    bne 1f
    mov x3,1
    sub x3,x3,BIAS
    b 2f
1:
    sub x3,x3,BIAS
    orr x2,x2,1<<52
2:
    str x2,[x1,diy_fp_f]        // stocke significant
    str x3,[x1,diy_fp_e]        // stocke exposant
100:
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30 


/******************************************************************/
/*     normalisation diy_fp                                               */ 
/******************************************************************/
/* x0 contient l'adresse de la structure    */
normalizeDiy_fp:
    stp x2,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    ldr x1,[x0,diy_fp_f]
    ldr x2,[x0,diy_fp_e]
1:
    tst x1,1<<53
    beq 2f
    lsl x1,x1,1
    sub x2,x2,1
    b 1b
2:
    lsl x1,x1,11
    sub x2,x2,11
    str x1,[x0,diy_fp_f]        // stocke significant
    str x2,[x0,diy_fp_e]        // stocke exposant
100:
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30 

/******************************************************************/
/*     calcul et affichage poste                                                */ 
/******************************************************************/
/* x0 contient la valeur float à calculer */
affichagePoste:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    ldr x1,qAdrdiyValeur1
    bl conversionDiy_fp
    ldr x0,qAdrdiyValeur1
    bl normalizeDiy_fp 
    
    ldr x2,qAdrdiyValeur1
    ldr x0,[x2,diy_fp_f]
    ldr x1,qAdrsZoneConv
    bl prepRegistre16
    ldr x0,qAdrszMessValeur
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar            // insert result at // character
    mov x3,x0

    //
    ldr x0,[x2,diy_fp_e]
    ldr x1,qAdrsZoneConv
    bl conversion10S
    mov x0,x3
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar            // insert result at // character
    mov x3,x0

    //
    mov x0,x6
    ldr x1,qAdrsZoneConv
    bl conversion10
    mov x0,x3
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar            // insert result at // character
    bl affichageMess                 // display message
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

