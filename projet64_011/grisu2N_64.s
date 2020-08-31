/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* affichage de float algorithme Grisu2 asm 64 bits  */
/* voir le document pdf de Florian Loitsch  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"

.equ BIAS,     1075
.equ NBPOSTESTABLE, 87
.equ EXP10MINI,  -348
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
szRetourLigne:            .asciz "\n"
.equ LGRETLIGNE,         . - szRetourLigne

dfPI:                     .double 0f314159265358979323E-17
dfTest1:                 .double 0f-5
dfTest2:                 .double 0f-1E23
dfTest3:                 .double 0f-12.34E305
dfTest4:                 .double 0f-0.3

/* contient les tables des puissances de 10 */ 
.include "./tablePuis10Recomp.inc"

/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
sBuffer:      .skip 80
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
    ldr x0,qAdrdfTest1
    ldr d0,[x0]                 // charge un float
    ldr x1,qAdrsBuffer
    mov x2,2                    // pour verification save registres
    mov x3,3
    mov x4,4
    mov x5,5
    mov x6,6
    mov x7,7
    mov x8,8
    mov x9,9
    mov x10,0x10
    mov x11,0x11
    mov x12,0x12
    mov x13,0x13
    mov x14,0x14
    mov x15,0x15
    mov x16,0x16
    mov x17,0x17
    mov x18,0x18
    mov x19,0x19
    mov x20,0x20
    mov x21,0x21
    mov x22,0x22
    mov x23,0x23
    mov x24,0x24
    mov x25,0x25
    mov x26,0x26
    mov x27,0x27
    mov x28,0x28
    bl convertirFloatDP
    affregtit controleReg 0
    affregtit controleReg 6
    affregtit controleReg 12
    affregtit controleReg 18
    affregtit controleReg 24
    ldr x0,qAdrsBuffer
    bl affichageMess
    ldr x0,qAdrszRetourLigne
    bl affichageMess
    //b 100f
    ldr x0,qAdrdfTest2
    ldr d0,[x0]
    //mov x0,1                  // pour test nan
    //mov x0,0                  // pour test zero
    //fmov d0,x0                // pour test zero ou nan
    ldr x1,qAdrsBuffer
    bl convertirFloatDP
    affregtit retourFloat2  0
    ldr x0,qAdrsBuffer
    bl affichageMess
    ldr x0,qAdrszRetourLigne
    bl affichageMess
    
    ldr x0,qAdrdfTest3
    ldr d0,[x0]
    ldr x1,qAdrsBuffer
    bl convertirFloatDP
    affregtit retourFloat3  0
    ldr x0,qAdrsBuffer
    bl affichageMess
    ldr x0,qAdrszRetourLigne
    bl affichageMess
    
    // test pi
    ldr x0,qAdrdfPI
    ldr d0,[x0]
    ldr x1,qAdrsBuffer
    bl convertirFloatDP
    affregtit retourPi  0
    ldr x0,qAdrsBuffer
    bl affichageMess
    ldr x0,qAdrszRetourLigne
    bl affichageMess
    
    ldr x0,qAdrdfTest4
    ldr d0,[x0]
    ldr x1,qAdrsBuffer
    bl convertirFloatDP
    affregtit retourFloat4  0
    ldr x0,qAdrsBuffer
    bl affichageMess
    ldr x0,qAdrszRetourLigne
    bl affichageMess
    
    mov x0,0
    eor x0,x0,0x7FF<<52        // infini plus
    fmov d0,x0
    ldr x1,qAdrsBuffer
    bl convertirFloatDP
    affregtit retourinfPlus  0
    ldr x0,qAdrsBuffer
    bl affichageMess
    ldr x0,qAdrszRetourLigne
    bl affichageMess
    
    eor x0,x0,0xFFF<<52       // infini moins
    fmov d0,x0
    ldr x1,qAdrsBuffer
    bl convertirFloatDP
    affregtit retourinfMoins 0
    ldr x0,qAdrsBuffer
    bl affichageMess
    ldr x0,qAdrszRetourLigne
    bl affichageMess
