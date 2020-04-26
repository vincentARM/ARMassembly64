/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/* Factorisation d'un nombre */
/* utilisation des threads    */
/* A lancer par facteurThread64  <Nombre> */
/* le programme vérifie si le nombre saisi n'est pas premier */
/* Attention : la routine de conversion du nombre saisi limite */
/* les nombres car il s'agit d'une routine pour des nombres signés */
/* pour des nombres plus grands, il faut les mettre directement dans le code !!! */
/* voir exemples lignes 95 et 300 */

/*********************************************/
/*           CONSTANTES                      */
/********************************************/
.include "../constantesARM64.inc"
.equ WAITID,     95
.equ TKILL,       130
.equ GETPPID,    173
.equ GETTID,     178
.equ CLONE,      220
.equ WAIT4,      260

.equ WNOHANG,               1  //  Wait, do not suspend execution
.equ WUNTRACED,             2   // Wait, return status of stopped child
.equ WCONTINUED,            8   // Wait, return status of continued child
.equ WEXITED,               4   // Wait for processes that have exited
//.equ WSTOPPED,            16   // Wait, return status of stopped child
.equ WNOWAIT,               32    //Wait, return status of a child without
.equ SIG_BLOCK,      1
.equ SIGCHLD,  17

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne:      .asciz  "\n"
szMessageThread:    .asciz "Execution thread du fils. \n" 
szMessageFinThread: .asciz "Fin du thread. \n" 
szMessageParent:    .asciz "C'est moi le papa !!\n"
szMessDebutPgm:     .asciz "Début programme.\n"
.equ LGMESSDEBUT,   . - szMessDebutPgm
szMessFinPgm:       .asciz "Fin ok du programme.\n"
.equ LGMESSFIN,     . - szMessFinPgm
szRetourLigne:      .asciz "\n"
.equ LGRETLIGNE,    . - szRetourLigne
szMessErreur:       .asciz "Erreur rencontrée.\n"
szMessOverflow:     .asciz "Dépassement de capacité vérification premier.\n"
szMessPremier:      .asciz "Ce nombre est premier.\n"
szMessResult:       .asciz "Facteur = @ \n"
szMessResult1:      .asciz "Facteur petit = @ \n"
szMessResult2:      .asciz "Facteur grand = @ \n"
szMessErrComm:      .asciz "Ligne de commande incomplete : facteurThread64 <nombre>\n"
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
qStatus:          .skip 8

/* zones pour l'appel fonction sleep */
qZonesAttente:
 qSecondes:      .skip 8
 qMicroSecondes: .skip 8
qZonesTemps:     .skip 16

qSet:            .skip 160
zRusage:         .skip 1000
sBuffer:         .skip 500
sZoneConv1:      .skip 24
sZoneConv2:      .skip 24
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text
.global main

main:                           // programme principal
    mov fp,sp                   // recup adresse pile  registre x29 fp
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    ldr x0,[fp]                 // nombre de paramètres ligne de commande
    cmp x0,#1                   // correct ?
    ble erreurCommande          // erreur

    add x0,fp,#16               // adresse du 2ième paramètre
    ldr x0,[x0]
    bl conversionAtoD
    mov x20,x0                  // save nombre
    //ldr x20,qNombre1          // pour tests
    //ldr x20,qNombrePrem
    //ldr x0,qFact1
    //ldr x1,qFact3
    //mul x20,x0,x1             // pour calcul grand nombre 
    //umulh x21,x0,x1           // pour verif depassement
    //ldr x20,qNombre4
    //affregtit deb 20
                                // verif premier */
    mov x0,x20
    bl verifPremier
    //affregtit retprem 0
    cbnz x0,premier
    mov x0,0
    mov x8,GETTID               // recup identifiant du père gettid
    svc 0
    mov x4,x0                   // identifiant père passé dans paramètre x4
    mov x21,x0                  // save du pid pere
                                // lancement du thread fils
    ldr x0,qFlags
    mov x1,0
    mov x2,0
    mov x3,0
    mov x5,0
    mov x8,CLONE                // appel fonction systeme clone
    svc 0 
    cmp x0,#0
    blt erreur
    bne parent                  // si <> zero x0 contient le pid du pere
                                // sinon c'est le fils 
    mov x1,x20                  // nombre
    bl chercherPetitF
    b 100f                      // normalement on ne revient jamais ici

