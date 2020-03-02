/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* routines pour liste avec double chainage 64 bits  */
/* avec entête de liste     */

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
/* structure liste double chainage*/
    .struct  0
dllist_entete:                    // pointeur premier noeud
    .struct  dllist_entete + 8
dllist_queue:                     // pointeur dernier noeud
    .struct  dllist_queue  + 8
dllist_fin:
/* structure des noeuds pour double chainage*/
    .struct  0
NDlist_next:                     // pointeur vers noeud suivant
    .struct  NDlist_next + 8
NDlist_prev:                     // pointeur vers noeud précédent
    .struct  NDlist_prev + 8
NDlist_valeur:                   // element valeur ou clé
    .struct  NDlist_valeur + 8
NDlist_fin:
/*******************************************/
/* Données initialisées                    */
/*******************************************/
.data
szMessInitListe:         .asciz "Liste initialisée.\n"
szCarriageReturn:        .asciz "\n"
szMessErreur:            .asciz "Erreur détectée.\n"
szMessValElement:        .asciz "Valeur : @ \n"
szMessListeVide:         .asciz "Liste vide.\n"
/*******************************************/
/* Données non initialisées                */
/*******************************************/
.bss 
dllist1:              .skip dllist_fin    // réservation place liste
sZoneConv:            .skip 24
/*******************************************/
/*  code section                           */
/*******************************************/
.text
.global main 
main: 
    ldr x0,qAdrdllist1
    bl newDList                      // creation nouvelle liste
    ldr x0,qAdrszMessInitListe
    bl affichageMess
    ldr x0,qAdrdllist1               // affiche liste vide
    bl afficheListe
    ldr x0,qAdrdllist1               // adresse liste
    bl afficheListeInverse           // doit aussi afficher liste vide
    ldr x0,qAdrdllist1               // adresse liste
    mov x1,#10                       // valeur
    bl insertEntete                  // insertion au début
    cmp x0,#-1
    beq 99f
    ldr x0,qAdrdllist1
    bl afficheListe
    ldr x0,qAdrdllist1
    mov x1,#20
    bl insertQueue                    // insertion en fin
    cmp x0,#-1
    beq 99f
    ldr x0,qAdrdllist1               // adresse liste
    mov x1,#10                       // valeur après laquelle il faut insérer
    mov x2,#15                       // valeur à inserer
    bl insertAfter
    cmp x0,#-1
    beq 99f
    ldr x0,qAdrdllist1               // adresse liste
    bl afficheListe
    ldr x0,qAdrdllist1               // adresse liste
    bl afficheListeInverse
    mov x0,0
    b 100f
99:
    ldr x0,qAdrszMessErreur
    bl affichageMess
    mov x0,1                         // code erreur
100:                                 // fin standard
    mov x8,EXIT
    svc 0
