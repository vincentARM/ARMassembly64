/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* algorithmes d'optimisation adaptés au problème du sac à dos  asm 64 bits  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"
.equ POIDSMAX,            20  // 20
.equ NBVOISINS,           20    // 30
.equ MULTIRATIO,          100
.equ MAXITERSTABLE,       10
.equ MAXPOSTABOUE,        5
.equ TEMPDEPART,          20    // temperature départ
.equ NBSOLUTIONSESSAIMS,  300    // 30
.equ MAXITERESSAIMS,      20
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*******************************************/
/* Structures               INFO: Stuctures */
/********************************************/
/* example structure Boite  */
    .struct  0
boite_nom:                        // nom
    .struct  boite_nom + 8 
boite_poids:                      // poids
    .struct  boite_poids + 8 
boite_valeur:                     // valeur
    .struct  boite_valeur + 8 
boite_fin:
/* structure linkedlist*/
    .struct  0
llist_next:                       // next element
    .struct  llist_next + 8
llist_taille:
llist_nom:                        // nom ou taille
    .struct  llist_nom + 8
llist_poids:                      // poids
    .struct  llist_poids + 8
llist_valeur:                     // valeur
    .struct  llist_valeur + 8
llist_ratio:                      // ratio = valeur * MULTIRATIO / poids 
    .struct  llist_ratio + 8
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
szMessPasdesolution:       .asciz "Liste solution vide !!\n"
szMessSolution:            .asciz "Valeur totale = @ poids total = @ nb de boites : @\nListe des boites : \n"
szMessBoite:               .asciz " ==> poids = @ valeur = @ ratio = @\n"

/* nom des boites */
szNomA:           .asciz "A"
szNomB:           .asciz "B"
szNomC:           .asciz "C"
szNomD:           .asciz "D"
szNomE:           .asciz "E"
szNomF:           .asciz "F"
szNomG:           .asciz "G"
szNomH:           .asciz "H"
szNomI:           .asciz "I"
szNomJ:           .asciz "J"
szNomK:           .asciz "K"
szNomL:           .asciz "L"
.align 4
/* table des boites pointeur nom, poids, valeur */
tbBoites:       .quad szNomA,4,15
                .quad szNomB,7,15
                .quad szNomC,10,20
                .quad szNomD,3,10
                .quad szNomE,6,11
                .quad szNomF,12,16
                .quad szNomG,11,12
                .quad szNomH,16,22
                .quad szNomI,5,12
                .quad szNomJ,14,21
                .quad szNomK,4,10
                .quad szNomL,3,7
                .equ NBBOITES,    (. - tbBoites)/ boite_fin // nombre de boites
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
.align 4
sZoneConv:           .skip 24
qZoneRec:            .skip 16
stListeBoites:       .skip llist_fin
stListeTaboue:       .skip llist_fin
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // INFO: main
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    affichelib Exemple
    ldr x0,qAdrstListeBoites
    bl creerProbleme1

    ldr x0,qAdrstListeBoites
    bl verifListe
                                // lancement des algos
    ldr x0,qAdrstListeBoites
    bl resoudreAlgoGlouton

    ldr x0,qAdrstListeBoites
    bl resoudreDescenteGradient

    ldr x0,qAdrstListeBoites
    bl resoudreRechercheTaboue

    ldr x0,qAdrstListeBoites
    bl resoudreRecuitSimule

    ldr x0,qAdrstListeBoites
    bl resoudreEssaimsPart
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
qAdrsZoneConv:           .quad sZoneConv
//qAdrstProbleme:          .quad stProbleme
qAdrstListeBoites:       .quad stListeBoites
/******************************************************************/
/*     creer problème  1                                             */ 
/******************************************************************/
/* x0 contient l'adresse de la liste des boites */
creerProbleme1:                // INFO: creerProbleme
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    //affichelib creerProbleme
    mov x17,x0
                               // recopie table des boites dans liste chainée
    ldr x13,qAdrtbBoites
    mov x12,0
    mov x14,boite_fin
1:
    madd x15,x12,x14,x13
    ldr x0,[x15,boite_nom]
    ldr x1,[x15,boite_poids]
    ldr x2,[x15,boite_valeur]
    bl creerNoeud
    mov x1,x0
    mov x0,x17
    bl insertNoeud
    add x12,x12,1
    cmp x12,NBBOITES
    blt 1b
    str x12,[x17,llist_taille]  // nombre de noeuds dans la liste
100:
    ldp x1,x2,[sp],16           // restaur des  2 registres
    ldp x0,lr,[sp],16           // restaur des  2 registres
    ret                         // retour adresse lr x30
qAdrtbBoites:         .quad tbBoites
/******************************************************************/
/*     resolution par l'algorithme glouton                        */ 
/******************************************************************/
/* x0 contient l'adresse de la liste des boites */
resoudreAlgoGlouton:              // INFO: resoudreAlgoGlouton
    stp x20,lr,[sp,-16]!          // save  registres
    stp x21,x22,[sp,-16]!         // save  registres
    affichelib resoudreAlgoGlouton
    mov x10,x0
    mov x0,llist_fin              // creation d'une liste solution
    bl allocPlace
    cmp x0,-1
    beq 100f
    mov x20,x0                    // adresse de la liste creee
    mov x0,x10                    // copie de la liste des boites disponibles
    bl copieListe                 // x0 contient l'adresse de la liste copiee
    bl triListe
    mov x21,x0                    // liste triée suivant ratio 
    //bl afficherSolutionDirect
    mov x0,x21
    mov x22,POIDSMAX             // poids maxi du sac
    ldr x21,[x21,llist_next]
    cbz x21,100f                 // liste vide
