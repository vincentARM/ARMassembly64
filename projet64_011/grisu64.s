/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* affichage de float algorithme Grisu asm 64 bits  */
/* voir le document pdf de Florian Loitsch  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"

.equ BIAS,     1075

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

dfPI:                      .double 0f314159265358979323E-17
//dfTest1:                 .double 0f4567E300
dfTest1:                   .double 0f12345E-10
//dfTest1:                   .double 0f-5.0
.include "./tablePuis10.Inc"
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
    ldr x0,[x0]
    //mov x0,1                  // pour test nan
    ldr x1,qAdrsBuffer
    bl AfficherFloatDP
    ldr x0,qAdrsBuffer
    bl affichageMess
    ldr x0,qAdrdfPI
    ldr x0,[x0]
    ldr x1,qAdrsBuffer
    bl AfficherFloatDP
    ldr x0,qAdrsBuffer
    bl affichageMess
    mov x0,0
    eor x0,x0,0x7FF<<52        // infini plus
    //bl affichageReg2
    ldr x1,qAdrsBuffer
    bl AfficherFloatDP
    ldr x0,qAdrsBuffer
    bl affichageMess
    eor x0,x0,0xFFF<<52       // infini moins
    //bl affichageReg2
    ldr x1,qAdrsBuffer
    bl AfficherFloatDP
    ldr x0,qAdrsBuffer
    bl affichageMess
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
qAdrsBuffer:             .quad sBuffer
qAdrdfTest1:             .quad dfTest1
qAdrdfPI:                .quad dfPI
qAdrtablePuis10:         .quad tablePuis10
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
/*     calcul du coefficient k                                    */ 
/******************************************************************/
/* x0 contient l'exposant    */
/* x1 contient le parametre alpha */
/* x2 contient le parametre gamma */
/* x0 retourne k */
k_comp:
    stp x2,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp d0,d1,[sp,-16]!        // save  registres
    sub x3,x1,x0               // alpha - exposant
    add x3,x3,63               // + 63 
    fmov d0,x3
    scvtf d0,d0                // conversion en float
    ldr d1,D_1                 // charge la constante
    fmul d0,d0,d1              // et la multiplie
    frinta d0,d0               // arrondi inferieur
    fcvtas x0, d0              // et conversion en entier
100:
    ldp d0,d1,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30 
D_1:               .double 0.30102999566398114
/******************************************************************/
/*     scission resultat                                    */ 
/******************************************************************/
/* x0 contient la structure du résultat    */
/* x1 contient l'adresse de la zone resultat */
cut:
    stp x2,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x5,x6,[sp,-16]!        // save  registres
    stp x7,x8,[sp,-16]!        // save  registres
    ldr x2,[x0,diy_fp_f]
    ldr x3,[x0,diy_fp_e]
    ldr x4,qDix7
    lsr x5,x4,x3
    udiv x6,x2,x5
    msub x7,x6,x5,x2
    lsl x7,x7,x3
    str w7,[x1,8]
    
    udiv x7,x6,x4
    str w7,[x1]
    msub x5,x7,x4,x6
    str w5,[x1,4]
100:
    ldp x7,x8,[sp],16          // restaur des  2 registres
    ldp x5,x6,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30 
qDix7:               .quad 10000000
/******************************************************************/
/*     normalisation diy_fp                                               */ 
/******************************************************************/
/* x0 contient l'adresse de la structure    */
normalizeDiy_fp:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
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
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30 
/******************************************************************/
/*     soustraction       non testée                              */ 
/******************************************************************/
/* x0 contient l'adresse de la structure du  premier nombre   */
/* x1 contient l'adresse de la structure du  deuxieme nombre  */
/* x2 contient l'adresse de la structure résultat   */
/* le premier nombre doit être superieur au second */
/* les exposants doivent être egaux */
minus:
    stp x2,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    ldr x3,[x0,diy_fp_e]
    ldr x4,[x1,diy_fp_e]
    cmp x3,x4
    bne 99f
    str x4,[x2,diy_fp_e]
    ldr x3,[x0,diy_fp_f]
    ldr x4,[x1,diy_fp_f]
    cmp x3,x4
    blt 99f
    sub x3,x3,x4
    str x3,[x2,diy_fp_f]
    mov x0,x2                    // retourne adresse du résultat
    b 100f