100:                            // fin standard du programme
    ldr x0,qAdrszMessFinPgm     // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc 0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdrsBuffer:             .quad sBuffer
qAdrdfTest1:             .quad dfTest1
qAdrdfTest2:             .quad dfTest2
qAdrdfTest3:             .quad dfTest3
qAdrdfTest4:             .quad dfTest4
qAdrdfPI:                .quad dfPI
qAdrtablePuis10:         .quad tablePuis10RCG2
/******************************************************************/
/*     conversion float double précision 64 bits grisu 2          */ 
/*     voir le document pdf de Florian Loitsch                    */ 
/******************************************************************/
/* d0 contient la valeur à convertir  */
/* x1 contient l'adresse du buffer longueur = 30 caractères */
/* x0 retourne le nombre de caractères dans le buffer  */
convertirFloatDP:               // INFO: AfficherFloatDP
    stp fp,lr,[sp,-16]!        // save  registres
    stp d0,d1,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x5,x6,[sp,-16]!        // save  registres
    stp x7,x8,[sp,-16]!        // save  registres
    stp x9,x10,[sp,-16]!        // save  registres
    stp x11,x12,[sp,-16]!        // save  registres
    stp x13,x14,[sp,-16]!        // save  registres
    stp x15,x16,[sp,-16]!        // save  registres
    stp x17,x18,[sp,-16]!        // save  registres
    stp x19,x20,[sp,-16]!        // save  registres
    stp x21,x22,[sp,-16]!        // save  registres
    stp x23,x24,[sp,-16]!        // save  registres
    stp x25,x26,[sp,-16]!        // save  registres
    stp x27,x28,[sp,-16]!        // save  registres
    sub sp,sp,32               // reserve 32 octets pour la zone chiffres
    mov fp,sp                  // adresse zone réservée dans frame pointer
    str xzr,[fp]               // raz zone réservée
    str xzr,[fp,8]
    str xzr,[fp,16]
    mov x21,x1                 // save adresse buffer
    mov x22,0                  // signe
    fmov x0,d0                 // copie nombre dans x0 pour calcul
    tst x0,1<<63               // nombre négatif ?
    beq 1f
    mov x2,'-'                 // oui préparation du signe
    strb w2,[x21]
    add x21,x21,1
    mov x22,1
1:
    cmp x0,0                   // nombre = zéro ?
    bne 2f
    ldr x2,iaffZero
    str w2,[x21]
    add x0,x22,1
    b 100f
2:
    tst x0,0x7FF<<52           // exposant à zéro ?
    bne 3f
    ldr x2,qAffNan             // ce n est pas un float 
    str x2,[x21]
    mov x0,3
    b 100f
3:                             // infini
    and x2,x0,0x7FF<<52
    lsr x2,x2,52
    cmp x2,0x7FF
    bne 4f
    ldr x2,qAffInf
    str x2,[x21]
    add x0,x22,3
    b 100f
4:                             // c est un float
    // utilisation des registres 
    // x27 x28  FP significant et exposant
    // x25 x26 Mini
    // x23 x24 Maxi
    // x22 signe
    // x21 adresse buffer
    // x19 K
    // x13 nombre de chiffres
    
    // conversion nombre entrée 
    and x27,x0,0xFFFFFFFFFFFFF  // significant
    and x28,x0,0x7FF<<52        // exposant
    lsr x28,x28,52
    cbnz x28,5f
    mov x28,1
    sub x28,x28,BIAS
    b 6f    
5:
    sub x28,x28,BIAS
    orr x27,x27,1<<52
6:
    /************************/
    // calcul limites
    lsl x23,x27,1
    add x23,x23,1               // frac maxi
    sub x24,x28,1               // exposant maxi
7:
    tst x23,1<<54
    beq 8f
    lsl x23,x23,1               // frac maxi
    sub x24,x24,1               // exposant maxi
    b 7b
8:
    mov x7,10
    lsl x23,x23,x7              // frac maxi
    sub x24,x24,x7              // exposant maxi
    ldr x7,qVal53
    cmp x27,x7
    mov x7,2
    mov x8,1
    csel x7,x7,x8,eq
    lsl x8,x27,x7               // mini frac
    sub x8,x8,1
    sub x3,x28,x7               // mini exp
    sub x7,x3,x24
    lsl x25,x8,x7               // frac mini
    mov x26,x24                 // expo mini = expo maxi 
    /************************/
    // normalisation nombre