1:                               // balayage de la liste
    ldr x12,[x21,llist_poids]    // charge un poids
    cmp x12,x22                  // superieur au reste ?
    bgt 2f
    sub x22,x22,x12              // diminue le poids total

    mov x0,x21                   // adresse du noeud trouvé
    mov x1,x20                   // adresse liste solution
    bl copieNoeud 
2:
    ldr x21,[x21,llist_next]     // noeud suivant
    cbnz x21,1b                  // boucle si pas fini

    affichelib SolutionGlouton
    mov x0,x20                   // adresse de la solution
    bl afficherSolutionDirect
100:
    ldp x21,x22,[sp],16         // restaur des  2 registres
    ldp x20,lr,[sp],16          // restaur des  2 registres
    ret                         // retour adresse lr x30

/******************************************************************/
/*     resoudreDescenteGradient                                        */ 
/******************************************************************/
/* x0 contient l'adresse de de la liste des boites */
resoudreDescenteGradient:                   // INFO: resoudreDescenteGradient
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    affichelib resoudreDescenteGradient
    mov x21,x0                 // save liste des boites
    bl SolutionAleatoire       // création d'une solution aléatoire de départ
    mov x22,x0
    //bl afficherSolutionDirect
    mov x20,0
1:
    mov x0,x21                // liste des boites
    mov x1,x22
    bl creerVoisinage         // x0 contient la liste des solutions voisines
    ldr x10,[x0,llist_taille]
    cbz x10,2f                // aucune solution ?
    bl meilleureSolution
    //bl afficherSolutionDirect
    ldr x1,[x0,llist_valeur]
    ldr x2,[x22,llist_valeur]
    cmp x1,x2
    ble 2f
    mov x22,x0 
    mov x20,0
    b 3f
2:
    add x20,x20,1
3:
    //affregtit bouclegrad 20
    cmp x20,MAXITERSTABLE
    blt 1b                 // boucle
    affichelib SolutionGradient
    mov x0,x22
    bl afficherSolutionDirect
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     resoudreRechercheTaboue                                        */ 
/******************************************************************/
/* x0 contient l'adresse de la structure problème */
resoudreRechercheTaboue:       // INFO: resoudreRechercheTaboue
    stp x20,lr,[sp,-16]!       // save  registres
    stp x21,x22,[sp,-16]!      // save  registres
    stp x23,x24,[sp,-16]!      // save  registres
    affichelib resoudreRechercheTaboue
    mov x21,x0                 // save liste boites
    bl SolutionAleatoire
    //str x0,[x22]
    mov x23,x0                 //  meilleure solution de départ
    bl ajouterListeTaboue
    //bl verifListeTaboue
    mov x20,0
1:
    mov x0,x21                 // liste des boites disponibles
    mov x1,x23
    bl creerVoisinage          // x0 contient la liste des solutions
    mov x24,x0
    bl enleverSolutionsTaboues
    ldr x0,[x24,llist_taille]
    cbz x0,2f
    mov x0,x24
    bl meilleureSolution
    mov x24,x0
    ldr x1,[x24,llist_valeur]
    ldr x2,[x23,llist_valeur]
    cmp x1,x2                       // comparaison des valeurs
    ble 2f                          // solution pas meilleure
    mov x0,x24                      // solution meilleure
    bl rechercherSolutionsTaboues   // est-elle taboue ?
    cbnz x0,2f                      // si trouvée
    mov x0,x24
    bl ajouterListeTaboue           // sinon on l'ajoute à la liste
    mov x23,x24                      // et elle devient la meilleure
    mov x20,0                       // raz du compteur stable
    b 3f
2:
    add x20,x20,1
3:
    cmp x20,MAXITERSTABLE           // maxi stable atteint ?
    blt 1b

    affichelib SolutionTaboue
    mov x0,x23
    bl afficherSolutionDirect
100:
    ldp x23,x24,[sp],16             // restaur des  2 registres
    ldp x21,x22,[sp],16             // restaur des  2 registres
    ldp x20,lr,[sp],16              // restaur des  2 registres
    ret                             // retour adresse lr x30
/******************************************************************/
/*     recuit simulé                                       */ 
/******************************************************************/
/* x0 contient l'adresse de la liste des boites */
resoudreRecuitSimule:          // INFO: resoudreRecuitSimule
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    affichelib resoudreRecuitSimule
    mov x21,x0                 // save liste des boites
    bl SolutionAleatoire       // creation d'une solution de départ
    affichelib verifsolutionAleat
    mov x23,x0                // solution aléatoire de depart
    mov x22,x0                // meilleure solution de départ
    bl afficherSolutionDirect

    mov x25,TEMPDEPART
1:
    mov x20,0
2:
    mov x0,x21                // liste des boites
    mov x1,x23                // solution aléatoire de départ
    bl creerVoisinage         // x0 contient la liste des solutions
    ldr x1,[x0,llist_taille]  // aucune solution ?
    cbz x1,4f
    bl meilleureSolution
    ldr x1,[x0,llist_valeur]
    ldr x2,[x22,llist_valeur] // meilleure ancienne solution
    cmp x1,x2
    beq 4f                    // valeurs solution egales
    blt 3f
    mov x22,x0                // solution meilleure
    mov x23,x0                // solution courante
    mov x20,0                 // et on repars à 0
    b 5f
3:                            //solution moins bonne 
    mov x10,x0
    mov x0,TEMPDEPART*2
    bl genererAlea            // tirage hasard
    cmp x0,x25
    blt 4f                    // si inferieur pas de prise en compte
    mov x23,x10               // on repars de la solution courante 
    mov x0,x10
    bl afficherSolutionDirect
    mov x20,0
    b 5f
4:                           // increment pour boucle
    add x20,x20,1