qAdrszMessInitListe:       .quad szMessInitListe
qAdrszMessErreur:          .quad szMessErreur
qAdrszCarriageReturn:      .quad szCarriageReturn
qAdrdllist1:               .quad dllist1
/******************************************************************/
/*     creation liste                                             */ 
/******************************************************************/
/* x0 contient l'adresse de la liste */
newDList:
    str xzr,[x0,#dllist_queue]
    str xzr,[x0,#dllist_entete]
    ret
/******************************************************************/
/*     liste vide ?                                               */ 
/******************************************************************/
/* x0 contient l'adresse de la liste */
/* x0 retourne 0 si vide sinon  retourne  1 */
estVide:
    ldr x0,[x0,#dllist_entete]
    cbz x0,100f
    mov x0,#1
100:
    ret
/******************************************************************/
/*     insertion valeur en début de liste                           */ 
/******************************************************************/
/* x0 contient l'adresse de la liste */
/* x1 contient la valeur */
insertEntete:
    stp x2,lr,[sp,-16]!                  // save  registres
    stp x3,x4,[sp,-16]!                  // save  registres
    mov x4,x0                            // save adresse
    mov x0,x1                            // valeur
    bl creerNoeud
    cmp x0,#-1                           // erreur d'allocation  ?
    beq 100f
    //affregtit creation 0
    ldr x2,[x4,#dllist_entete]           // charge adresse du premier noeud
    str x2,[x0,#NDlist_next]             // stocke adresse dans nouveau pointeur suivant
    str xzr,[x0,#NDlist_prev]            // stocke zero dans le pointeur précedent
    str x0,[x4,#dllist_entete]           // stocke adresse noeud dans pointeur entete de liste
    cmp x2,#0                            // addresse du premier noeud est nulle ?
    beq 1f
    str x0,[x2,#NDlist_prev]             // non -> stocke l'adresse du noeud dans le pointeur 
    b 100f
1:
    str x0,[x4,#dllist_queue]            // sinon stocke l'adresse dans le pointeur de queue de la liste
100:
    ldp x3,x4,[sp],16                    // restaur  2 registres
    ldp x2,lr,[sp],16                    // restaur  2 registres
    ret
/******************************************************************/
/*     insertion valeur en fin de liste                           */ 
/******************************************************************/
/* x0 contient l'adresse de la liste */
/* x1 contient la valeur */
insertQueue:
    stp x2,lr,[sp,-16]!                  // save  registres
    stp x3,x4,[sp,-16]!                  // save  registres
    mov x4,x0                            // save adresse liste
    mov x0,x1                            // valeur
    bl creerNoeud                        // creation d'un noeud
    cmp x0,#-1
    beq 100f                             // erreur d'allocation
    ldr x2,[x4,#dllist_queue]            // charge l'adresse du dernier noeud
    str x2,[x0,#NDlist_prev]             // et la stocke dans le pointeur précedent
    str xzr,[x0,#NDlist_next]            // stocke zéro dans le pointeur suivant
    str x0,[x4,#dllist_queue]            // stocke l'adresse du noeud dans le pointeur enqueue de la liste
    cbz x2,1f                            // adresse du dernier noeus est nulle
    str x0,[x2,#NDlist_next]             // non -> stocke adresse dans pointeur suivant
    b 100f
1:
    str x0,[x4,#dllist_entete]           // sinon stocke dans pointeur entete de la liste
100:
    ldp x3,x4,[sp],16                    // restaur  2 registres
    ldp x2,lr,[sp],16                    // restaur  2 registres
    ret
/******************************************************************/
/*     insertion valeur après une autre valeur                    */ 
/******************************************************************/
/* x0 contient l'adresse de la liste */
/* x1 contient la valeur à rechercher*/
/* x2 contient la valeur à inserer */
insertAfter:
    stp x2,lr,[sp,-16]!                     // save  registres
    stp x3,x4,[sp,-16]!                  // save  registres
    mov x4,x0                               // save adresse liste
    bl chercheValeur                        // recherche de la valeur
    cmp x0,#-1
    beq 100f                                // non trouvée -> erreur
    mov x3,x0                               // save adresse du noeud trouvé
    mov x0,x2                               // valeur
    bl creerNoeud                           // creation du noeud
    cmp x0,#-1
    beq 100f                                // erreur d'allocation
    ldr x2,[x3,#NDlist_next]                // charge le pointeur suivant du noeud trouvé
    str x0,[x3,#NDlist_next]                // stocke l'adresse du noeud dans le pointeur suivant
    str x3,[x0,#NDlist_prev]                // stocke l'adresse du noeud trouvé dans le pointeur pr�cedent
    str x2,[x0,#NDlist_next]                // stocke le pointeur suivant du noeud trouvé dans le pointeur suivant du noeud
    cbz x2,1f                               // pointeur suivant est nul ?
    str x0,[x2,#NDlist_prev]                // non stocke l'adresse dans pointeur précedent
    b 100f
1:
    str x0,[x4,#dllist_queue]             // sinon stocke l'adresse de le pointeur enqueue de la liste
100:
    ldp x3,x4,[sp],16                    // restaur  2 registres
    ldp x2,lr,[sp],16                       // restaur  2 registres
    ret
/******************************************************************/
/*     recherche une valeur                                       */ 
/******************************************************************/
/* x0 contient l'adresse de la liste */
/* x1 contient la valeur à chercher  */
/* x0 retourne l'adresse du noeud trouvé si -1 si non trouvée*/
chercheValeur:
    stp x2,lr,[sp,-16]!                  // save  registres
    ldr x0,[x0,#dllist_entete]           // charge le premier noeud
1:
    cbz x0,99f                            // si nul, fin de la recherche. Non trouvée
    ldr x2,[x0,#NDlist_valeur]           // charge la valeur du noeud
    cmp x2,x1                            // egale ?
    beq 100f
    ldr x0,[x0,#NDlist_next]             // charge adresse noeud suivant 
    b 1b                                 // et boucle
99:
    mov x0,-1
100:
    ldp x2,lr,[sp],16                    // restaur  2 registres
    ret
/******************************************************************/
/*     Creation d'un nouveau noeud                                */ 
/******************************************************************/
/* x0 contient la valeur */
/* x0 retourne l'adresse du noeud ou -1 si erreur d'allocation */
creerNoeud:
    stp x1,lr,[sp,-16]!                  // save  registres
    mov x1,x0                            // save valeur
                                         // allocation place sur le tas
    mov x0,#NDlist_fin                   // reservation taille d'un noeud
    bl allocPlace
    cmp x0,#-1                           // erreur d'allocation
    beq 100f
    str x1,[x0,#NDlist_valeur]           // stocke la valeur
    str xzr,[x0,#NDlist_next]            // stocke 0 dans pointeur suivant
    str xzr,[x0,#NDlist_prev]            // stocke 0 dans pointeur précedent
100:
    ldp x1,lr,[sp],16                    // restaur  2 registres
    ret
/******************************************************************/
/*     affiche les valeurs de la liste                                               */ 
/******************************************************************/
/* x0 contient contient l'adresse de la liste */
afficheListe:
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    affichelib afficheListe
    mov x2,x0
    ldr x2,[x2,#dllist_entete]  // charge le premier noeud
    cbnz x2,1f
    ldr x0,qAdrszMessListeVide
    bl affichageMess
    b 100f
1:                              // début de boucle
    ldr x0,[x2,NDlist_valeur]
    ldr x1,qAdrsZoneConv
    bl conversion10S
    ldr x0,qAdrszMessValElement
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    bl affichageMess
    ldr x2,[x2,NDlist_next]
    cbnz x2,1b

100:
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszMessValElement:       .quad szMessValElement
qAdrszMessListeVide:        .quad szMessListeVide
qAdrsZoneConv:              .quad sZoneConv
/******************************************************************/
/*     affiche les valeurs de la liste                                               */ 
/******************************************************************/
/* x0 contient contient l'adresse de la liste */
afficheListeInverse:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    affichelib afficheListeInverse
    mov x2,x0
    ldr x2,[x2,#dllist_queue]   // charge le dernier noeud
    cbnz x2,1f
    ldr x0,qAdrszMessListeVide
    bl affichageMess
    b 100f
1:                              // début de boucle
    ldr x0,[x2,NDlist_valeur]
    ldr x1,qAdrsZoneConv
    bl conversion10S
    ldr x0,qAdrszMessValElement
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    bl affichageMess
    ldr x2,[x2,NDlist_prev]
    cbnz x2,1b

100:
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