parent:    
    mov x19,x0                 // save du pid fils 1
    mov x4,x21                 // identifiant père passé dans paramètre x4
                               // lancement du thread fils
    ldr x0,qFlags
    mov x1,0
    mov x2,0
    mov x3,0
    mov x5,0
    mov x8,CLONE                // appel fonction systeme clone
    svc 0 
    cmp x0,#0
    blt erreur
    bne parent1                 // si <> zero x0 contient le pid du pere
                                // sinon c'est le fils 
    mov x1,x20                  // nombre
    bl chercherGrandF
    b 100f                     // normalement on ne revient jamais ici

parent1:
    mov x22,x0                  // recup du pid 2ième fils
    //affregtit threadpere 19
    mov x4,x21                  // identifiant père passé dans paramètre x4
                                // lancement du thread fils
    ldr x0,qFlags
    mov x1,0
    mov x2,0
    mov x3,0
    mov x5,0
    mov x8,CLONE                 // appel fonction systeme clone
    svc 0 
    cmp x0,#0
    blt erreur
    bne parent2                  // si <> zero x0 contient le pid du pere
                                 // sinon c'est le fils 
    mov x1,x20                   // nombre
    bl decompRho
    b 100f                       // normalement on ne revient jamais ici

parent2:
    mov x23,x0                   // recup PID du 3ième fils
    //affregtit pereattente 0

1:                                 // debut de boucle d'attente des signaux du fils
    mov x0,x19                     // attente signal du pid fils 1
    ldr x1,qAdrqStatus             // contient le status de retour
    mov x2,#WCONTINUED| WUNTRACED | WNOHANG // revoir options
    ldr x3,qAdrzRusage             // structure contenant les infos de retour 
    mov x8,WAIT4                   // appel fonction systeme WAIT4
    svc 0 
    cmp x0,#0
    blt erreur
    bgt 2f

    mov x0,x22                     // attente signal du pid fils 2
    ldr x1,qAdrqStatus             // contient le status de retour
    mov x2,#WCONTINUED | WUNTRACED| WNOHANG // revoir options
    ldr x3,qAdrzRusage             // structure contenant les infos de retour 
    mov x8,WAIT4                   // appel fonction systeme WAIT4
    svc 0 
    cmp x0,#0
    blt erreur
    bgt 3f


    mov x0,x23                     // attente signal du pid fils 3
    ldr x1,qAdrqStatus             // contient le status de retour
    mov x2,#WCONTINUED | WUNTRACED| WNOHANG // revoir options
    ldr x3,qAdrzRusage             // structure contenant les infos de retour 
    mov x8,WAIT4                   // appel fonction systeme WAIT4
    svc 0 
    cmp x0,#0
    blt erreur
    bgt 4f

    b 1b                           // sinon on boucle 
2:
    //affregtit finthread1 19
    mov x0,x22
    mov x1,9
    mov x8,TKILL
    svc 0
    cbz x0,21f
    affregtit erreurTKILLTH1 0
    b erreur
21:
    mov x0,x23
    mov x1,9
    mov x8,TKILL
    svc 0
    cbz x0,5f
    affregtit erreurTKILLTH1 0
    b erreur
3:
    //affregtit finthread2 19
    mov x0,x19
    mov x1,9
    mov x8,TKILL
    svc 0
    cbz x0,31f
    affregtit erreurTKILLTH1 0
    b erreur
31:
    mov x0,x23
    mov x1,9
    mov x8,TKILL
    svc 0
    cbz x0,5f
    affregtit erreurTKILLTH1 0
    b erreur
    b 5f