5:
    cmp x20,MAXITERSTABLE    // max stable ?
    blt 2b                   // boucle 
    //brk 5
    sub x25,x25,1            // baisse de la température
    cbnz x25,1b              // et boucle

    affichelib SolutionRecuit
    mov x0,x22
    bl afficherSolutionDirect
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     resoudre essaims particuliers                              */ 
/******************************************************************/
/* x0 contient l'adresse de la liste des boites */
resoudreEssaimsPart:             // INFO: resoudreEssaimsPart
    stp x20,lr,[sp,-16]!         // save  registres
    stp x21,x22,[sp,-16]!        // save  registres
    stp x23,x24,[sp,-16]!        // save  registres
    affichelib resoudreEssaimsPart
    mov x20,x0                   // save liste des boites
    mov x0,llist_fin             // creation d'une liste des solutions
    bl allocPlace
    cmp x0,-1
    beq 100f
    mov x23,x0                   // adresse de la liste creee
    mov x21,0
1:                    // création d'une liste de solution aléatoires
    mov x0,x20
    bl SolutionAleatoire
    mov x1,0          // ajout de la solution aléatoire à la liste
    mov x2,0
    bl creerNoeud
    mov x1,x0
    mov x0,x23
    bl insertNoeud
    add x21,x21,1
    cmp x21,NBSOLUTIONSESSAIMS  // maxi ?
    blt 1b
    mov x0,x23           // determine la meilleure solution de ce lot
    bl meilleureSolution

    mov x24,x0           // meilleure solution du lot
    mov x25,x0           // meilleure meilleure solution
    mov x21,0
3:                      // boucle d'amélioration
    mov x0,x23
    bl meilleureSolution
    //affichelib retourmeilleuresolution
    //bl afficherSolutionDirect
    mov x24,x0
    ldr x10,[x24,llist_valeur]
    ldr x11,[x25,llist_valeur]
    cmp x10,x11
    ble 4f
    mov x25,x24     // nouvelle meilleure solution
4:
    mov x0,x23
    mov x1,x24
    mov x2,x25
    mov x3,x20
    bl majSolutionEssaims
    add x21,x21,1
    //affregtit Bouclex21 20
    cmp x21,MAXITERESSAIMS
    blt 3b                  // boucle

    affichelib SolutionEssaims
    mov x0,x25
    bl afficherSolutionDirect
100:
    ldp x23,x24,[sp],16          // restaur des  2 registres
    ldp x21,x22,[sp],16          // restaur des  2 registres
    ldp x20,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     creer une solution voisine                                 */ 
/******************************************************************/
/* x0 contient l'adresse de la liste des boites */
/* x1 contient l'adresse d'une solution */
/* x0 retourne l'adresse d'une liste contenant tous les voisins */
creerVoisinage:                   // INFO: creerVoisinage
    stp x20,lr,[sp,-16]!        // save  registres
    stp x21,x22,[sp,-16]!        // save  registres
    stp x23,x24,[sp,-16]!        // save  registres
    stp x25,x26,[sp,-16]!        // save  registres
    stp x27,x28,[sp,-16]!        // save  registres
    //affichelib creerVoisinage
    mov x20,x0       // save liste des boites
    mov x21,x1       // save solution aleatoire de depart

    mov x0,llist_fin // creation d'une liste
    bl allocPlace
    cmp x0,-1
    beq 100f
    mov x22,x0        // adresse de la liste creee
    mov x23,0         // indice
1:
    //affregtit debutvois 20
    mov x0,x21        // copie de la solution aleatoire
    bl copieListe
    mov x24,x0        // adresse copie liste solution
    //affichelib apresCopie
    //mov x0,x24             // liste 
    //bl afficherSolutionDirect
    ldr x0,[x24,llist_taille]
    //sub x0,x0,1
    cbz x0,11f
    bl genererAlea    // choix d'un index
11:
    mov x1,x0
    mov x0,x24
    bl eliminerIndex
    //mov x0,x24             // liste 
    //bl afficherSolutionDirect

    ldr x26,[x24,llist_poids]   // chargement d'un poids
    mov x11,POIDSMAX
    sub x26,x11,x26        // poids restant
    //affregtit poidsrestant 21
    // copier la liste des boites disponibles
    mov x0,x20
    bl copieListe          // xo contient l'adresse de la liste copiee
    mov x25,x0             // liste des boites disponibles
    // il faut eliminer toutes les boites de la solution de cette liste
    mov x1,x24             // liste solution
    bl eliminerBoitesIdentiques
    //mov x0,x25             // liste 
    //bl verifListe
    mov x0,x25             // nouvelle liste des boites disponibles
    mov x1,x26             // poids maxi
    bl EliminerTropLourdes
    // ajout des boites
    ldr x27,[x25,llist_taille]
    //affregtit elimVoisin 0
    //affregtit elimVoisin 24
2:
    cmp x26,0         // poids restant
    ble 5f
    cmp x27,0         // plus de boites 
    ble 5f
    sub x0,x27,0      // tirage index entre 0 et nb boites
    cbz x0,3f
    bl genererAlea
3:
    mov x1,x0          // index à eliminer des boites
    mov x0,x25         // liste des boites
    mov x2,x24         // et liste de la solution à laquelle on ajoute la boite
    bl eliminerIndexAjout
    sub x26,x26,x0        // - le poids trouvé
    sub x27,x27,1         // decrement nb de boites
    mov x0,x25            // liste des boites
    mov x1,x26            // poids restant
    bl EliminerTropLourdes
    b 2b                  // et boucle
