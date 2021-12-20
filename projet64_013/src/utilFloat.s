/* Programme assembleur ARM Raspberry 64 bits */
/* Utilitaire affichage float double 64 bits  voir le site ci dessous  */
/* https://blog.benoitblanchon.fr/lightweight-float-to-string/ */ 

/**********************************************/
/* CONSTANTES                              */
/**********************************************/
.include "./src/constantesARM64.inc"

/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text
.global convertirFloat
/******************************************************************/
/*     Conversion Float                                            */ 
/******************************************************************/
/* d0  contient la valeur du Float */
/* x0 contient l'adresse de la zone de conversion  mini 20 caractères*/
/* x0 retourne la longueur utile de la zone */
convertirFloat:               // INFO: convertirFloat
    stp x1,lr,[sp,-16]!       // save  registres
    stp x2,x3,[sp,-16]!       // save  registres
    stp x4,x5,[sp,-16]!       // save  registres
    stp x6,x7,[sp,-16]!       // save  registres
    stp x8,x9,[sp,-16]!       // save  registres
    stp d1,d2,[sp,-16]!       // save  registres
    mov x6,x0                 // save adresse de la zone
    fmov x0,d0
    mov x8,#0                 // nombre de caractères écrits
    mov x3,#'+'
    strb w3,[x6]              // forçage du signe +
    mov x2,x0
    tbz x2,63,1f              // test du bit 63 pour determiner le signe
    mov x2,1
    lsl x2,x2,63
    bic x0,x0,x2              // raz du 63 ième bit pour valeur toujours positive
    mov x3,#'-'               // et signe -
    strb w3,[x6]              // dans résultat
1:
    adds x8,x8,#1             // position suivante
    cmp x0,#0                 // cas du 0 positif ou negatif
    bne 2f
    mov x3,#'0'
    strb w3,[x6,x8]           // stocke le caractère 0
    adds x8,x8,#1
    mov x3,#0
    strb w3,[x6,x8]           // stocke le 0 final
    mov x0,x8                 // retourne la longueur
    b 100f
