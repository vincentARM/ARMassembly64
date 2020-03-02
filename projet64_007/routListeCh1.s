/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* routines pour liste chainée 64 bits  */
/* avec entête de liste     */
/* la valeur contenue dans l'entête n'est pas utilisable */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*******************************************/
/* Structures                               */
/********************************************/
/* structure linkedlist*/
    .struct  0
llist_next:                            // next element
    .struct  llist_next + 8
llist_value:                           // element value
    .struct  llist_value + 8
llist_fin:
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
szMessValElement:        .asciz "Valeur : @ \n"
szMessListeVide:         .asciz "Liste vide.\n"
szMessTrouve:            .asciz "Valeur trouvée.\n"
szMessNonTrouve:         .asciz "Valeur absente de la liste !\n"
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
sZoneConv:         .skip 100
.align 4
qDebutListe1:       .skip llist_fin
qDebutListe2:       .skip llist_fin
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    ldr x0,qAdrqDebutListe1
    bl afficheListe
    /* creation premier noeud */
    mov x0,5
    mov x1,0
    bl creerNoeud
    mov x5,x0
    mov x1,x0
    ldr x0,qAdrqDebutListe1
    bl insertNoeud
    ldr x0,qAdrqDebutListe1
    bl afficheListe
    /* creation noeud en tete de liste */
    mov x0,10
    mov x1,0
    bl creerNoeud
    mov x6,x0
    mov x1,x0
    ldr x0,qAdrqDebutListe1
    bl insertNoeud
    ldr x0,qAdrqDebutListe1
    bl afficheListe
    /* creation noeud apres noeud 1 */
    mov x0,15
    mov x1,0
    bl creerNoeud
    mov x7,x0
    mov x1,x0
    mov x0,x6                  // adresse du premier noeud
    bl insertNoeud
    ldr x0,qAdrqDebutListe1
    bl afficheListe
    mov x0,55
    mov x1,0
    bl creerNoeud
    mov x7,x0
    mov x1,x0
    mov x0,x6                  // adresse du premier noeud
    bl insertNoeud
    ldr x0,qAdrqDebutListe1
    bl afficheListe
    ldr x0,qAdrqDebutListe1
    bl triListe                // attention l'ancienne liste est détruite
    
    mov x20,x0                 // adresse de la nouvelle liste triée
    bl afficheListe
    mov x0,x20                 // recherche d'une valeur dans la liste triée
    mov x1,55
    bl rechValeur
    cmp x0,-1
    beq 2f
    ldr x0,qAdrszMessTrouve
    bl affichageMess
    b 3f
2:
    ldr x0,qAdrszMessNonTrouve
    bl affichageMess
3:
                                // copie liste
    mov x0,x20
    bl copieListe
    mov x21,x0
    bl afficheListe
                               // insertion dans liste trié
    mov x0,32
    mov x1,0
    bl creerNoeud
    mov x1,x0
    mov x0,x21
    bl insertNoeudTrie
    mov x0,66
    mov x1,0
    bl creerNoeud
    mov x1,x0
    mov x0,x21
    bl insertNoeudTrie
    mov x0,2
    mov x1,0
    bl creerNoeud
    mov x1,x0
    mov x0,x21
    bl insertNoeudTrie
    mov x0,x21
    bl afficheListe
                                // insertion liste vide
    ldr x22,qAdrqDebutListe2
    mov x0,10
    mov x1,0
    bl creerNoeud
    mov x1,x0
    mov x0,x22
    bl insertNoeudTrie
    mov x0,x22
    bl afficheListe
    mov x0,x21                 // suppression d'un noeud
    mov x1,55
    bl suppressionNoeudValeur
    cmp x0,-1
    beq 4f
    mov x0,x21
    bl afficheListe
4:
    mov x0,x21                 // suppression premier noeud
    mov x1,2
    bl suppressionNoeudValeur
    cmp x0,-1
    beq 5f
    mov x0,x21
    bl afficheListe
5:
    mov x0,x21                 // suppression dernier noeud
    mov x1,66
    bl suppressionNoeudValeur
    cmp x0,-1
    beq 6f
    mov x0,x21
    bl afficheListe
6:
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
qAdrqDebutListe1:        .quad qDebutListe1
qAdrqDebutListe2:        .quad qDebutListe2
qAdrszMessTrouve:        .quad szMessTrouve
qAdrszMessNonTrouve:     .quad szMessNonTrouve