5:
                           // insertion solution dans listes des solutions
    mov x0,x24             // pointeur liste dans zone nom
    mov x1,0
    mov x2,0
    bl creerNoeud
    mov x1,x0
    mov x0,x22
    bl insertNoeud
    add x23,x23,1
    cmp x23,NBVOISINS
    blt 1b
    str x23,[x22,llist_taille]
    
    mov x0,x22             // retourne le pointeur de la liste des solutions

100:
    ldp x27,x28,[sp],16          // restaur des  2 registres
    ldp x25,x26,[sp],16          // restaur des  2 registres
    ldp x23,x24,[sp],16          // restaur des  2 registre
    ldp x21,x22,[sp],16          // restaur des  2 registre
    ldp x20,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     Solution aléatoire                                         */ 
/******************************************************************/
/* x0 contient l'adresse de la liste des boites */ 
SolutionAleatoire:                   // INFO: SolutionAleatoire
    stp x26,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    stp x20,x21,[sp,-16]!        // save  registres
    stp x22,x23,[sp,-16]!        // save  registres
    stp x24,x25,[sp,-16]!        // save  registres
    //affichelib SolutionAleatoire
    mov x10,x0
    mov x0,llist_fin            // creation d'une liste solution
    bl allocPlace
    cmp x0,-1
    beq 100f
    mov x22,x0                  // adresse de la liste creee
                                // copier la liste des boites disponibles
    mov x0,x10
    bl copieListe               // xo contient l'adresse de la liste copiee
    mov x20,x0
    mov x1,POIDSMAX
    mov x21,x1
    bl EliminerTropLourdes
    //mov x0,x20
    //bl verifListe
    ldr x24,[x20,llist_taille]   // TODO: remplacer par x23
    //affregtit elim 0
1:
    //ldr x24,[x20,llist_taille]
    cmp x21,0
    ble 5f
    cmp x24,0
    ble 5f
    sub x0,x24,1
    cbz x0,2f
    bl genererAlea
2:
    mov x1,x0
    mov x0,x20
    mov x2,x22
    bl eliminerIndexAjout
    sub x21,x21,x0        // - le poids trouvé
    sub x24,x24,1
    mov x0,x20
    mov x1,x21
    bl EliminerTropLourdes
    b 1b
5:
    //affichelib solutionaleatoire
    mov x0,x22                  // retourne l'adresse de la liste
    //bl afficherSolutionDirect
100:
    ldp x24,x25,[sp],16          // restaur des  2 registres
    ldp x22,x23,[sp],16          // restaur des  2 registres
    ldp x20,x21,[sp],16          // restaur des  2 registres
    ldp x1,x2,[sp],16            // restaur des  2 registres
    ldp x26,lr,[sp],16           // restaur des  2 registres
    ret                          // retour adresse lr x30
/******************************************************************/
/*      EliminerTropLourdes                                              */ 
/******************************************************************/
/* x0 contient la liste des boites */
/* x1 contient le poids maxi */
EliminerTropLourdes:                   // INFO: EliminerTropLourdes
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x5,x6,[sp,-16]!        // save  registres
    //affichelib EliminerTropLourdes
    mov x2,x0
    mov x6,x0
    ldr x5,[x0,llist_taille]
    //il faut balayer la liste des boites
    ldr x2,[x2,llist_next]    // liste vide ?
    cbz x2,100f                // oui
    //affregtit ETL 0
1:
    ldr x3,[x2,llist_poids] //recup poids
    //affregtit comparpoids 0
    cmp x3,x1
    //ldr x4,[x2,llist_next]
    ble 2f
    mov x4,x0
    bl suppressionNoeud     // x0 contient le noeud precedent
    sub x5,x5,1
    mov x2,x4
2:
    mov x0,x2
    ldr x2,[x2,llist_next]
    cbnz x2,1b
    str x5,[x6,llist_taille]
100:
    ldp x5,x6,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     ajout d'une solution à la liste taboue                     */ 
/******************************************************************/
/* x0 contient la liste d'une solution */
ajouterListeTaboue:                   // INFO: ajouterListeTaboue
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    affichelib ajouterListeTaboue
    mov x10,x0
    ldr x11,qAdrstListeTaboue
    ldr x2,[x11,llist_taille]
    cmp x2,MAXPOSTABOUE        // si limite atteinte, suppression d'un noeud
    blt 2f
1:                          // boucle de balayage des noeuds
    mov x3,x2
    ldr x2,[x2,llist_next]  // cherche dernier noeud
    cbnz x2,1b
    mov x0,x3
    bl suppressionNoeud
    sub x2,x2,1
2:
    mov x0,x10
    mov x1,0
    mov x2,0
    bl creerNoeud
    mov x1,x0
    mov x0,x11
    bl insertNoeud
    add x2,x2,1
    str x2,[x11,llist_taille]
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrstListeTaboue:       .quad stListeTaboue
/******************************************************************/
/*     suppression des solutions taboues de la liste des voisinage */ 
/******************************************************************/
/* x0 contient la liste des solutions voisines */
enleverSolutionsTaboues:                   // INFO: enleverSolutionsTaboues
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    //affichelib enleverSolutionsTaboues
    mov x10,x0                 // save liste voisins
    ldr x11,qAdrstListeTaboue
    ldr x2,[x10,llist_taille]  // taille liste départ
                               // balayage des solutions taboues
    ldr x12,[x11,llist_next]
    cbz x12,100f               // liste taboue vide
1:
    ldr x13,[x12,llist_nom]    // contient l'adresse d'une solution
    ldr x14,[x10,llist_next]
    mov x1,x10                 // adresse noeud precedent
    //affregtit boucle1 10
2:                             // pour chaque taboue balayer la table des voisins
    cbz x14,4f                 // plus de solutions
    //affregtit comparSolutions 10
    cmp x14,x13
    bne 3f
    mov x0,x1             // si egalité supprimer le noeud
    bl suppressionNoeud
    sub x2,x2,1
    
    b 4f
