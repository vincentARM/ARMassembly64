/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* test instructions accès mémoire asm 64 bits  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"
.equ NBPOSTESTABLE,   10
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*********************************/
/* Structures                    */
/*********************************/
/* exemple de table */
    .struct  0
table1_cle:          /* clé de l'enregistrement */ 
    .struct  table1_cle + 4 
table1_valeur:       /* valeur sur 2 octets*/ 
    .struct  table1_valeur + 2 
table1_code:         /* code sur un octet */
    .struct  table1_code + 1
table1_cpl:          /* complement pour arriver à 8 octets */
    .struct  table1_cpl + 1
table1_fin:
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
szMessErreurTable:        .asciz "Erreur: table trop petite.\n"
.equ LGMESSERREURTABLE,    . - szMessErreurTable
szMessAffEnreg:           .ascii "N° : "
sNumEnreg:                .fill  5, 1, ' '
                          .ascii " clé :"
sCle:                     .fill 10, 1 , ' '
                          .ascii " valeur :"
sValeur:                  .fill 5,1,' '
                          .ascii " code :"
sCode:                    .fill 3,1,' '
                          .asciz "\n"
.equ LGMESSENREG,         . - szMessAffEnreg
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
qZonesTest:         .skip 8 * 2000
stTable:            .skip table1_fin * NBPOSTESTABLE
sBuffer:            .skip 100
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
    ldr x1,qAdrqZonesTest
    mov w0,'A'                  // stockage un caractère
    strb w0,[x1]
    affmemtit stockeCas1 x1 2
    affregtit stockeCas1 0
    ldr x1,=qZonesTest
    mov w0,0xFFFF                // stockage demi mot : 16 bits
    strh w0,[x1,2]             // frontière demi mot
    affmemtit stockeCas2 x1 2
    affregtit stockeCas2 0
    ldr x1,qAdrqZonesTest
    mov w0,-5                  // stockage  mot
    str w0,[x1,4]              // frontière  mot
    affmemtit stockeCas3 x1 2
    affregtit stockeCas3 0
    ldr x1,qAdrqZonesTest
    mov x0,-2                  // stockage double mot
    str x0,[x1,8]              // frontière double mot
    affmemtit stockeCas4 x1 2
    affregtit stockeCas4 0

    /* lecture memoire */
    mov x0,xzr
    ldr x1,qAdrqZonesTest
    mov x2,8
    ldr x0,[x1,x2]            // chargement double mot
    affregtit chargeCas1 0
    ldr x1,qAdrqZonesTest
    ldr  w0,[x1,4]!            // chargement mot avec avancement avant de x1
    affregtit chargeCas2 0
    ldr x1,qAdrqZonesTest
    ldrh w0,[x1],2            // chargement demi mot avec avancement après de x1
    affregtit chargeCas3 0
    ldr x1,qAdrqZonesTest
    ldrb w0,[x1]            // chargement octet
    affregtit chargeCas4 0
    ldr x1,qAdrqZonesTest
    add x1,x1,16
    ldr x0,[x1,-256]            // chargement double mot
    affregtit chargeCas5 0
    ldr x0,[x1,5080]            // chargement double mot
    affregtit chargeCas6 0
    ldr x1,qAdrqZonesTest
    add x1,x1,16
    ldur x0,[x1,-16]            // chargement double mot ldur
    affregtit chargeldur7 0

    /* stockage avec calcul deplacement */
    ldr x1,qAdrqZonesTest
    mov x0,-6                  // stockage double mot
    mov x2,4
    str x0,[x1,x2,lsl 3]      // stockage à x1 + (4 * 8) curieux 2 ne marche pas
    affmemtit stockdeplacement x1 4
    affregtit stockdeplacement 0
    /* lecture avec calcul deplacement */
    mov x0,0
    ldr x1,qAdrqZonesTest
    mov x2,4
    ldr x0,[x1,x2,lsl 3]      // lecture de x1 + (4 * 8) idem
    affregtit lectdeplacement 0
    /* lecture avec calcul deplacement pour un mot*/
    mov x0,0
    ldr x1,qAdrqZonesTest
    mov x2,4
    ldr w0,[x1,x2,lsl 2]      // lecture de x1 + (4 * 4) pour un mot c'est ok
    affregtit lecturemotdeplacement 0
    ldr x1,qAdrqZonesTest
    mov w2,4
    ldr x0,[x1,w2,UXTW 3]      // lecture de x1 + (4 * 8) 
    affregtit lectureextraregistre 0

    /* stockage octet negatif */
    ldr x1,qAdrqZonesTest
    mov w0,-6                  // byte negatif
    strb w0,[x1]               // stockage 
    affmemtit stockoctetnegatif x1 2
    affregtit stockoctetnegatif 0
    /* lecture un octet */
    mov x0,0
    ldr x1,qAdrqZonesTest
    ldrb w0,[x1]
    affregtit lectoctetsimple 0
    /* lecture avec complement negatif */
    mov x0,0
    ldr x1,qAdrqZonesTest
    ldrsb x0,[x1]      // lecture de l'octet avec report du signe sur registre 64 
    affregtit lectoctetnegatif64 0
    mov x0,0
    ldrsb w0,[x1]      // lecture de l'octet avec report du signe sur registre 64 
    affregtit lectoctetnegatif32 0
    /**********************************/
    /* EXEMPLE GESTION TABLE          */
    /**********************************/
    mov x28,0         // compteur de postes
    /* insertion un enregistrement */
    ldr x0,qAdrstTable
    mov x1,110
    mov x2,50
    mov x3,'C'
    bl insertionTable
    cmp x0,-1          // erreur ?
    beq 100f
   /* insertion un enregistrement */
    ldr x0,qAdrstTable
    mov x1,150
    mov x2,20
    mov x3,'Z'
    bl insertionTable
    cmp x0,-1         // erreur ?
    beq 100f

    /* affichage table */
    affichelib Affichagetable
    ldr x0,qAdrstTable
    mov x1,0          // 1er enregistrement