99:
    ldr x0,qAdrszMessErrSous     // message erreur
    mov x1,LGMESSERRSOUS
    bl affichageMessSP
    mov x0,-1
100:
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszMessErrSous:    .quad szMessErrSous
/******************************************************************/
/*     multiplication                                               */ 
/******************************************************************/
/* x0 contient l'adresse de la structure du  premier nombre   */
/* x1 contient l'adresse de la structure du  deuxieme nombre  */
/* x2 contient l'adresse de la structure résultat   */
multiply:
    stp x3,lr,[sp,-16]!        // save  registres
    stp x4,x5,[sp,-16]!        // save  registres
    stp x6,x7,[sp,-16]!        // save  registres
    stp x8,x9,[sp,-16]!        // save  registres
    stp x10,x11,[sp,-16]!      // save  registres
    ldr x3,qM32
    ldr x4,[x0,diy_fp_f]       // x
    
    lsr x5,x4,32               // a
    and x6,x4,x3               // b
    ldr x7,[x1,diy_fp_f]
    lsr x8,x7,32               // c
    and x9,x7,x3               // d
    mul x10,x5,x8              // ac
    mul x11,x6,x8              // bc
    mul x5,x5,x9               // ad
    mul x7,x6,x9               // bd
    lsr x7,x7,32               // tmp
    and x4,x5,x3
    add x7,x7,x4
    and x4,x11,x3
    add x7,x7,x4               // tmp
    mov x3,1<<31
    add x7,x7,x3
    lsr x5,x5,32
    add x5,x5,x10
    lsr x6,x11,32
    add x5,x5,x6
    lsr x6,x7,32
    add x5,x5,x6
    str x5,[x2,diy_fp_f]
    ldr x4,[x0,diy_fp_e]       // x
    ldr x6,[x1,diy_fp_e]       // y
    add x4,x4,x6
    add x4,x4,64
    str x4,[x2,diy_fp_e]       // result
    
100:
    ldp x10,x11,[sp],16          // restaur des  2 registres
    ldp x8,x9,[sp],16          // restaur des  2 registres
    ldp x6,x7,[sp],16          // restaur des  2 registres
    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x3,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qM32:            .quad  0xFFFFFFFF 
/******************************************************************/
/*     afficage d'un float double précision                       */ 
/******************************************************************/
/* x0 contient la valeur à afficher  */
/* x1 contient l'adresse du buffer longueur > 30 caractères */
AfficherFloatDP:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    sub sp,sp,48               // reserve 48 octets : 16 pour FP 16 pour resultat scission
                               // et 8 pour resultat multiplication
    mov fp,sp                  // adresse zone réservée dans frame pointer
    mov x3,x1                  // save adresse buffer
    
    tst x0,1<<63               // nombre négatif ?
    beq 1f
    mov x2,'-'                 // oui préparation du signe
    strb w2,[x3]
    add x3,x3,1
1:
    cmp x0,0                   // nombre = zéro ?
    bne 2f
    ldr x2,iaffZero
    str w2,[x3]
    b 100f
2:
    tst x0,0x7FF<<52           // exposant à zéro ?
    bne 3f
    ldr x2,qAffNan
    str x2,[x3]
    b 100f
3:
    and x2,x0,0x7FF<<52
    lsr x2,x2,52
    cmp x2,0x7FF
    bne 4f
    ldr x2,qAffInf
    str x2,[x3]
    b 100f