3:
    mov x1,x14
    ldr x14,[x14,llist_next]
    b 2b
4:
    ldr x12,[x12,llist_next]
    //affregtit finboucle 10
    cbnz x12,1b
    str x2,[x10,llist_taille]      // mettre à jour la taille
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     suppression des solutions taboues de la liste des voisinage */ 
/******************************************************************/
/* x0 contient l'adresse de la liste à rechercher */
/* x0 retourne 0 ou 1 si trouvée */
rechercherSolutionsTaboues:                   // INFO: rechercherSolutionsTaboues
    stp x3,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    affichelib rechercherSolutionsTaboues
    mov x10,x0                 // save liste voisins
    ldr x11,qAdrstListeTaboue
    // balayage des solutions taboues
    ldr x12,[x11,llist_next]
    cbz x12,100f        // liste taboue vide
1:
    ldr x13,[x12,llist_nom]
    cmp x13,x0
    beq 2f
    ldr x12,[x12,llist_next]
    cbnz x12,1b
    mov x0,0
    b 100f
2:
    mov x0,1              // trouvée
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x3,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     eliminer un noeud en fonction de son rang                  */ 
/*     et l'ajouter à la liste solution                           */
/******************************************************************/
/* x0 contient la liste des boites */
/* x1 contient l'index à supprimer */
/* x2 contient la liste solution  */
eliminerIndexAjout:                   // INFO: eliminerIndexAjout
    stp x7,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x5,x6,[sp,-16]!        // save  registres
    //affichelib eliminerIndexAjout
    mov x6,x0                  // listes des boites possibles
    ldr x5,[x0,llist_taille]
    //il faut balayer la liste des boites
    ldr x4,[x0,llist_next]    // liste vide ?
    cbz x4,100f                // oui
    //affregtit ELIMindex 0
    mov x3,0
1:
    cmp x3,x1
    blt 2f
    mov x7,x0  // save x0
    mov x0,x4
    mov x1,x2
    bl copieNoeud 
    mov x1,x0   // save poids trouvé
    mov x0,x7   //restaur x0
    bl suppressionNoeud     // x0 contient le noeud precedent
    sub x5,x5,1
    str x5,[x6,llist_taille]
    //affregtit suitesupp 0
    mov x0,x1    // retour du poids trouvé
    b 100f
2:
    add x3,x3,1
    mov x0,x4
    ldr x4,[x4,llist_next]
    cbnz x4,1b
   
100:
    ldp x5,x6,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x7,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     eliminer un noeud en fonction de son rang                  */ 
/******************************************************************/
/* x0 contient la liste des boites */
/* x1 contient l'index à supprimer */
eliminerIndex:                   // INFO: eliminerIndex
    stp x5,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    //affichelib eliminerIndex
    mov x5,x0
    //il faut balayer la liste des boites
    ldr x4,[x0,llist_next]    // liste vide ?
    cbz x4,100f                // oui
    //affregtit ELIMindex 0
    mov x3,0
1:
    //affregtit eliminindex1 0
    cmp x3,x1
    blt 2f
    ldr x10,[x5,llist_taille]
    sub x10,x10,1
    str x10,[x5,llist_taille]
    ldr x10,[x5,llist_poids]
    ldr x11,[x4,llist_poids]
    sub x10,x10,x11
    str x10,[x5,llist_poids]
    ldr x10,[x5,llist_valeur]
    ldr x11,[x4,llist_valeur]
    sub x10,x10,x11
    str x10,[x5,llist_valeur]

    bl suppressionNoeud     // x0 contient le noeud precedent
    b 100f
2:
    add x3,x3,1
    mov x0,x4
    ldr x4,[x4,llist_next]
    cbnz x4,1b
    
100:
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x5,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     Eliminer d'une liste les boites identiques à une autre liste */ 
/******************************************************************/
/* x0 contient l'adresse de la liste à modifier */
/* x1 contient l'adresse de la liste guide */
eliminerBoitesIdentiques:                   // INFO: eliminerBoitesIdentiques
    stp x0,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x20,x21,[sp,-16]!        // save  registres
    //affichelib eliminerBoitesIdentiques
    mov x20,x0
    mov x21,x1
    ldr x4,[x0,llist_next]    // liste vide ?
    cbz x4,100f                // oui
    ldr x5,[x1,llist_next]    // liste vide ?
    cbz x5,100f                // oui
1:
    ldr x11,[x5,llist_nom]
    ldr x4,[x20,llist_next]    // debut liste
    mov x3,x20                // save adresse noeud
2:
    ldr x12,[x4,llist_nom]
    cmp x11,x12
    bne 3f
    // egalité il faut supprimer le noeud et mettre à jour les compteurs
    ldr x10,[x20,llist_taille]
    sub x10,x10,1
    str x10,[x20,llist_taille]
    ldr x10,[x20,llist_poids]
    ldr x11,[x4,llist_poids]
    sub x10,x10,x11
    str x10,[x20,llist_poids]
    ldr x10,[x20,llist_valeur]
    ldr x11,[x4,llist_valeur]
    sub x10,x10,x11
    str x10,[x20,llist_valeur]

    mov x0,x3
    bl suppressionNoeud
    b 4f
3:
    mov x3,x4
    ldr x4,[x4,llist_next] 
    cbnz x4,2b      // boucle
4:
    ldr x5,[x5,llist_next]    // boite suivante liste guide
    cbnz x5,1b     // fin

100:
    ldp x20,x21,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     maj solutions essaims particulaires                        */ 