/******************************************************************/
/*     initialisation Liste                                               */ 
/******************************************************************/
/* x0 contient l'adresse de debut de liste */
initListe:
    stp x0,lr,[sp,-16]!        // save  registres
    str xzr,[x0,llist_value]
    str xzr,[x0,llist_next]
100:
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     creation noeud                                             */ 
/******************************************************************/
/* x0 contient la clé   */
/* x1 contient zero ou l'adresse du noeud suivant */
/* x0 retourne l'adresse du noeud sur le tas */
creerNoeud:
    stp x2,lr,[sp,-16]!        // save  registres
    mov x2,x0
    mov x0,llist_fin
    bl allocPlace
    cmp x0,-1
    beq 100f
    str x2,[x0,llist_value]
    str x1,[x0,llist_next]
    //affregtit creat 0
100:
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     insert Noeud dans liste                                    */ 
/******************************************************************/
/* x0 contient l'adresse du noeud apres lequel il faut inserer */
/* x1 contient l'adresse du noeud à inserer */
insertNoeud:
    stp x2,lr,[sp,-16]!        // save  registres
    ldr x2,[x0,llist_next]
    str x2,[x1,llist_next]
    str x1,[x0,llist_next]
    //affregtit insert 0
100:
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     affiche les valeurs de la liste                                               */ 
/******************************************************************/
/* x0 contient l'adresse du debut de liste */
/* Attention la tête de liste ne doit pas être prise en compte */
afficheListe:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    affichelib afficheListe
    mov x2,x0
    ldr x2,[x2,llist_next]
    cbnz x2,1f
    ldr x0,qAdrszMessListeVide
    bl affichageMess
    b 100f
1:
    ldr x0,[x2,llist_value]
    ldr x1,qAdrsZoneConv
    bl conversion10S
    ldr x0,qAdrszMessValElement
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    bl affichageMess
    ldr x2,[x2,llist_next]
    cbnz x2,1b

100:
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszMessValElement:       .quad szMessValElement
qAdrszMessListeVide:        .quad szMessListeVide
qAdrsZoneConv:              .quad sZoneConv
/******************************************************************/
/*     suppression d'un noeud après un autre                      */ 
/******************************************************************/
/* x0 contient l'adresse du noeud après lequel il faut supprimer */
suppressionNoeud:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    ldr x1,[x0,llist_next]
    ldr x2,[x1,llist_next]
    str x2,[x0,llist_next]
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     recherche valeur dans liste                                */ 
/******************************************************************/
/* x0 contient l'adresse du debut de liste */
/* x1 contient la valeur à rechercher    */
/* x0 retourne l'adresse du noeud trouvé ou -1 si non trouvé */
rechValeur:
    stp x2,lr,[sp,-16]!        // save  registres
    mov x2,x0
    ldr x2,[x2,llist_next]     // liste vide ?
    cbnz x2,1f                 // non
    ldr x0,qAdrszMessListeVide
    bl affichageMess
    mov x0,-1
    b 100f
1:                             // boucle de recherche
    ldr x0,[x2,llist_value]
    cmp x0,x1
    beq 2f                     // trouvé
    ldr x2,[x2,llist_next]
    cbnz x2,1b
    mov x0,-1                  // non trouvé
    b 100f
2:
    mov x0,x2                  // retourne adresse du noeud
100:
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     triListe                                               */ 
/******************************************************************/
/* x0 contient l'adresse du debut de liste */
triListe:
    stp x1,lr,[sp,-16]!       // save  registres
    stp x2,x3,[sp,-16]!       // save  registres
    stp x4,x5,[sp,-16]!       // save  registres
    stp x6,x7,[sp,-16]!       // save  registres
    mov x6,x0                 // save tête liste
    mov x0,0
    mov x1,0
    bl creerNoeud             // création entête nouvelle liste
    mov x5,x0                 // tête nouvelle liste
    ldr x2,[x6,llist_next]    // premier noeud
1:
    cbz x2,6f                 // fin ?
    mov x1,x2                 // noeud courant à inserer
    ldr x3,[x1,llist_value]   // valeur du noeud à insérer
    ldr x2,[x1,llist_next]    // noeud suivant
    ldr x4,[x5,llist_next]    // premier noeud nouvelle liste
    mov x6,x4
    cbz x4,3f                 // liste vide ?
    mov x0,x5                 // tete nouvelle liste dans noeud precedent
