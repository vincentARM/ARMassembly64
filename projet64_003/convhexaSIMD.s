/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* test conversion hexa avec instruction SIMD asm 64 bits  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"
.equ NBTESTS,       10000

.equ GETTIME,         113       //clock_gettime
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
szMessTemps: .ascii "Durée calculée : "
sSecondes: .fill 10,1,' '
             .ascii " s "
sMicroS:   .fill 10,1,' '
             .asciz " nanos\n"
.equ LGMESSTEMPS,           . - szMessTemps
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss
.align 4
qwDebut:    .skip 16
qwFin:      .skip 16
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
    affichelib verifroutine
    mov x0,0xDEF0
    movk x0,0x9ABC, lsl 16
    movk x0,0x5678, lsl 32
    movk x0,0x1234,lsl 48     // registre départ
    ldr x1,qAdrsBuffer        // zone receptrice
    bl conversionHexa
    ldr x0,qAdrsBuffer       // verification conversion
    affmemtit affresult x0 2
    mov  x0,-1               // autre valeur
    ldr x1,qAdrsBuffer
    bl conversionHexa
    ldr x0,qAdrsBuffer
    affmemtit affresult x0 2
    /* mesure temps execution routine SIMD*/
    bl startChrono
    mov x4,0                 // compteur début
1:
    mov x0,x4                // conversion du compteur
    ldr x1,qAdrsBuffer
    bl conversionHexa
    add x4,x4,1
    mov x1,NBTESTS
    cmp x4,x1
    ble 1b
    bl stopChrono

    /* mesure temps execution routine classique*/
    bl startChrono
    mov x4,0
2:
    mov x0,x4
    ldr x1,qAdrsBuffer
    bl prepRegistre16
    add x4,x4,1
    mov x1,NBTESTS
    cmp x4,x1
    ble 2b
    bl stopChrono


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
/******************************************************************/
/*     conversion hexa avec instructions SIMD                                              */ 
/******************************************************************/
/* x0 contient la valeur à convertir   */
/* x1 l'adresse de la zone receptrice */
conversionHexa:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    ldr x3,mask2              // extrait les demioctets pairs
    and x2,x0,x3
    mov v2.D[0],x2            // copie dans registre vecteurs
    mov v1.b[15],v2.B[0]       // et eclatement sur registres 128 bits
    mov v1.b[13],v2.B[1]
    mov v1.b[11],v2.B[2]
    mov v1.b[9],v2.B[3]
    mov v1.b[7],v2.B[4]
    mov v1.b[5],v2.B[5]
    mov v1.b[3],v2.B[6]
    mov v1.b[1],v2.B[7]
    ldr x3,mask1             // extrait les demioctets impairs
    and x2,x0,x3
    lsr x2,x2,4              // decalage demi octet droite
    mov v2.D[0],x2           // copie dans registre vecteurs
    mov v1.b[14],v2.B[0]      // et eclatement dans registre 128 bits
    mov v1.b[12],v2.B[1]
    mov v1.b[10],v2.B[2]
    mov v1.b[8],v2.B[3]
    mov v1.b[6],v2.B[4]
    mov v1.b[4],v2.B[5]
    mov v1.b[2],v2.B[6]
    mov v1.b[0],v2.B[7]
    movi v2.16b,0x9           // charge la valeur 9 dans les 16 octets
    cmgt v3.16b,v1.16b,v2.16b // compare si chaque octet est superieur à 9
    movi v2.16b,0x30          // valeur 0 pour chiffre 0 à 9
    movi v4.16b,0x37          // pour chiffre A à F 
    bit  v2.16b,v4.16b,v3.16b // remplace la valeur 30 par 37 pour tous les octets >
    add v3.16b,v1.16b,v2.16b  // addition pour conversion ascii
    str q3,[x1]               // stockage registre 128 en mémoire
    //mov x0,v3.D[1]            // recupération partie haute des 16 octets
    //rev x0,x0                 // inversion des octets
    //mov x2,v3.D[0]            // récuperation partie basse
    //rev x2,x2                 // inversion des octets
    //tp x0,x2,[x1]            // stockage des 2 registres en mémoire