/******************************************************************/
/* x0 contient l'adresse de la liste des solutions */
/* x1 contient l'adresse de la meilleure solution  */
/* x2 contient l'adresse de la meilleure actuelle */
/* x3 contient l'adresse de la liste des boites */
majSolutionEssaims:              // INFO: majSolutionEssaims
    stp x20,lr,[sp,-16]!         // save  registres
    stp x21,x22,[sp,-16]!        // save  registres
    stp x23,x24,[sp,-16]!        // save  registres
    //affichelib majSolutionEssaims
    mov x20,x0
    mov x21,x1               // meilleure solution
    mov x22,x2               // meilleure solution
    ldr x24,[x20,llist_next]
    cbnz x24,1f             // liste non vide
    ldr x0,qAdrszMessPasdesolution
    bl affichageMess
    b 100f
1:
    //affregtit examSolution 20
    ldr x23,[x24,llist_nom]
    cmp x23,x21
    beq 10f
    mov x0,x23
    mov x1,x21
    bl ajoutBoite
    mov x0,x23
    mov x1,x22
    bl ajoutBoite
    //mov x0,x23
    //affmemtit solutionAjou x0 4
2:
    ldr x15,[x23,llist_poids]
    cmp x15,POIDSMAX
    ble 3f
    ldr x0,[x23,llist_taille]
    bl genererAlea
    mov x1,x0
    mov x0,x23
    bl eliminerIndex
    b 2b
3:                  // Completer  la solution
    mov x0,x3
    mov x1,x23
    bl completerSolution
    //affregtit finsolutionessaim 0
10:
    ldr x24,[x24,llist_next]
    //affregtit boucleessaim 20
    cbnz x24,1b

12:
   // mov x0,x12     // retourne la meilleure solution trouvée
    //affregtit finmeilleure 0
    //bl afficherSolution
100:
    ldp x23,x24,[sp],16          // restaur des  2 registres
    ldp x21,x22,[sp],16          // restaur des  2 registres
    ldp x20,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     ajout boite d'une solution meilleure                      */ 
/******************************************************************/
/* x0 contient l'adresse de la solution courante*/
/* x1 contient l'adresse  d'une des meilleures solutions  */
ajoutBoite:                   // INFO: ajoutBoite
    stp x20,lr,[sp,-16]!        // save  registres
    stp x21,x22,[sp,-16]!        // save  registres
    stp x23,x24,[sp,-16]!        // save  registres
    //affichelib ajoutBoite
    mov x20,x0
    mov x21,x1
    ldr x22,[x21,llist_taille]
    mov x0,x22                //TODO:  amemiorer ces registres
    bl genererAlea
    ldr x24,[x21,llist_next]
    cbz x24,100f
    mov x23,0
1:
    cmp x23,x0
    blt 2f
    //il faut verifier que la boite trouvée n'est pas déjà dans la liste
    mov x0,x24
    mov x1,x20
    bl rechercherBoite
    cbnz x0,100f         // boite dans la liste
    
    mov x0,x24
    mov x1,x20
    bl copieNoeud 
    b 100f
2:
    add x23,x23,1
    ldr x24,[x24,llist_next]
    cbnz x24,1b

100:
    ldp x23,x24,[sp],16          // restaur des  2 registres
    ldp x21,x22,[sp],16          // restaur des  2 registres
    ldp x20,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     Completer une solution  avec des boites                    */ 
/******************************************************************/
/* x0 contient l'adresse de la liste des boites */ 
/* x1 contient la solution à completer */
completerSolution:               // INFO: completerSolution
    stp x0,lr,[sp,-16]!          // save  registres
    stp x1,x2,[sp,-16]!          // save  registres
    stp x20,x21,[sp,-16]!        // save  registres
    stp x22,x23,[sp,-16]!        // save  registres
    stp x24,x25,[sp,-16]!        // save  registres
    //affichelib completerSolution
    mov x23,x0                   // save liste des boites TODO: registre 23
    mov x22,x1
   // mov x0,x1
    //bl afficherSolutionDirect
    mov x0,x23                   // copier la liste des boites disponibles
    bl copieListe                // xo contient l'adresse de la liste copiee
    mov x20,x0
    mov x1,x22                   // enlever les boites de la liste
    bl eliminerBoitesIdentiques
    mov x1,POIDSMAX
    ldr x2,[x22,llist_poids]
    sub x1,x1,x2           // calcul du poids à completer 
    mov x21,x1
    bl EliminerTropLourdes
    //mov x0,x20
    //bl verifListe
    ldr x24,[x20,llist_taille]
    //affregtit elim 0
1:
    //ldr x24,[x20,llist_taille]
    cmp x21,0             // poids à completer
    ble 5f
    cmp x24,0             // nombre de boites
    ble 5f
    mov x0,x24            // taille
    cbz x0,2f
    bl genererAlea
2:
    mov x1,x0
    mov x0,x20
    mov x2,x22
    bl eliminerIndexAjout
    sub x21,x21,x0        // - le poids trouvé
    sub x24,x24,1
    mov x0,x20
    mov x1,x21
    bl EliminerTropLourdes
    b 1b
5:
    // verifier la solution 
    //affichelib ajoutsolution
    mov x0,x22
    //bl afficherSolutionDirect
    //ldr x2,[x22,llist_taille]
100:
    ldp x24,x25,[sp],16          // restaur des  2 registres
    ldp x22,x23,[sp],16          // restaur des  2 registres
    ldp x20,x21,[sp],16          // restaur des  2 registres
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     rechercher meilleure solution                              */ 
/******************************************************************/
/* x0 contient l'adresse du noeud */
/* x1 contient la liste */
rechercherBoite:                   // INFO: rechercherBoite
    stp x20,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    //affichelib rechercherBoite
    mov x20,x0
    ldr x0,[x1,llist_next]
    cbnz x0,100f
    ldr x1,[x20,llist_nom]