1:
    bl affichageTable
    add x1,x1,1
    cmp x1,x28        // nombre d'enregistrement ?
    blt 1b            // et boucle

100:                           // fin standard du programme
    ldr x0,qAdrszMessFinPgm    // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                   // code retour
    mov x8,EXIT                // system call "Exit"
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdrqZonesTest:          .quad qZonesTest
qAdrstTable:             .quad stTable
/******************************************************************/
/*     insertion dans une table                                   */ 
/******************************************************************/
/* x0 : adresse de la table  */
/* x1 : cle */
/* x2 : valeur */
/* x3 : code  */
insertionTable:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x6,x7,[sp,-16]!        // save  registres
    stp x4,x5,[sp,-16]!        // save  registres
    mov x4,#0
    mov x5,table1_fin          // longueur d'un enregistrement
1:
    madd x6,x4,x5,x0           // calcul adresse enregistrement
    ldr w7,[x6,table1_cle]     // clé à zéro ?
    cbz w7,2f                  // oui -> insertion
    add x4,x4,#1               // non enregistrement suivant
    cmp x4,NBPOSTESTABLE       // nb de postes maxi ?
    bge 99f                    // oui -> erreur
    b 1b                       // sinon boucle
2:
    str w1,[x6,table1_cle]     // insertion à l'adresse trouvée
    strh w2,[x6,table1_valeur]
    strb w3,[x6,table1_code]
    add x28,x28,1              // compteur de postes
    mov x0,x6                  // retourne l'adresse du poste crée
    b 100f
99:                            // erreur taille table
    ldr x0,qadrszMessErreurTable
    mov x1,LGMESSERREURTABLE
    bl affichageMessSP
    mov x0,-1
100:
    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x6,x7,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qadrszMessErreurTable:       .quad szMessErreurTable
/******************************************************************/
/*     insertion dans une table                                   */ 
/******************************************************************/
/* x0 : adresse de la table  */
/* x1 : numero enregistrement */
affichageTable:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    mov x2,table1_fin
    madd x3,x1,x2,x0           // calcul de l'adresse
    mov x0,x1                  // N° enregistrement
    ldr x1,qAdrsBuffer
    bl conversion10            // conversion décimale
    ldr x4,qAdrsNumEnreg
1:                             // et recopie dans la zone d'affichage
    ldrb w2,[x1],1
    cbz w2,2f
    strb w2,[x4],1
    b 1b
2:
    ldrsw x0,[x3,table1_cle]    // idem pour la clé
    ldr x1,qAdrsBuffer
    bl conversion10
    ldr x4,qAdrsCle
3:
    ldrsb x2,[x1],1
    cbz w2,4f
    strb w2,[x4],1
    b 3b
4:
    ldrsh x0,[x3,table1_valeur] // idem pour la valeur
    ldr x1,qAdrsBuffer
    bl conversion10
    ldr x4,qAdrsValeur
5:
    ldrsb x2,[x1],1
    cbz w2,6f
    strb w2,[x4],1
    b 5b
6:
    ldrsb x0,[x3,table1_code]   // recup du code
    ldr x4,qAdrsCode           // et copie dans zone d'affichage
    strb w0,[x4]

    ldr x0,qAdrszMessAffEnreg  // affichage du résultat final
    mov x1,LGMESSENREG
    bl affichageMessSP
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrsBuffer:            .quad sBuffer
qAdrszMessAffEnreg:     .quad szMessAffEnreg
qAdrsCle:               .quad sCle
qAdrsValeur:            .quad sValeur
qAdrsCode:              .quad sCode
qAdrsNumEnreg:          .quad sNumEnreg