9:                              // debut boucle 
    tst x27,1<<53
    beq 10f
    lsl x27,x27,1
    sub x28,x28,1
    b 9b
10:
    lsl x27,x27,11              // maj  significant fp 
    sub x28,x28,11              // maj exposant fp
    
    /***************************/
    /* calcul du coefficient k pour accèder à la table */
    add x0,x24,NBPOSTESTABLE    // exposant maxi 
    mov x1,0                    // alpha
                                // recherche index de départ de la table
    sub x3,x1,x0                // alpha - exposant
    fmov d0,x3
    scvtf d0,d0                 // conversion en float
    ldr d1,D_1                  // charge la constante
    fmul d0,d0,d1               // et la multiplie
    frinta d0,d0                // arrondi inferieur
    fcvtas x0, d0               // et conversion en entier
    
    //affregtit coefficientK 0
    
    sub x4,x0,EXP10MINI         // calcul index
    asr x4,x4,3                 // division par pas de 8
    mov x2,diy_fp_fin
    ldr x3,qAdrtablePuis10
11:
    mul x0,x4,x2
    add x1,x3,x0                // contient l adresse de la puissance de 10
    //affregtit bouclerecherche 0
    ldr x5,[x1,diy_fp_e]       // chargement de l'exposant
    add x5,x5,x24              // + exposant maxi
    add x5,x5,64
    cmp x5,-60                 // recherche de l'exposant dans la fourchette -59 -32
    bge 12f
    add x4,x4,1
    b 11b                      // boucle
12:
    cmp x5,-32
    ble 13f
    sub x4,x4,1
    b 11b                      // boucle
13:
    mul x0,x4,x2               // calcul du déplacement dans la table
    add x1,x3,x0               // contient l adresse de la puissance de 10
    mov x0,x1
    lsl x0,x4,3                // mul index par le pas de  8
    add x19,x0,EXP10MINI       // ajout première puissance pour coefficient
    ldr x2,[x1,diy_fp_f]       // chargement du significant de la puissance de 10
                               // multiplication FP
    umulh x27,x27,x2
    ldr x3,[x1,diy_fp_e]
    add x28,x28,x3
    add x28,x28,64
                               // multiplication mini
    umulh x25,x25,x2
    add x26,x26,x3
    add x26,x26,64
    add x25,x25,1              // mini + 1
                               // multiplication maxi
    umulh x23,x23,x2
    add x24,x24,x3
    add x24,x24,64
    sub x23,x23,1              // maxi - 1
    /**********************************/
    // extraire les chiffres du résultat des multiplications
    neg x19,x19                // inversion coefficient
    sub x7,x23,x27             // wfrac
    //affregtit frac1 24
    mov x8,1
    neg x10,x24                // - exp maxi
    lsl x8,x8,x10              // one.frac
    neg x9,x24                 // - one expo
    lsr x10,x23,x9             // partie 1
    sub x2,x8,1
    and x12,x23,x2            // partie 2
    //affregtit part 9
    mov x13,0                 // idx
    mov x14,10                //kappa
    sub x3,x23,x25            // delta = frac maxi - frac mini
    //affregtit delta 0
    ldr x15,qAdrTable10       // table puissance de 10
    mov x16,10
14:                          // debut boucle extraction chiffre avant virgule
    add x6,x15,x16,lsl 3
    ldr x17,[x6]             // div
    udiv x18,x10,x17         // extraction chiffre
    //affregtit division 15
    cbnz x18,15f
    cbnz x13,15f
    b 16f
15:
    add x1,x18,'0'           // conversion ascii
    strb w1,[fp,x13]         // et stockage
    add x13,x13,1            // incremente idx