4:                              // Fin 3ieme thread
    //affregtit finthread3 19
                                // arret des 2 autres
    mov x0,x19
    mov x1,9
    mov x8,TKILL
    svc 0
    cbz x0,41f
    affregtit erreurTKILLTH3 0
    b erreur
41:
    mov x0,x22
    mov x1,9
    mov x8,TKILL
    svc 0
    cbz x0,5f
    affregtit erreurTKILLTH3 0
    b erreur
5:
    ldr x0,qAdrszMessFinPgm     // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                    // code retour
    b 100f

premier:
    ldr x0,qAdrszMessPremier
    bl affichageMess
    mov x0,#1                   // code erreur
    b 100f
erreur:                         // affichage erreur
    ldr x1,qAdrszMessErreur
    bl   afficheErreur
    mov x0,#1                   // code erreur
    b 100f
erreurCommande:
    ldr x1,qAdrszMessErrComm
    bl   afficheErreur   
    mov x0,#1                   // code erreur
    b 100f
100:                            // fin standard du programme
    mov x8,EXIT                 // system call "Exit"
    svc #0
qFlags:                  .quad SIGCHLD
qAdrqZonesAttente:       .quad qZonesAttente
qAdrqZonesTemps:         .quad qZonesTemps
qAdrszMessageParent:     .quad szMessageParent
qAdrszMessErreur:        .quad szMessErreur
qAdrszMessErrComm:       .quad szMessErrComm
qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdrszMessPremier:       .quad szMessPremier
qAdrzRusage:             .quad zRusage
qAdrqStatus:             .quad qStatus
qAdrqSecondes:           .quad qSecondes
qAdrszMessResult1:       .quad szMessResult1
qAdrsZoneConv1:          .quad sZoneConv1
qAdrszMessResult2:       .quad szMessResult2
qAdrsZoneConv2:          .quad sZoneConv2
qNombre1:                .quad 8000016166000622191
qNombre2:                .quad 900000006023     // premier
qNombre3:                .quad 3492064813715162969
qNombre4:                .quad 1537228672093301419
qFact1:                  .quad 3000001651
qFact2:                  .quad 3500004311
qNombrePrem:             .quad 100000000003
qFact3:                  .quad  1193

/***************************************************/
/*   appel du thread  petit facteur                */
/***************************************************/
chercherPetitF:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    stp x4,x5,[sp,-16]!        // save  registres
    mov x8,173                 // getppid appel fonction systeme pour trouver le pid du pére */
    svc 0 
    affregtit petitfacteurs 0  // voir dans le registre zero
    tst x1,1                   // nombre pair
    beq 9f
    mov x10,3
    udiv x2,x1,x10
    msub x4,x10,x2,x1
    cbz x4,10f
1:
    mov x2,1
    mov x5,6
2:
    mul x4,x5,x2
    sub x10,x4,1
    udiv x6,x1,x10
    msub x7,x6,x10,x1
    cbz x7,10f
    add x10,x4,1
    udiv x6,x1,x10
    msub x7,x6,x10,x1
    cbz x7,10f
    add x2,x2,1
    cmp x2,x1
    bhi 99f
    b 2b
9:  
    mov x10,2                 // nombre pair
10:
    mov x0,x10                // affichage résultat
    ldr x1,qAdrsZoneConv1
    bl conversion10
    ldr x0,qAdrszMessResult1
    ldr x1,qAdrsZoneConv1
    bl strInsertAtChar
    bl affichageMess 
    ldr x0,qAdrszMessageFinThread
    bl affichageMess
    mov x0,x10                // retour résultat
    //affregtit finpetitsfacteurs 0
    b 100f
99:                            // affichage erreur fils
    ldr x1,qAdrszMessErreur
    bl   afficheErreur
    mov x0,#-1                 // code erreur
    b 100f
100:
    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    //ret
    mov x8,EXIT                // appel fonction systeme pour terminer
    svc 0