2: 
    ldr x2,iMaskExposant
    mov x1,x0
    and x1,x1,x2              // extraction exposant
   // affregtit mask 0
    cmp x1,x2
    bne 4f
    tbz x0,51,3f              // test du bit 51 à zéro 
    mov x2,#'N'               // cas du Nan. stk byte car pas possible de stocker un int 
    strb w2,[x6]              // car zone non alignée
    mov x2,#'a'
    strb w2,[x6,#1] 
    mov x2,#'n'
    strb w2,[x6,#2] 
    mov x2,#0                  // 0 final
    strb w2,[x6,#3] 
    mov x0,#3
    b 100f
3:                             // cas infini positif ou négatif
    mov x2,#'I'
    strb w2,[x6,x8] 
    adds x8,x8,#1
    mov x2,#'n'
    strb w2,[x6,x8] 
    adds x8,x8,#1
    mov x2,#'f'
    strb w2,[x6,x8] 
    adds x8,x8,#1
    mov x2,#0
    strb w2,[x6,x8]
    mov x0,x8
    b 100f
4:
    bl normaliserFloat
    mov x5,x0                  // save exposant
    fcvtzu d2,d0               // valeur entière de la partie entière
    fmov x0,d2                 // partie entière
    scvtf d1,d2                // remise en float
    fsub d1,d0,d1              // pour extraire partie fractionnaire
    ldr d2,dConst1
    fmul d1,d2,d1              // pour la recadrer en partie entière
    fcvtzu d1,d1               // convertir en entier
    fmov x4,d1                 // valeur fractionnaire
                               // conversion partie entière dans x0
    mov x2,x6                  // save adresse début zone 
    adds x6,x6,x8
    mov x1,x6
    bl conversion10
    add x6,x6,x0
    mov x3,#','
    strb w3,[x6]
    adds x6,x6,#1
 
    mov x0,x4                  // conversion partie fractionnaire
    mov x1,x6
    bl conversion10SP          // conversion spéciale car il faut conserver les zéros en tête
    add x6,x6,x0
    sub x6,x6,#1
                               // et il faut supprimer les zéros finaux
5:
    ldrb w0,[x6]
    cmp w0,#'0'
    bne 6f
    sub x6,x6,#1
    b 5b
6:
    cmp w0,#','
    bne 7f
    sub x6,x6,#1
7:
    add x6,x6,#1
    mov x3,#'E'
    strb w3,[x6]
    add x6,x6,#1
    mov x0,x5                  // conversion exposant
    mov x3,x0
    tbz x3,63,4f               // exposant négatif ?
    neg x0,x0                  // on le positive !!
    mov x3,#'-'                // et stockage du signe - dans le résultat
    strb w3,[x6]
    adds x6,x6,#1
4:                             // conversion exposant
    mov x1,x6
    bl conversion10
    add x6,x6,x0
    
    strb wzr,[x6]              // 0 final
    adds x6,x6,#1
    mov x0,x6
    subs x0,x0,x2              // retour de la longueur de la zone
    subs x0,x0,#1              // sans le 0 final

100:
    ldp d1,d2,[sp],16          // restaur  registres
    ldp x8,x9,[sp],16          // restaur  registres
    ldp x6,x7,[sp],16          // restaur  registres
    ldp x4,x5,[sp],16          // restaur  registres
    ldp x2,x3,[sp],16          // restaur  registres
    ldp x1,lr,[sp],16           // restaur registres
    ret
    
iMaskExposant:            .quad 0x7FF<<52
dConst1:                  .double 0f1E17

/***************************************************/
/*   normaliser float                              */
/***************************************************/
/* x0 contient la valeur du float (valeur toujours positive et <> Nan) */
/* d0 retourne la nouvelle valeur */
/* x0 retourne l'exposant */
normaliserFloat:            // INFO: normaliserFloat
    stp x1,lr,[sp,-16]!     // save  registres
    fmov d0,x0              // valeur de départ
    mov x0,#0               // exposant
    ldr d1,dConstE7         // pas de normalisation pour les valeurs < 1E7
    fcmp d0,d1
    blo 10f                 // si d0 est < dConstE7
    
    ldr d1,dConstE256
    fcmp d0,d1
    blo 1f
    fdiv d0,d0,d1
    adds x0,x0,#256
1:
    
    ldr d1,dConstE128
    fcmp d0,d1
    blo 1f
    fdiv d0,d0,d1
    adds x0,x0,#128
1:
    ldr d1,dConstE64
    fcmp d0,d1
    blo 1f
    fdiv d0,d0,d1
    adds x0,x0,#64
1:
    ldr d1,dConstE32
    fcmp d0,d1
    blo 1f
    fdiv d0,d0,d1
    adds x0,x0,#32
1:
    ldr d1,dConstE16
    fcmp d0,d1
    blo 2f
    fdiv d0,d0,d1
    adds x0,x0,#16
2:
    ldr d1,dConstE8
    fcmp d0,d1
    blo 3f
    fdiv d0,d0,d1
    adds x0,x0,#8
3:
    ldr d1,dConstE4
    fcmp d0,d1
    blo 4f
    fdiv d0,d0,d1
    adds x0,x0,#4
4:
    ldr d1,dConstE2
    fcmp d0,d1
    blo 5f
    fdiv d0,d0,d1
    adds x0,x0,#2
5:
    ldr d1,dConstE1
    fcmp d0,d1
    blo 10f
    fdiv d0,d0,d1
    adds x0,x0,#1

10:
    ldr d1,dConstME5         // pas de normalisation pour les valeurs > 1E-5
    fcmp d0,d1
    bhi 100f                 // fin
    
    ldr d1,dConstME255
    fcmp d0,d1
    bhi 11f
    ldr d1,dConstE256

    fmul d0,d0,d1
    subs x0,x0,#256
11:
    
    ldr d1,dConstME127
    fcmp d0,d1
    bhi 11f
    ldr d1,dConstE128

    fmul d0,d0,d1
    subs x0,x0,#128
11:
    
    ldr d1,dConstME63
    fcmp d0,d1
    bhi 11f
    ldr d1,dConstE64

    fmul d0,d0,d1
    subs x0,x0,#64
11:
   
    ldr d1,dConstME31
    fcmp d0,d1
    bhi 11f
    ldr d1,dConstE32

    fmul d0,d0,d1
    subs x0,x0,#32
11:
    ldr d1,dConstME15
    fcmp d0,d1
    bhi 12f
    ldr d1,dConstE16
    fmul d0,d0,d1
    subs x0,x0,#16
12:
    ldr d1,dConstME7
    fcmp d0,d1
    bhi 13f
    ldr d1,dConstE8
    fmul d0,d0,d1
    subs x0,x0,#8
13:
    ldr d1,dConstME3
    fcmp d0,d1
    bhi 14f
    ldr d1,dConstE4
    fmul d0,d0,d1
    subs x0,x0,#4
14:
    ldr d1,dConstME1
    fcmp d0,d1
    bhi 15f
    ldr d1,dConstE2
    fmul d0,d0,d1
    subs x0,x0,#2
15:
    ldr d1,dConstE0
    fcmp d0,d1
    bhi 100f
    ldr d1,dConstE1
    fmul d0,d0,d1
    subs x0,x0,#1

100:                       // fin standard de la fonction
    ldp x1,lr,[sp],16      // restaur registres
    ret
.align 2
dConstE7:             .double 0f1E7
dConstE256:           .double 0f1E256
dConstE128:           .double 0f1E128
dConstE64:            .double 0f1E64
dConstE32:            .double 0f1E32
dConstE16:            .double 0f1E16
dConstE8:             .double 0f1E8
dConstE4:             .double 0f1E4
dConstE2:             .double 0f1E2
dConstE1:             .double 0f1E1
dConstME5:            .double 0f1E-5
dConstME255:          .double 0f1E-255
dConstME127:          .double 0f1E-127
dConstME63:           .double 0f1E-63
dConstME31:           .double 0f1E-31
dConstME15:           .double 0f1E-15
dConstME7:            .double 0f1E-7
dConstME3:            .double 0f1E-3
dConstME1:            .double 0f1E-1
dConstE0:             .double 0f1E0

/******************************************************************/
/*     Conversion d'un registre en décimal                        */ 
/******************************************************************/
/* x0 contient la valeur et x1 l' adresse de la zone de stockage   */
/* modif 05/11/2021 pour garder les zéros de tête  */
conversion10SP:                 // INFO: conversion10SP
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x4,x5,[sp,-16]!         // save  registres
    mov x5,x1
    mov x4,#16
    mov x2,x0
    mov x1,#10                  // conversion decimale
1:                              // debut de boucle de conversion
    mov x0,x2                   // copie nombre départ ou quotients successifs
    udiv x2,x0,x1               // division par le facteur de conversion
    msub x3,x1,x2,x0
    add x3,x3,#48               // car c'est un chiffre    
    strb w3,[x5,x4]             // stockage du byte au debut zone (x5) + la position (x4)
    subs x4,x4,#1               // position précedente
    bge 1b
    strb wzr,[x5,16]            // 0 final
100:    
    ldp x4,x5,[sp],16           // restaur  registres
    ldp x2,x3,[sp],16           // restaur  registres
    ldp x1,lr,[sp],16           // restaur registres
    ret