16:
    msub x5,x18,x17,x10      // partie 1 = modulo
    mov x10,x5
    sub x14,x14,1            // decrement kappa
    lsl x5,x10,x9
    add x5,x5,x12            // tmp
    //affregtit tmp 0
    cmp x5,x3                // comparaison avec delta
    bls 21f
    add x16,x16,1
    cbnz x14,14b             // kappa > 0
    
    mov x16,18
18:                          // boucle 2 extraction chiffres partie 2
    add x6,x15,x16,lsl 3
    mov x5,10
    mul x12,x12,x5           // partie 2 * 10
    mul x3,x3,x5             // delta * 10
    sub x14,x14,1            // decrement kappa
    lsr x18,x12,x9           // chiffre
    cbnz x18,19f
    cbnz x13,19f
    b 20f
19:
    add x18,x18,'0'          // conversion ascii
    strb w18,[fp,x13]        // et stockage
    add x13,x13,1            // incremente idx
20:
    sub x7,x8,1              // one.frac - 1
    and x12,x12,x7           // partie 2
    cmp x12,x3
    bls 21f
    sub x16,x16,1
    b 18b
21:
    add x19,x19,x14          // k = k + kappa
    // ici x19 = K x13 = idx x21 = adresse buffer et x22 le signe
    // affregtit finextract  10
    //affregtit finextract  19
    //mov x0,fp
    //affmemtit finextract x0 2 

    mov x0,fp              // zone chiffres extraits
    mov x1,x13             // nb chiffres
    mov x2,x21             // adresse buffer
    mov x3,x19             // Exposant
    mov x4,x22             // positif/negatif
    bl formaterChiffres

100:
    add sp,sp,32           // alignement pile
    ldp x27,x28,[sp],16     // restaur des  2 registres
    ldp x25,x26,[sp],16     // restaur des  2 registres
    ldp x23,x24,[sp],16     // restaur des  2 registres
    ldp x21,x22,[sp],16     // restaur des  2 registres
    ldp x19,x20,[sp],16     // restaur des  2 registres
    ldp x17,x18,[sp],16     // restaur des  2 registres
    ldp x15,x16,[sp],16     // restaur des  2 registres
    ldp x13,x14,[sp],16     // restaur des  2 registres
    ldp x11,x12,[sp],16     // restaur des  2 registres
    ldp x9,x10,[sp],16     // restaur des  2 registres
    ldp x7,x8,[sp],16      // restaur des  2 registres
    ldp x5,x6,[sp],16      // restaur des  2 registres
    ldp x3,x4,[sp],16      // restaur des  2 registres
    ldp x1,x2,[sp],16      // restaur des  2 registres
    ldp d0,d1,[sp],16      // restaur des  2 registres
    ldp fp,lr,[sp],16      // restaur des  2 registres
    ret                    // retour adresse lr x30
iaffZero:             .int 0x00030
qAffNan:              .quad 0x006E614E
qAffInf:              .quad 0x00666E49         // infini
D_1:                  .double 0.30102999566398114
qVal53:               .quad 1<<53
qAdrTable10:          .quad Table10

/******************************************************************/
/*     formatage des chiffres du resultat                              */ 
/******************************************************************/
/* x0 contient l'adresse zone chiffre   */
/* x1 contient le nombre de chiffres  */
/* x2 contient l'adresse du buffer de destination  */
/* x3 contient l'exposant  */
/* x4 contient 0 si positif 1 si negatif */
/* x0 retourne le nombre de caractères */
formaterChiffres:              // INFO: formaterChiffres
    stp fp,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x5,x6,[sp,-16]!        // save  registres
    stp x7,x8,[sp,-16]!        // save  registres
    stp x9,x10,[sp,-16]!       // save  registres
    //affregtit formaterChiffres 0
    add x9,x3,x1
    subs x9,x9,1      // exposant = exposant + nb chiffres - 1
    bge 1f
    neg x9,x9         // valeur absolue
1:
    cmp x3,0
    blt 4f
    add x6,x1,7
    cmp x9,x6
    bge 4f
                      // affichage entier
    mov x5,0
2:                    //boucle de copie
    ldrb w6,[x0,x5]
    strb w6,[x2]
    add x5,x5,1
    add x2,x2,1
    cmp x5,x1
    blt 2b
    mov w6,'0'
    mov x5,0