//qAdrqSet:                 .quad qSet
qAdrszMessageFinThread:   .quad szMessageFinThread
qAdrszMessageThread:      .quad szMessageThread
/***************************************************/
/*   appel du thread  grand facteur                */
/***************************************************/
chercherGrandF:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    stp x4,x5,[sp,-16]!        // save  registres
    //mov x8,173                 // getppid appel fonction systeme pour trouver le pid du pére */
    //svc 0 
    affregtit grandsFacteurs 0          // voir dans le registre zero
    // calcul racine carree du nombre
    mov x0,x1
    bl calRacineCarree
    //affregtit racine 0
    mov x18,x0
    mul x2,x18,x18
    cmp x2,x1
    beq 10f
1:
    mov x5,6
    udiv x2,x0,x5
    affregtit debutGF 0
2:
    mul x4,x5,x2
    sub x18,x4,1
    udiv x16,x1,x18
    msub x17,x16,x18,x1
    cbz x17,10f
    add x18,x4,1
    udiv x16,x1,x18
    msub x17,x16,x18,x1
    cbz x17,10f
    sub x2,x2,1
    cbz x2,99f
    b 2b

10:
    mov x0,x16                // affichage résultat
    ldr x1,qAdrsZoneConv2
    bl conversion10
    ldr x0,qAdrszMessResult2
    ldr x1,qAdrsZoneConv2
    bl strInsertAtChar
    bl affichageMess 
    mov x0,x18                // retour résultat
    //affregtit fingrandsfacteurs 0
    b 100f
99:                            // affichage erreur fils
    ldr x1,qAdrszMessErreur
    bl   afficheErreur
    mov x0,#-1                 // code erreur
    b 100f
100:
    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    mov x8,EXIT                // appel fonction systeme pour terminer
    svc 0

/***************************************************/
/*   Exemple d'appel du thread               */
/***************************************************/
decompRho:
    stp x1,lr,[sp,-16]!        // save  registres
    affregtit decompRho 0      // voir dans le registre zero
    mov x0,x1
    bl calculRho
    affregtit fincalculRho 0

100:
    ldp x1,lr,[sp],16          // restaur des  2 registres
    mov x8,EXIT                // appel fonction systeme pour terminer
    svc 0
/***************************************************/
/*   Calcul racine carree                          */
/***************************************************/
/* x0 contient le nombre  non signé                  */
/* x0 retourne la racine carrée   ou - 1               */
calRacineCarree:
    stp x1,lr,[sp,-16]!       // save  registres
    stp x2,x3,[sp,-16]!       // save  registres
    stp x4,x5,[sp,-16]!       // save  registres
    stp x6,x7,[sp,-16]!       // save  registres
    cmp x0,0
    beq 100f                  // si zero fin
1:
    cmp x0,#4                 // si inférieur à 4 retourne 1
    bhi 2f 
    mov x0,#1
    b 100f
2:                    // début calcul
    mov x3,64
    clz x2,x0         // nombre de zéros à gauche
    sub x2,x3,x2      // donc nombre de chiffres utiles à droite
    bic x2,x2,#1      // pour avoir un nombre pair de chiffres
    mov x3,#0b11      // masque pour extraitre 2 bits consécutif du registre origine
    lsl x3,x3,x2      // et placement sur les 2 premiers bits utiles
    mov x1,#0         // init résultat avec 0
    mov x4,#0         // raz zone reste
3:                    // boucle de calcul
    and x5,x0,x3      // extraction de 2 bits avec le masque
    lsr x6,x5,x2       // deplacement à droite 
    add x4,x4,x6      // addition avec le reste précedent 
    lsl x5,x1,1       // multiplication du résultat par 2 
    lsl x5,x5,#1      // deplacement d'un bit à gauche
    orr x5,x5,#1      // et on met 1 pour voir si le calcul est bon
    lsl x1,x1,#1      // on decale x1 à gauche
    mov x6,x4
    subs x4,x4,x5     // on l'enleve du reste
    csel x4,x6,x4,mi  // si negatif on remet x4 à l'état d'avant
    add x6,x1,1
    csel x1,x6,x1,pl  // et on met 1 au dernier bit de la racine si resultat positif  (sinon il reste à 0)
    subs x2,x2,#2     // passage aux 2 autre caractères à droite.
    bmi 4f            // c'est fini ?
    lsl x4,x4,#2      // non donc déplacement du reste de 2 caractères sur la gauche
    lsr x3,x3,#2      // et deplacement du masque de 2 caractères vers la droite
    b 3b              // et boucle