1:
    ldr x3,[x0,llist_nom]
    cmp x2,x1
    beq 2f
    ldr x0,[x0,llist_next]
    cbnz x0,1b
    mov x0,0
    b 100f          // non trouvée
2:
    mov x0,1
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x20,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     rechercher meilleure solution                              */ 
/******************************************************************/
/* x0 contient l'adresse de la liste des solutions */
meilleureSolution:                   // INFO: meilleureSolution
    stp x20,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    //affichelib meilleureSolution
    mov x20,x0
    mov x1,0               // compteur solutions
    ldr x11,[x20,llist_next]
    cbnz x11,1f             // liste non vide
    ldr x0,qAdrszMessPasdesolution
    bl affichageMess
    b 100f
1:
    ldr x12,[x11,llist_nom]        // 1ere solution = meilleure
    ldr x14,[x12,llist_valeur]     // meilleure valeur
    //affregtit debsol 10
    ldr x13,[x12,llist_next]
    cbnz x13,2f             // liste non vide
    affichelib ErreurPremiereSolution
    ldr x0,qAdrszMessPasdesolution
    bl affichageMess
    b 100f
2:
    //affregtit examSolution 10
    ldr x11,[x11,llist_next]
    cbz x11,4f
    ldr x13,[x11,llist_nom]
    mov x0,x12
    ldr x15,[x13,llist_valeur]
    cmp x15,x14
    ble 3f
    ldr x12,[x11,llist_nom]
    mov x14,x15
3:
    add x1,x1,1
    b 2b
4:
    //affregtit Nombredesolutionsdansx1 0
    mov x0,x12     // retourne la meilleure solution trouvée
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x20,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

/******************************************************************/
/*     affichage d'une solution directement                                  */ 
/******************************************************************/
/* x0 contient l'adresse de la solution */
afficherSolutionDirect:                   // INFO: afficherSolutionDirect
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    //affichelib afficherSolutionDirect
    mov x10,x0
    ldr x0,[x10,llist_valeur]
    ldr x1,qAdrsZoneConv
    bl conversion10
    ldr x0,qAdrszMessSolution
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    mov x16,x0
    ldr x0,[x10,llist_poids]
    ldr x1,qAdrsZoneConv
    bl conversion10
    mov x0,x16
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    mov x16,x0
    ldr x0,[x10,llist_taille]
    ldr x1,qAdrsZoneConv
    bl conversion10
    mov x0,x16
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    bl affichageMess
    ldr x11,[x10,llist_next]
    cbnz x11,1f             // liste vide
    ldr x0,qAdrszMessPasdesolution
    bl affichageMess
    b 100f
1:
    ldr x0,[x11,llist_nom ]            // affichage nom
    bl affichageMess
    ldr x0,[x11,llist_poids]   // affichage poids
    ldr x1,qAdrsZoneConv
    bl conversion10
    ldr x0,qAdrszMessBoite
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    mov x16,x0
    ldr x0,[x11,llist_valeur]   // affichage valeur
    ldr x1,qAdrsZoneConv
    bl conversion10
    mov x0,x16
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    mov x16,x0
    ldr x0,[x11,llist_ratio]   // affichage ratio
    ldr x1,qAdrsZoneConv
    bl conversion10
    mov x0,x16
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    //mov x16,x0
    bl affichageMess
    ldr x11,[x11,llist_next]
    cbnz x11,1b
    ldr x0,qAdrszRetourLigne
    bl affichageMess
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszMessPasdesolution:   .quad szMessPasdesolution
qAdrszMessSolution:        .quad szMessSolution
/******************************************************************/
/*     afficher une boite                                         */ 
/******************************************************************/
/* x0 contient l'adresse d'une boite */
afficherBoite:                 // INFO: afficherBoite
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    affichelib afficherBoite
    mov x10,x0
    ldr x0,[x10,boite_nom]     // affichage nom
    ldr x0,[x0]
    bl affichageMess
    ldr x0,[x10,boite_poids]   // affichage poids
    ldr x1,qAdrsZoneConv
    bl conversion10
    ldr x0,qAdrszMessBoite
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    mov x15,x0
    ldr x0,[x10,boite_valeur]   // affichage valeur
    ldr x1,qAdrsZoneConv
    bl conversion10
    mov x0,x15
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    mov x15,x0
    bl affichageMess
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszMessBoite:         .quad szMessBoite
/******************************************************************/
/*     creation noeud                                             */ 
/******************************************************************/
/* x0 contient l'adresse du nom   */
/* x1 contient le poids      */
/* x2 contient la valeur     */
/* x0 retourne l'adresse du noeud sur le tas */
creerNoeud:                    // INFO: creerNoeud
    stp x3,lr,[sp,-16]!        // save  registres
    mov x3,x0
    mov x0,llist_fin
    bl allocPlace
    cmp x0,-1
    beq 100f
    str x3,[x0,llist_nom]
    str x1,[x0,llist_poids]
    str x2,[x0,llist_valeur]
    // calcul du ratio
    mov x3,MULTIRATIO
    mul x3,x3,x2
    udiv x3,x3,x1
    str x3,[x0,llist_ratio]
    str xzr,[x0,llist_next]
    //affregtit creat 0
100:
    ldp x3,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     insert Noeud dans liste                                    */ 
/******************************************************************/
/* x0 contient l'adresse du noeud apres lequel il faut inserer */
/* x1 contient l'adresse du noeud à inserer */
insertNoeud:                   // INFO: insertNoeud
    stp x2,lr,[sp,-16]!        // save  registres
    ldr x2,[x0,llist_next]
    str x2,[x1,llist_next]
    str x1,[x0,llist_next]
    //affregtit insert 0