3:
    cmp x5,x3
    bge 31f
    strb w6,[x2]
    add x5,x5,1
    add x2,x2,1
    b 3b
31:
    strb wzr,[x2]
    add x0,x1,x3         // longueur zone
    add x0,x0,x4
    b 100f
4:                          //
    cmp x3,0
    bge 5f
    cmp x3,-7
    ble 5f
    b 6f
5:
    cmp x9,4
    bge 15f
6:                      // affichage decimal
    cmp x3,0
    bge 7f
    neg x3,x3
7:
    sub x4,x1,x3
    cmp x4,0
    bgt 10f
    
    neg x4,x4
    mov w6,'0'
    strb w6,[x2]
    add x2,x2,1
    mov w6,'.'
    strb w6,[x2]
    add x2,x2,1
    mov w6,'0'
    mov x5,0
8:
    cmp x5,x4
    bge 81f
    strb w6,[x2]
    add x5,x5,1
    add x2,x2,1
    b 8b
81:
    mov x5,0
9:
    ldrb w6,[x0,x5]
    strb w6,[x2]
    add x5,x5,1
    add x2,x2,1
    cmp x5,x1
    blt 9b
    strb wzr,[x2]
    add x0,x1,2
    add x0,x0,x4
    add x0,x0,x22
    b 100f
10:
    mov x5,0
11:
    ldrb w6,[x0,x5]
    strb w6,[x2]
    add x5,x5,1
    add x2,x2,1
    cmp x5,x4
    blt 11b
    mov w6,'.'
    strb w6,[x2]
    add x2,x2,1
    mov x5,0
    sub x3,x1,x4
12:
    add x7,x5,x4
    ldrb w6,[x0,x7]
    strb w6,[x2]
    add x5,x5,1
    add x2,x2,1
    cmp x5,x3
    blt 12b
    strb wzr,[x2]
    add x0,x1,1
    add x0,x0,x22
    b 100f
15:                           // Affichage sous la forme FRACeEXP
    mov x11,x2        // save debut adresse buffer
    mov x5,18
    sub x5,x5,x4
    cmp x1,x5
    csel x1,x1,x5,lt
    ldrb w6,[x0]
    strb w6,[x2]
    add x2,x2,1
    cmp x1,1
    ble 17f
    mov w6,'.'
    strb w6,[x2]
    add x2,x2,1
    mov x5,0
    sub x8,x1,1
16:
    add x10,x5,1
    ldrb w6,[x0,x10]
    strb w6,[x2]
    add x2,x2,1
    add x5,x5,1
    cmp x5,x8
    blt 16b
17:                      // affichage exposant
    mov w6,'e'
    strb w6,[x2]
    add x2,x2,1
    add x8,x3,x1
    sub x8,x8,1
    mov w6,'+'
    cmp x8,0
    bge 18f
    mov w6,'-'
18:
    strb w6,[x2]
    add x2,x2,1
    mov x7,0          // cent
    cmp x9,99
    ble 19f
    mov x10,100
    udiv x7,x9,x10
    add x6,x7,'0'
    strb w6,[x2]
    add x2,x2,1
    msub x9,x7,x10,x9
19:
    cmp x9,9
    ble 20f
    mov x10,10
    udiv x5,x9,x10
    add x6,x5,'0'
    strb w6,[x2]
    add x2,x2,1
    msub x9,x5,x10,x9
    b 21f
20:
    cmp x7,0
    beq 21f
    mov w6,'0'
    strb w6,[x2]
    add x2,x2,1
21:
    mov x10,10
    udiv x5,x9,x10
    msub x7,x5,x10,x9
    add x6,x7,'0'
    strb w6,[x2]
    add x2,x2,1
    strb wzr,[x2]
    sub x0,x2,x11       // nombre de chiffres
    sub x0,x0,1
    add x0,x0,x4
    add x0,x0,x22
100:
    ldp x9,x10,[sp],16          // restaur des  2 registres
    ldp x7,x8,[sp],16          // restaur des  2 registres
    ldp x5,x6,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp fp,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
    