4:                    // fin du calcul
    mov x0,x1         // retour résultat

100:
    ldp x6,x7,[sp],16          // restaur des  2 registres
    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/***************************************************/
/*   Verification si un nombre est premier         */
/***************************************************/
/* x0 contient le nombre à verifier */
/* x0 retourne 1 si premier  0 sinon */
//2147483647  OK
//4294967297  NOK
//131071       OK
//1000003    OK 
//10001363   OK
verifPremier:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    mov x2,x0
    sub x1,x0,#1
    cmp x2,0
    beq 99f                    // retourne zéro
    cmp x2,2                   // pour 1 et 2 retourne 1
    bls 2f                     // comparaison non signée
    mov x0,#2
    bl moduloPuR64
    bcs 100f                   // erreur overflow
    cmp x0,#1
    bne 99f                    // Pas premier
    cmp x2,3
    beq 2f
    mov x0,#3
    bl moduloPuR64
    blt 100f                   // erreur overflow
    cmp x0,#1
    bne 99f

    cmp x2,5
    beq 2f
    mov x0,#5
    bl moduloPuR64
    bcs 100f                   // erreur overflow
    cmp x0,#1
    bne 99f                    // Pas premier

    cmp x2,7
    beq 2f
    mov x0,#7
    bl moduloPuR64
    bcs 100f                   // erreur overflow
    cmp x0,#1
    bne 99f                    // Pas premier

    cmp x2,11
    beq 2f
    mov x0,#11
    bl moduloPuR64
    bcs 100f                   // erreur overflow
    cmp x0,#1
    bne 99f                    // Pas premier

    cmp x2,13
    beq 2f
    mov x0,#13
    bl moduloPuR64
    bcs 100f                   // erreur overflow
    cmp x0,#1
    bne 99f                    // Pas premier

    cmp x2,17
    beq 2f
    mov x0,#17
    bl moduloPuR64
    bcs 100f                   // erreur overflow
    cmp x0,#1
    bne 99f                    // Pas premier

2:
    cmn x0,0                   // carry à zero pas d'erreur
    mov x0,1                   // premier
    b 100f
99:
    cmn x0,0                   // carry à zero pas d'erreur
    mov x0,#0                  // Pas premier
100:
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

/********************************************************/
/*   Calcul modulo de b puissance e modulo m  */
/*    Exemple 4 puissance 13 modulo 497 = 445         */
/********************************************************/
/* x0  nombre  */
/* x1 exposant */
/* x2 modulo   */
moduloPuR64:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x5,x6,[sp,-16]!        // save  registres
    stp x7,x8,[sp,-16]!        // save  registres
    stp x9,x10,[sp,-16]!        // save  registres
    cbz x0,100f
    cbz x1,100f
    mov x8,x0
    mov x7,x1
    mov x6,1                   // resultat
    udiv x4,x8,x2
    msub x9,x4,x2,x8           // contient le reste
    //affregtit debutmod 0
1:
    tst x7,1
    beq 2f
    mul x4,x9,x6
    umulh x5,x9,x6
    //cbnz x5,99f
    mov x6,x4
    mov x0,x6
    mov x1,x5
    bl divisionReg128U
    mov x6,x3               // x3 contient le reste
2:
    mul x8,x9,x9
    umulh x5,x9,x9
    //cbnz x5,99f
    mov x0,x8
    mov x1,x5
    bl divisionReg128U
    mov x9,x3                  // x3 contient le reste
    lsr x7,x7,1
    cbnz x7,1b
    mov x0,x6                  // result
    cmn x0,0                   // carry à zero pas d'erreur
    b 100f