2:
    ldr x7,[x4,llist_value]   // valeur du noeud 
    cmp x7,x3                 // valeur du noeud > valeur à inserer
    bgt 3f

    mov x0,x4                 // save noeud précedent
    ldr x4,[x0,llist_next]    // noeud suivant
    cbz x4,3f                 // dernier noeud ?
    b 2b                      // sinon boucle
3:                            // fin de recherche donc insertion 
    str x4,[x1,llist_next]    // adresse du noeud dans le suivant du noeud à inserer
    str x1,[x0,llist_next]    // adresse du noeud à inserer dans le suivant du noeud précedent
    b 1b                      // boucle sur autre noeud à inserer

6:                            // fin retourne la tete de la liste triée
    mov x0,x5

100:
    ldp x6,x7,[sp],16          // restaur des  2 registres
    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret
/******************************************************************/
/*     copieListe                                               */ 
/******************************************************************/
/* x0 contient l'adresse du debut de liste */
/* x0 retourne l'adresse de debut de la nouvelle liste */
copieListe:
    stp x1,lr,[sp,-16]!       // save  registres
    stp x2,x3,[sp,-16]!       // save  registres
    stp x4,x5,[sp,-16]!       // save  registres
    mov x2,x0                 // save addresse
    mov x0,0
    mov x1,0
    bl creerNoeud             // création entête nouvelle liste
    mov x3,x0                 // tête nouvelle liste
    mov x4,x0
    ldr x2,[x2,llist_next]    // liste vide ?
    cbnz x2,1f                // non
    mov x0,x3                 // retourne le noeud vide
    b 100f
1:
    ldr x0,[x2,llist_value]   // recup valeur
    mov x1,0
    bl creerNoeud
    mov x1,x0                // adresse du noeud crée
    mov x0,x4                // insertion après le noeud précedent
    mov x4,x1                // et on garde l'adresse du dernier noeud crée
    bl insertNoeud
    ldr x2,[x2,llist_next]
    cbnz x2,1b
    mov x0,x3                // retourne la tête de liste

100:
    ldp x4,x5,[sp],16        // restaur des  2 registres
    ldp x2,x3,[sp],16        // restaur des  2 registres
    ldp x1,lr,[sp],16        // restaur des  2 registres
    ret
/******************************************************************/
/*     insertion noeud dans liste  triée                              */ 
/******************************************************************/
/* x0 contient l'adresse du debut de liste */
/* x1 contient l'adresse du noeud à inserer    */
/* x0 retourne  */
insertNoeudTrie:
    stp x2,lr,[sp,-16]!        // save  registres
    mov x5,x0
    mov x2,x0
    ldr x2,[x2,llist_next]     // liste vide ?
    cbz x2,2f                  //  oui

    ldr x3,[x1,llist_value]     // valeur à rechercher
1:                             // boucle de recherche cle supérieure
    ldr x4,[x2,llist_value]
    cmp x3,x4
    ble 2f                     // insertion
    mov x5,x2
    ldr x2,[x2,llist_next]
    cbnz x2,1b
2:
    mov x0,x5
    bl insertNoeud
100:
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     recherche valeur dans liste                                */ 
/******************************************************************/
/* x0 contient l'adresse du debut de liste */
/* x1 contient la valeur à rechercher    */
/* x0 retourne l'adresse du noeud trouvé ou -1 si non trouvé */
suppressionNoeudValeur:
    stp x2,lr,[sp,-16]!        // save  registres
    mov x5,x0
    mov x2,x0
    ldr x2,[x2,llist_next]     // liste vide ?
    cbnz x2,1f                 // non
    ldr x0,qAdrszMessListeVide
    bl affichageMess
    mov x0,-1
    b 100f
1:                             // boucle de recherche
    ldr x0,[x2,llist_value]
    cmp x0,x1
    beq 2f                     // trouvé
    mov x5,x2
    ldr x2,[x2,llist_next]
    cbnz x2,1b
    mov x0,-1                  // non trouvé
    b 100f
2:
    mov x0,x5
    bl suppressionNoeud
    mov x0,x5                  // retourne le noeud precedent.
100:
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