100:
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     Copie d'un noeud d'une liste dans une autre                */ 
/******************************************************************/
/* x0 contient l'adresse du noeud */
/* x1 contient l'adresse de la liste receptrice */
/* x0 retourne le poids trouvé */
copieNoeud:                   // INFO: copieNoeud
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    //affichelib copieNoeud
    mov x10,x0
    mov x11,x1
    ldr x12,[x11,llist_taille]
    add x12,x12,1
    str x12,[x11,llist_taille]
    ldr x0,[x10,llist_nom]
    ldr x1,[x10,llist_poids]
    ldr x12,[x11,llist_poids]
    add x12,x12,x1
    str x12,[x11,llist_poids]
    mov x3,x1               // save du poids
    ldr x2,[x10,llist_valeur]
    ldr x12,[x11,llist_valeur]
    add x12,x12,x2
    str x12,[x11,llist_valeur]
    bl creerNoeud
    mov x1,x0
    mov x0,x11
    bl insertNoeud
    mov x0,x3
100:
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     copieListe                                               */ 
/******************************************************************/
/* x0 contient l'adresse du debut de liste */
/* x0 retourne l'adresse de debut de la nouvelle liste */
copieListe:                   // INFO: copieListe
    stp x1,lr,[sp,-16]!       // save  registres
    stp x2,x3,[sp,-16]!       // save  registres
    stp x4,x5,[sp,-16]!       // save  registres
    mov x5,x0                 // save addresse
    mov x0,0
    mov x1,0
    bl creerNoeud             // création entête nouvelle liste
    mov x3,x0                 // tête nouvelle liste
    mov x4,x0
    ldr x6,[x5,llist_taille]
    str x6,[x3,llist_taille]
    ldr x6,[x5,llist_poids]
    str x6,[x3,llist_poids]
    ldr x6,[x5,llist_valeur]
    str x6,[x3,llist_valeur]
    ldr x5,[x5,llist_next]    // liste vide ?
    cbnz x5,1f                // non
    mov x0,x3                 // retourne le noeud vide
    b 100f
1:
    ldr x0,[x5,llist_nom]   // recup valeur
    ldr x1,[x5,llist_poids]
    ldr x2,[x5,llist_valeur]
    bl creerNoeud
    mov x1,x0                // adresse du noeud crée
    mov x0,x4                // insertion après le noeud précedent
    mov x4,x1                // et on garde l'adresse du dernier noeud crée
    bl insertNoeud
    ldr x5,[x5,llist_next]
    cbnz x5,1b
    mov x0,x3                // retourne la tête de liste

100:
    ldp x4,x5,[sp],16        // restaur des  2 registres
    ldp x2,x3,[sp],16        // restaur des  2 registres
    ldp x1,lr,[sp],16        // restaur des  2 registres
    ret
/******************************************************************/
/*     suppression d'un noeud après un autre                      */ 
/******************************************************************/
/* x0 contient l'adresse du noeud après lequel il faut supprimer */
suppressionNoeud:              // INFO: suppressionNoeud
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    //affichelib suppressionNoeud
    ldr x1,[x0,llist_next]
    ldr x2,[x1,llist_next]
    str x2,[x0,llist_next]
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     triListe suivant le ratio                                  */ 
/******************************************************************/
/* x0 contient l'adresse du debut de liste */
triListe:                     // INFO: triListe
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
    ldr x3,[x1,llist_ratio]   // valeur du noeud à insérer
    ldr x2,[x1,llist_next]    // noeud suivant
    ldr x4,[x5,llist_next]    // premier noeud nouvelle liste
    mov x6,x4
    cbz x4,3f                 // liste vide ?
    mov x0,x5                 // tete nouvelle liste dans noeud precedent
2:
    ldr x7,[x4,llist_ratio]   // valeur du noeud 
    cmp x7,x3                 // valeur du noeud < valeur à inserer
    blt 3f

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
/*     suppression d'un noeud après un autre                      */ 
/******************************************************************/
/* x0 contient l'adresse du noeud après lequel il faut supprimer */
verifListeTaboue:              // INFO: verifListeTaboue
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    affichelib veriflisteTaboue
    ldr x1,qAdrstListeTaboue
    ldr x2,[x1,llist_taille]  // taille liste départ
    // balayage des solutions taboues
    ldr x1,[x1,llist_next]
    cbz x1,100f        // liste taboue vide
1:
    ldr x3,[x1,llist_nom]
    affregtit verifTaboue 0
    ldr x1,[x1,llist_next]
    cbnz x1,1b        // liste taboue vide
100:
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     verification d'une liste                                   */ 
/******************************************************************/
/* x0 contient l'adresse de debut de la liste */
verifListe:                   // INFO: verifListe
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    affichelib verifListe
    ldr x15,[x0,llist_next]
    cbz x15,100f             // liste vide
1:
    ldr x0,[x15,llist_nom]
    bl affichageMess
    ldr x0,qAdrszRetourLigne
    bl affichageMess
    ldr x15,[x15,llist_next]
    cbnz x15,1b
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     générateur aléatoire                                     */ 
/******************************************************************/
/* x0 contient la valeur maxi */
genererAlea:                   // INFO: genererAlea
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    //affichelib genererAlea
    mov x3,x0                  // save maxi
    ldr x0,qAdrqZoneRec        // zone receptrice
    mov x1,8                   // longueur
    mov x2,0
    mov x8,278
    svc 0                      // appel systeme urandom
    ldr x0,qAdrqZoneRec
    ldr x0,[x0]
    udiv x1,x0,x3
    msub x0,x1,x3,x0
100:
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrqZoneRec:     .quad qZoneRec