99:
    affregtit overflow 0
    affregtit overflow 4
    ldr x1,qAdrszMessOverflow
    bl   afficheErreur
    cmp x0,0                   // carry à un car erreur
    mov x0,-1                  // code erreur

100:
    ldp x9,x10,[sp],16          // restaur des  2 registres
    ldp x7,x8,[sp],16          // restaur des  2 registres
    ldp x5,x6,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszMessOverflow:         .quad  szMessOverflow
/***************************************************/
/*   algorithme rho de décomposition en facteurs */
/***************************************************/
/* x0 contient le nombre à decomposer*/
calculRho:
    stp x1,lr,[sp,-16]!     // save  registres
    stp x2,x3,[sp,-16]!     // save  registres
    mov x19,x0
    mov x10,0xFFFF          // nombre de boucles maxi
    lsl x10,x10,4           // à ajuster si pas de résultat
    mov x0,0
    sub x1,x19,1
    bl extRandom
    mov x11,0
    mov x13,x0           //xi
    mov x14,x0           // y
    mov x12,1            // i
    mov x15,2            // k
    mov x17,1            // un
1:
    mov x16,x13          // = xi-1
    add x12,x12,1        // i + 1
    mul x0,x16,x16       // xi = (xi-1) au carré
    umulh x1,x16,x16
    subs x0,x0,1         // - 1
    sbc x1,x1,xzr
    mov x2,x19

    bl divisionReg128U   // x3 contient le reste
    mov x13,x3
    sub x0,x14,x13       // y - xi
    mov x1,x19           // n
    bl calPGCDmod
    cmp x0,1
    beq 2f
    cmp x0,x19
    beq 2f
    //affregtit trouve 0
    ldr x1,qAdrsBuffer
    bl conversion10
    ldr x0,qAdrszMessResult
    ldr x1,qAdrsBuffer
    bl strInsertAtChar
    bl affichageMess 
    add x11,x11,1
    cmp x11,4              // affichage de 4 résultats 
    beq 100f
2:
    cmp x12,x15            // i = k ?
    bne 3f
    mov x14,x13            // xi -> y
    lsl x15,x15,1          // * 2
3:
    subs x10,x10,1
    ble 100f               // fin 

    b 1b                   // ou boucle 

99:
    affregtit OVERFLOW 1
100:
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrsBuffer:       .quad sBuffer
qAdrszMessResult:  .quad szMessResult
/***************************************************/
/*   Calcul PGCD */
/***************************************************/
/* x0 contient le premier nombre */
/* x1 contient le deuxieme nombre */
/* x0 retourne le PGCD            */
/* si erreur carry est mis à 1    */
calPGCD:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    cbz x0,99f
    cbz x1,99f
1:
    cmp x0,x1
    bhi 2f
    mov x2,x0
    mov x0,x1
    mov x1,x2
2:
    sub x0,x0,x1
    cmp x0,0
    bhi 1b                     // boucle
    mov x0,x1
    cmn x0,0                   // carry à 0
    b 100f
99:                            // erreur detectée
    mov x0,0
    cmp x0,0                   // carry à 1
100:
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

/***************************************************/
/*   Calcul du pgcd en utilisant le modulo */
/***************************************************/
/* x0 contient le premier nombre */
/* x1 contient le deuxieme nombre */
/* x0 retourne le PGCD            */
/* si erreur carry est mis à 1    */
calPGCDmod:                    // NON SIGNE
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    cbz x0,99f                 // si = 0 erreur
    cbz x1,99f
1:
    cmp x0,x1
    bhi 2f
    mov x2,x0
    mov x0,x1
    mov x1,x2
2:
    udiv x2,x0,x1
    msub x0,x2,x1,x0
    cmp x0,0
    bhi 1b                     // boucle
    mov x0,x1
    cmn x0,0                   // carry à 0
    b 100f