4:
    affichelib OK
    mov x1,fp
    bl conversionDiy_fp
    mov x0,fp
    bl normalizeDiy_fp
    ldr x0,[fp,diy_fp_e]
    add x0,x0,64           // exposant
    mov x1,0               // alpha
    mov x2,3               // gamma ??
    bl  k_comp
   // affregtit retour 0
    mov x4,x0              // save coefficient
    add x0,x0,289          // calcul adresse poste kieme des puissance de 10
    mov x2,diy_fp_fin
    mul x0,x0,x2
    ldr x2,qAdrtablePuis10
    add x1,x2,x0           // contient l adresse de la puissance de 10
    mov x0,fp
    add x2,fp,32           // adresse zone resultat
    bl multiply
    mov x0,x2              // adresse zone resultat
    add x1,fp,16           // zone reception scission
    bl cut
    ldr w0,[x1]            // valeur zone 0
    mov x1,x3              // buffer
    mov x2,10
    bl conversion10W
    add x3,x3,x0
                           // conversion des zones 1 et 2
    ldr w0,[fp,20]
    mov x1,x3              // buffer
    bl extraction10W
    add x3,x3,x0
    ldr w0,[fp,24]
    mov x1,x3              // buffer
    bl extraction10W
    add x3,x3,x0
    mov w0,'E'
    strb w0,[x3]
    add x3,x3,1
    add x0,x4,1            // ajout de 1 à l exposant (????)
    neg x0,x0
    mov x1,x3
    bl conversion10S
    add x3,x3,x0
    mov w0,'\n'
    strb w0,[x3]
    add x3,x3,1
    strb wzr,[x3]
100:
    add sp,sp,48           // alignement pile
    ldp x3,x4,[sp],16      // restaur des  2 registres
    ldp x1,x2,[sp],16      // restaur des  2 registres
    ldp x0,lr,[sp],16      // restaur des  2 registres
    ret                    // retour adresse lr x30
iaffZero:             .int 0x00A30
qAffNan:              .quad 0x0A6E614E
qAffInf:              .quad 0x0A666E49         // infini
/******************************************************************/
/*     conversion décimale 4 octets non signée                             */ 
/******************************************************************/
/* x0 contient la valeur à convertir  */
/* x1 contient la zone receptrice  longueur >= 21 */
/* x2 contient le nombre de caractère à extraire */
/* la zone receptrice contiendra la chaine ascii cadrée à gauche */

/* x0 retourne la longueur de la chaine sans le zero */
.equ LGZONECONV,   10
conversion10W:
    stp x5,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    mov x4,#LGZONECONV        // position dernier chiffre
    mov w5,#10                // conversion decimale
1:                            // debut de boucle de conversion
    mov w2,w0                 // copie nombre départ ou quotients successifs
    udiv w0,w2,w5             // division par le facteur de conversion
    msub w3,w0,w5,w2           //calcul reste
    add w3,w3,#48              // car c'est un chiffre
    sub x4,x4,#1              // position précedente
    strb w3,[x1,x4]           // stockage du chiffre
    cbnz w0,1b                 // arret si quotient est égale à zero
    mov x2,LGZONECONV          // calcul longueur de la chaine (10 - dernière position)
    sub x0,x2,x4               // car pas d instruction rsb en 64 bits
                               // mais il faut déplacer la zone au début
    cbz x4,3f                  // si pas complète
    mov x2,0                   // position début  
2:    
    ldrb w3,[x1,x4]            // chargement un chiffre
    strb w3,[x1,x2]            // et stockage au debut
    add x4,x4,#1               // position suivante
    add x2,x2,#1               // et position suivante début
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
/*     extraction décimale de 7 chiffres de 4 octets non signée                             */ 
/******************************************************************/
/* w0 contient la valeur à convertir  */
/* x1 contient la zone receptrice  longueur >= 10 */
/* la zone receptrice contiendra la chaine ascii cadrée à gauche */
/* x0 retourne la longueur de la chaine sans le zero */
extraction10W:
    stp x5,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    mov x4,7                   // position dernier chiffre
    mov w3,'0'
0:
    strb w3,[x1,x4]
    subs x4,x4,1
    bge 0b
    mov x4,7                   // position dernier chiffre
    mov w5,#10                 // conversion decimale
1:                             // debut de boucle de conversion
    mov w2,w0                  // copie nombre départ ou quotients successifs
    udiv w0,w2,w5              // division par le facteur de conversion
    msub w3,w0,w5,w2           //calcul reste
    add w3,w3,#48              // car c'est un chiffre
    sub x4,x4,#1               // position précedente
    strb w3,[x1,x4]            // stockage du chiffre
    cbz x4,2f                  // arret si 7 caractère
    cbnz w0,1b                 // arret si quotient est égale à zero
2:
    mov x0,7
    strb wzr,[x1,x0]
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x5,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
    