100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
mask1:                   .quad 0xF0F0F0F0F0F0F0F0
mask2:                   .quad 0x0F0F0F0F0F0F0F0F
/********************************************************/
/* Lancement du chrono                                  */
/********************************************************/
startChrono:                 // fonction
    stp x0,lr,[sp,-16]!      // save  registres
    stp x1,x8,[sp,-16]!      // save  registres
    ldr x1,qAdrqwDebut       // zone de reception du temps début
    mov x0,0
    mov x8,GETTIME           // appel systeme gettimeofday
    svc 0 
    cmp x0,#0                // verification si l'appel est OK
    bge 100f
                             // affichage erreur
    adr x1,szMessErreurCH    // x0 <- code erreur, x1 <- adresse chaine */
    bl   afficheErreur       // appel affichage message
100:                         // fin standard  de la fonction  */
    ldp x1,x8,[sp],16        // restaur des  2 registres
    ldp x0,lr,[sp],16        // restaur des  2 registres
    ret                      // retour adresse lr x30
szMessErreurCH: .asciz "Erreur debut Chrono rencontrée.\n"
.align 4
qAdrqwDebut:         .quad qwDebut
/********************************************************/
/* Affichage du temps      */
stopChrono:                    // fonction
    stp x8,lr,[sp,-16]!        // save  registres
    stp x0,x5,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    ldr x1,qAdrqwFin           // zone de reception du temps fin
    mov x0,0
    mov x8,GETTIME             // appel systeme gettimeofday
    svc 0 
    cmp x0,#0
    blt 99f                    // verification si l'appel est OK
                               // calcul du temps
    ldr x0,qAdrqwDebut         // temps départ
    ldr x2,[x0]                // secondes
    ldr x3,[x0,#8]             // micro secondes
    ldr x0,qAdrqwFin           // temps arrivée
    ldr x4,[x0]                // secondes
    ldr x5,[x0,#8]             // micro secondes
    sub x2,x4,x2               // nombre de secondes ecoulées
    subs x3,x5,x3              // nombre de microsecondes écoulées
    bpl 1f
    sub x2,x2,#1               // si negatif on enleve 1 seconde aux secondes
    ldr x4,iSecMicro
    add x3,x3,x4               // et on ajoute 1 000 000 000 pour avoir un nb de nanosecondes exact
1:
    //affregtit avantconv 0
    mov x0,x2                  // conversion des secondes en base 10 pour l'affichage
    ldr x1,qAdrsBuffer
    bl conversion10
    ldr x4,qAdrsSecondes      // recopie des secondes dans zone affichage
2:
    ldrb w0,[x1],1
    cbz w0,3f
    strb w0,[x4],1
    b 2b
3:
    mov x0,x3                 // conversion des microsecondes en base 10 pour l'affichage
    ldr x1,qAdrsBuffer
    bl conversion10
    ldr x4,qAdrsMicroS        // recopie des micro secondes dans zone affichage
4:
    ldrb w0,[x1],1
    cbz w0,5f
    strb w0,[x4],1
    b 4b
5:
    ldr x0,qAdrszMessTemps   // r0 ← adresse du message 
    bl affichageMess         // affichage message dans console
    b 100f
99:                          // erreur rencontrée
    adr x1,szMessErreurCHS   // r0 <- code erreur, r1 <- adresse chaine
    bl   afficheErreur       // appel affichage message
100:                         // fin standard  de la fonction
    ldp x1,x2,[sp],16        // restaur des  2 registres
    ldp x3,x4,[sp],16        // restaur des  2 registres
    ldp x0,x5,[sp],16        // restaur des  2 registres
    ldp x8,lr,[sp],16        // restaur des  2 registres
    ret                      // retour adresse lr x30   
/* variables */
qAdrqwFin:               .quad qwFin
qAdrszMessTemps:         .quad szMessTemps
qAdrsSecondes:           .quad sSecondes
qAdrsMicroS:             .quad sMicroS
iSecMicro:               .quad 1000000000    
szMessErreurCHS: .asciz "Erreur stop Chrono rencontrée.\n"
.align 4