99:                            // erreur detectée
    mov x0,0
    cmp x0,0                   // carry à 1
100:
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     nombre aléatoire                                          */ 
/******************************************************************/
/* Attention : utilise une zone buffer de 8 octets */
/*  x0 contient la valeur inferieure */
/*  x1 contient la valeur superieure */
/*  x0 retourne le nombre */
extRandom:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x8,[sp,-16]!        // save  registres
    stp x19,x20,[sp,-16]!      // save  registres
    sub sp,sp,16               // reserve 16 octets sur la pile
    mov x19,x0
    add x20,x1,1
    mov x0,sp                  // stockage du resultat sur la pile
    mov x1,8                   // longueur 8 octets
    mov x2,0
    mov x8,278                 // appel cal system Urandom
    svc 0
    mov x0,sp                  // recup du résultat sur la pile
    ldr x0,[x0]
    sub x2,x20,x19             // calcul de la plage des valeurs 
    udiv x1,x0,x2              // calcul du modulo plage
    msub x0,x1,x2,x0
    add  x0,x0,x19             // et ajout de la valeur inférieure
100:
    add sp,sp,16               // realignement de la pile 
    ldp x19,x20,[sp],16        // restaur des  2 registres
    ldp x2,x8,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/***************************************************/
/*   division d un nombre de 128 bits par un nombre de 64 bits */
/***************************************************/
/* x0 contient partie basse dividende */
/* x1 contient partie haute dividente */
/* x2 contient le diviseur */
/* x0 retourne partie basse quotient */
/* x1 retourne partie haute quotient */
/* x3 retourne le reste */
/* version corrigée 22/04/2020 */
divisionReg128U:
    stp x6,lr,[sp,-16]!        // save  registres
    stp x4,x5,[sp,-16]!        // save  registres
    stp x7,x8,[sp,-16]!        // save  registres
    cmp x1,0                   // verif que le dividende est > au diviseur
    cbnz x1,0f
    cmp x0,x2
    bgt 0f
    mov x3,x0
    mov x0,0
    b 100f
0:
    mov x7,#0                  // raz du reste R
    mov x3,#128                // compteur de boucle
    mov x4,#0                  // dernier bit
1:
    mov x8,0                  // raz reste partie haute
    tst x7,1<<63              // test bit gauche du reste partie basse
    lsl x7,x7,1               // dacalage partie basse du reste
    beq 2f
    orr  x8,x8,#1              // et on le pousse dans le reste R partie haute
2:
    tst x1,1<<63               // test du bit le plus à gauche
    lsl x1,x1,#1               // on decale la partie haute du quotient de 1
    beq 3f
    orr  x7,x7,#1              // et on le pousse dans le reste R
3:
    tst x0,1<<63
    lsl x0,x0,#1               // puis on decale la partie basse 
    beq 4f
    orr x1,x1,#1               // et on pousse le bit de gauche dans la partie haute
4:
    orr x0,x0,x4               // position du dernier bit du quotient
    mov x4,#0                  // raz du bit
    /* modification pour résoudre le cas du divisueur > 2 ^^ 62 - 1 */
    mov x5,x7                 // save du reste partie basse
    mov x6,x8                 // save du reste partie haute
    subs x7,x7,x2             // soustraction du diviseur
    sbc  x8,x8,xzr            // retenue si x7 est plus petit
    cmp x8,-1
    beq 5f
    mov x4,#1                 // dernier bit à 1
    b 6f
5:                            // il faut restaurer le reste
    mov x7,x5
    mov x8,x6
6:
                              // et boucle
    subs x3,x3,#1
    bgt 1b    
    lsl x1,x1,#1              // on decale le quotient de 1
    tst x0,1<<63
    lsl x0,x0,#1              // puis on decale la partie basse 
    beq 7f
    orr x1,x1,#1
7:
    orr x0,x0,x4              // position du dernier bit du quotient
    mov x3,x7
100:
    ldp x7,x8,[sp],16          // restaur des  2 registres
    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x6,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

