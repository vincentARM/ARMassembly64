/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* Probleme Voyageur de commerce algorithmes génétiques asm 64 bits  */
/* PVC */

/************************************/
/* Constantes                       */ 
/************************************/
.include "../constantesARM64.inc"
.equ NBIND,   20          // nombre d'individu
.equ MAXGENE,  50         // Nombre maxi de génération
/* parametre pour le PVC */
.equ MINFITNESS,   2579
.equ MULTI,  10          // multiplicateur
.equ TAUXMUT, 4          // remarque 0,4 * 10
.equ TAUXAJOUTGEN,  2
.equ TAUXSUPPGEN, 1
.equ TAUXCROSSOVER, 0

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*******************************************/
/* Structures                               */
/********************************************/
/* example structure  individus */
    .struct  0
ind_fitness:                      // valeur
    .struct  ind_fitness + 8 
ind_genome:                       // pointeur vers génome
    .struct  ind_genome + 8 
ind_probleme:                     // pointeur vers suivant
    .struct  ind_probleme + 8 
ind_fin:
/* example structure processus */
    .struct  0
proc_population:                 // pointeur vers individu
    .struct  proc_population + 8 
proc_population_next:            // pointeur vers individu suivant
    .struct  proc_population + 8 
proc_nbGeneration:
    .struct proc_nbGeneration + 8
proc_meilleureFitness:
    .struct proc_meilleureFitness + 8
proc_probleme:
    .struct proc_probleme + 8    // type de problème (Non utile)
proc_fin:
/* structure liste chainée */
//    .struct  0
//llist_next:                            // next element
//    .struct  llist_next + 8
//llist_value:                           // element value
//    .struct  llist_value + 8
//llist_fin:
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
szMessInd:               .asciz "(@)"
szMessGeneration:        .asciz "@ -> "
szMessBlancs:            .asciz " "
/* table des villes  */
szParis:        .asciz "Paris"
szLyon:         .asciz "Lyon"
szMarseille:    .asciz "Marseille"
szNantes:       .asciz "Nantes"
szBordeaux:     .asciz "Bordeaux"
szToulouse:     .asciz "Toulouse"
szLille:        .asciz "Lille"
/* table des pointeurs de ville */
tbNomVille:     .quad szParis
                .quad szLyon
                .quad szMarseille
                .quad szNantes
                .quad szBordeaux
                .quad szToulouse
                .quad szLille
                .equ NBVILLES, (. - tbNomVille) / 8
/* table des distances */
tbDistance:     .quad 0,462,772,379,546,678,215
                .equ NBDISTANCES,  (. - tbDistance) / 8
                .quad 462,0,326,598,842,506,664
                .quad 772,326,0,909,555,407,1005
                .quad 379,598,909,0,338,540,584
                .quad 546,842,555,338,0,250,792
                .quad 678,506,407,540,250,0,926
                .quad 215,664,1005,584,792,926,0
/* L'index de la ville correspond à un géne */
.equ NBGENOME,    NBVILLES
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
sZoneConv:          .skip 24
stProcEvol:         .skip proc_fin        // structure processus évolutionnaire
tbPopulation:       .skip ind_fin * NBIND // table population
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    affichelib Problème_voyageur_commerce
                                // creation processus
    ldr x0,qAdrstProcEvol
    bl creationProc
                                // lancement processus
    ldr x0,qAdrstProcEvol
    mov x1,1                    // type de problème =PVC mais inutile ici
    bl execProc

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
qAdrstProcEvol:          .quad stProcEvol

/******************************************************************/
/*     execution du processus                                               */ 
/******************************************************************/
/* x0 contient l'adresse de la structure processus */
execProc:                         // INFO: execProc
    stp x20,lr,[sp,-16]!          // save  registres
    stp x21,x22,[sp,-16]!         // save  registres
    stp x23,x24,[sp,-16]!         // save  registres
    stp x25,x26,[sp,-16]!         // save  registres
    stp x27,x28,[sp,-16]!         // save  registres
    //affichelib execProc
    /* pas d'initialisation pour PVC*/
    mov x28,x0                     // save de la structure processus
    mov x20,MINFITNESS + 1         // meilleure Fitness
    mov x21,0                      // generation
1:                                 // debut boucle génération
    mov x25,ind_fin                // taille d'un poste individu
    ldr x26,[x28,proc_population]  // table de la generation
    mov x23,x26                    // meilleur individu = individu 0
    mov x24,0
    //mov x0,x26                   // si necessaire pour controle
    //bl afficherPop               // affichage population à chaque génération
2:
    madd x0,x24,x25,x26           // calcul adresse individu à traiter
    bl evaluerInd
    ldr x11,[x0,ind_fitness]      // attention x0 ne doit pas changer
    ldr x12,[x23,ind_fitness]     // fitness du meilleur individu
    cmp x11,x12
    csel x23,x0,x23,lt            // nouveau meilleur individu
    add x24,x24,1                 // individu suivant
    cmp x24,NBIND                 // maxi ?
    blt 2b
    // affichage
    mov x0,x23                    // meilleur individu
    mov x1,x21                    // génération
    bl afficherMeilleur
    ldr x20,[x23,ind_fitness]     // nouvelle meilleure fitness
                                  // il faut creer une nouvelle table
    mov x0,ind_fin * NBIND
    bl allocPlace
    mov x25,x0                    // adresse nouvelle table sur le tas
    mov x1,0                      // indice stockage
    mov x2,x23                    // adresse individu
    bl copieIndividu
                                  // création nelle population
    mov x22,1
3:                                // boucle de création nouvelle population
    mov x0,MULTI -1
    bl genererAlea
    cmp x0,TAUXCROSSOVER
    bgt 4f
                                  // avec crossover donc 2 parents
    mov x0,x28                    // adresse structure processus
    bl procSelection
    mov x24,x0                    // save parent 1
    mov x0,x28
    bl procSelection
    mov x13,x0                    // save parent 2
    mov x0,x25                    // table nouvelle population
    mov x1,x22                    // indice
    ldr x2,[x28,proc_probleme]
    mov x3,x24
    mov x4,x13
    bl fiCreerIndividu2parents
    b 5f
4:                               // sans crossover donc 1 parent
    mov x0,x28
    bl procSelection
    mov x12,x0
    mov x0,x25                   // table nouvelle population
    mov x1,x22                   // indice
    ldr x2,[x28,proc_probleme]
    mov x3,x12
    bl fiCreerIndividu1parent
5:
    add x22,x22,1
    cmp x22,NBIND
    blt 3b
    str x25,[x28,proc_population] // survie nouvelle population

    add x21,x21,1                // increment generation
    cmp x21,MAXGENE              // maxi ?
    bge 100f
    cmp x20,MINFITNESS           // objectif atteint ?
    bgt 1b                       // non -> boucle
100:
    ldp x27,x28,[sp],16          // restaur des  2 registres
    ldp x25,x26,[sp],16          // restaur des  2 registres
    ldp x23,x24,[sp],16          // restaur des  2 registres
    ldp x21,x22,[sp],16          // restaur des  2 registres
    ldp x20,lr,[sp],16           // restaur des  2 registres
    ret                          // retour adresse lr x30
/******************************************************************/
/*     routine copie individu                                     */ 
/******************************************************************/
/* x0 contient l'adresse de la table population */
/* x1 contient l'indice */
/* x2 contient l'adresse individu origine */
copieIndividu:                 // INFO: copieIndividu
    stp x0,lr,[sp,-16]!        // save  registres
    //affichelib copieindividu
    mov x18,ind_fin
    madd x18,x1,x18,x0         // calcul de l'adresse dans la table
    mov x17,0
1:
    ldrb w16,[x2,x17]
    strb w16,[x18,x17]
    add x17,x17,1
    cmp x17,ind_fin
    blt 1b

100:
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

/******************************************************************/
/*     routine muter individu                                     */ 
/******************************************************************/
/* x0 contient l'adresse de la structure individu */
muterIndPVC:                   // INFO: muterIndPVC
    stp x0,lr,[sp,-16]!        // save  registres
    //affichelib muterind
    mov x10,x0                 // save structure
    mov x0,MULTI
    bl genererAlea
    cmp x0,TAUXMUT
    bge 100f                   // pas de mutation
    mov x0,NBGENOME-1
    bl genererAlea
    mov x11,x0
    mov x0,NBGENOME-1
    bl genererAlea
    mov x12,x0
    ldr x13,[x10,ind_genome]   // table du genome de l'individu
    ldr x14,[x13,x11,lsl 3]    // inversion de 2 genes
    ldr x15,[x13,x12,lsl 3]
    str x15,[x13,x11,lsl 3]
    str x14,[x13,x12,lsl 3]
  
100:
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     routine evaluer individu  PVC                                   */ 
/******************************************************************/
/* x0 contient l'adresse de la structure individu */
/* x0 conserve cette adresse */
evaluerInd:                    // INFO: evaluerInd
    stp x0,lr,[sp,-16]!        // save  registres
    //affichelib evaluerind
    //affregtit evaluer0 0
    mov x17,x0  
    mov x11,0                 // distance totale
    mov x12,0                 // index prec
    ldr x13,[x0,ind_genome]
    //affregtit evaluer1 11
    ldr x0,[x13]              // premier index
    mov x16,x0                // pour calculer dernière ville premiere ville
    mov x15,1
1:
   //affregtit eval 11
    ldr x1,[x13,x15,lsl 3]
   //affregtit eval1 0
    bl calDistance
    add x11,x11,x0
    mov x0,x1
    add x15,x15,1
   //affregtit eval2 11
    cmp x15,NBGENOME
    blt 1b
    mov x0,x16                 // calcul boucle finale
    bl calDistance
    add x11,x11,x0
    str x11,[x17,ind_fitness]  // stockage résultat

100:
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     routine afficher individu                                     */ 
/******************************************************************/
/* x0 contient l'adresse de la structure individu */
afficherInd:                   // INFO: afficherInd
    stp x0,lr,[sp,-16]!        // save  registres
    //affichelib afficherind
    mov x10,x0
    ldr x0,[x10,ind_fitness]   // affichage fitness
    ldr x1,qAdrsZoneConv
    bl conversion10S
    ldr x0,qAdrszMessInd
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    bl affichageMess
    ldr x11,[x10,ind_genome]   // pointeur table genome
    ldr x14,qAdrtbNomVille
    mov x12,0
1:                             // boucle d'affichage du genome
    ldr x13,[x11,x12,lsl 3]    // recupération de l'index
    ldr x0,[x14,x13,lsl 3]     // puis recup adresse du nom de ville
    bl affichageMess
    ldr x0,qAdrszMessBlancs    // affichage du séparateur espace
    bl affichageMess
    add x12,x12,1
    cmp x12,NBGENOME
    blt 1b
2:
    ldr x0,qAdrszRetourLigne
    mov x1,LGRETLIGNE
    bl affichageMessSP
100:
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszMessInd:        .quad szMessInd
qAdrsZoneConv:        .quad sZoneConv
qAdrszMessBlancs:     .quad szMessBlancs

/******************************************************************/
/*     Fabrique individu creerIndividu seul                       */ 
/******************************************************************/
/* x0 contient l'adresse de la table population */
/* x1 l'indice du poste   */
/* x2 contient le type */
fiCreerIndividu:                 // INFO: fiCreerIndividu
    stp x0,lr,[sp,-16]!          // save  registres
    //affichelib creerindividu
    mov x10,x0
    mov x11,ind_fin
    madd x12,x11,x1,x0           // adresse structure individu dans table population
    //affregtit creation 10
    str xzr,[x12,ind_fitness]    // raz 
    str x2,[x12,ind_probleme]
    mov x0,x12  
    bl creationGenome
100:
    ldp x0,lr,[sp],16            // restaur des  2 registres
    ret                          // retour adresse lr x30
/******************************************************************/
/*     Fabrique individu creerIndividu avec 1 parent              */ 
/******************************************************************/
/* x0 contient l'adresse de la table population */
/* x1 l'indice du poste   */
/* x2 contient le type */
/* x3 contient l'adresse du parent */
fiCreerIndividu1parent:        // INFO: fiCreerIndividu1parent
    stp x0,lr,[sp,-16]!        // save  registres
    ldr x11,[x3,ind_genome]    // recup adresse table genome du parent
    mov x12,ind_fin
    madd x10,x12,x1,x0         // calcul adresse structure individu 
    //affregtit ind1 10
    mov x0,NBGENOME            // creation nouvelle table genome sur le tas
    lsl x0,x0,3
    bl allocPlace
    str x0,[x10,ind_genome]    // store adresse table genome individu
    mov x13,0
1:                             // recopie genome parent vers fils
    ldr x14,[x11,x13,lsl 3]
    str x14,[x0,x13,lsl 3]
    add x13,x13,1
    cmp x13,NBGENOME
    blt 1b
    mov x0,x10                 // et mutation 
    bl muterIndPVC
100:
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     Fabrique individu creerIndividu avec 2 parents              */ 
/******************************************************************/
/* x0 contient l'adresse de la table population */
/* x1 l'indice du poste   */
/* x2 contient le type */
/* x3 contient l'adresse du parent 1 */
/* x4 contient l'adresse du parent 2 */
fiCreerIndividu2parents:         // INFO: fiCreerIndividu2parents  
    stp x20,lr,[sp,-16]!         // save  registres
    mov x20,x0
    mov x0,NBGENOME-2
    bl genererAlea
    add x11,x0,1                // au moins 1 ville
    mov x12,ind_fin
    madd x10,x12,x1,x20         // calcul adresse structure individu 
    mov x0,NBGENOME             // creation nouvelle table genome
    lsl x0,x0,3
    bl allocPlace
    //mov x12,x0
    str x0,[x10,ind_genome]     // store adresse table genome individu
    ldr x3,[x3,ind_genome]      // genome parent 1
    mov x13,0
1:                              // recopie des premieres villes du parent 1
    ldr x14,[x3,x13,lsl 3]
    str x14,[x0,x13,lsl 3]
    add x13,x13,1
    cmp x13,x11
    blt 1b
                                // maintenant il faut recopier les autres villes du parent 2
    ldr x4,[x4,ind_genome]
    mov x15,0
2:
    ldr x16,[x4,x15,lsl 3]      // charge une ville parent 2
    mov x17,0                   // indice recherche
3:
    ldr x18,[x0,x17,lsl 3]
    cmp x16,x18                // la ville est deja chargée
    beq 4f
    add x17,x17,1
    cmp x17,x11
    blt 3b                     // boucle de recherche
    str x16,[x0,x13,lsl 3]     // sinon on charge la nouvelle ville
    add x13,x13,1
4:
    add x15,x15,1              // autre ville
    cmp x15,NBGENOME
    blt 2b                     // boucle ?
    mov x0,x10
    bl muterIndPVC             // et mutation

100:
    ldp x20,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     Affichage du meilleur individu              */ 
/******************************************************************/
/* x0 contient l'adresse structure individu */
/* x1 contient la géneration */
afficherMeilleur:              // INFO: afficherMeilleur
    stp x0,lr,[sp,-16]!        // save  registres
    //affichelib affichermeilleur
    mov x10,x0
    mov x0,x1
    ldr x1,qAdrsZoneConv
    bl conversion10S
    ldr x0,qAdrszMessGeneration
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    bl affichageMess
    mov x0,x10
    bl afficherInd             // affiche les données individu
100:
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszMessGeneration:       .quad szMessGeneration
/******************************************************************/
/*     creation du processus evolutionnaire                       */ 
/******************************************************************/
/* x0 contient l'adresse de la structure proc  */
/* x1 contient le type du problème */
creationProc:                    // INFO: creationProc
    stp x21,lr,[sp,-16]!         // save  registres
    stp x22,x23,[sp,-16]!        // save  registres
    //affichelib creationProc
    mov x21,x1
    str x1,[x0,proc_probleme]
    str xzr,[x0,proc_nbGeneration]
    ldr x22,qAdrtbPopulation
    str x22,[x0,proc_population]
                                // ajout individu dans table population
    mov x23,0
1:                              // debut de boucle de création
    mov x0,x22                  // table population
    mov x2,x21                  // type=probleme
    mov x1,x23                  // poste table
    bl fiCreerIndividu
    add x23,x23,1
    cmp x23,NBIND
    blt 1b
100:
    ldp x22,x23,[sp],16         // restaur des  2 registres
    ldp x21,lr,[sp],16          // restaur des  2 registres
    ret                         // retour adresse lr x30
qAdrtbPopulation:          .quad tbPopulation

/******************************************************************/
/*     selection population                       */ 
/******************************************************************/
/* x0 contient l'adresse de la structure proc  */
/* x0 retourne l'adresse de l'individu selectionné */
procSelection:                      //INFO: procSelection
    stp x1,lr,[sp,-16]!             // save  registres
    //affichelib procSelection
    mov x10,x0
    ldr x13,[x10,proc_population]   // table 
                                    //tirage au sort de 2 parents
    mov x0,NBIND -1
    bl genererAlea
    mov x11,x0
    mov x0,NBIND -1
    bl genererAlea
    mov x12,x0
    mov x14,ind_fin
    madd x11,x11,x14,x13
    ldr x16,[x11,ind_fitness]
    madd x12,x12,x14,x13
    ldr x17,[x12,ind_fitness]
                                    // et on garde celui qui a la plus petite fitness
    cmp x16,x17
    csel x0,x11,x12,lt              // retour dans x0

100:
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/***************PROBLEME PVC    */
/******************************************************************/
/*     calcul distance entre 2 villes                       */ 
/******************************************************************/
/* x0 contient l'index première ville  */
/* x1 contient l'index deuxieme ville */
calDistance:
    stp x20,lr,[sp,-16]!       // save  registres
    stp x21,x22,[sp,-16]!      // save  registres
    //affichelib calDistance
    ldr x20,qAdrtbDistance
    mov x21,NBDISTANCES        // nb de distance par ville
    lsl x21,x21,3              // * par 8 octets
    mul x21,x21,x0             // * index ville 1
    lsl x22,x1,3               // index ville 2 * 8 octets
    add x21,x21,x22            // donne la distance recherchée 
    ldr x0,[x20,x21]           // dans la table

100:
    ldp x21,x22,[sp],16        // restaur des  2 registres
    ldp x20,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrtbDistance:      .quad tbDistance
/******************************************************************/
/*     creation du genome d'un individu                       */ 
/******************************************************************/
/* x0 contient l'adresse de la structure individu  */
creationGenome:
    stp x25,lr,[sp,-16]!     // save  registres
    mov x25,x0               // save structure
                             //creation table genome sur le tas 
    mov x0,NBGENOME
    lsl x0,x0,3
    bl allocPlace
    str x0,[x25,ind_genome]  // stockage table genome
                             // initialisation index table genome
    mov x12,0
1:                           // boucle d'initialisation
    str x12,[x0,x12,lsl 3]
    add x12,x12,1
    cmp x12,NBGENOME
    blt 1b
    mov x1,NBGENOME          // melange de la table
    bl knuthShuffle
100:
    ldp x25,lr,[sp],16       // restaur des  2 registres
    ret                      // retour adresse lr x30
qAdrtbNomVille:         .quad tbNomVille
/******************************************************************/
/*     Knuth Shuffle                                              */ 
/******************************************************************/
/* x0 contains the address of table */
/* x1 contains the number of elements */
knuthShuffle:
    stp x1,lr,[sp,-16]!         // save  registers
    stp x2,x3,[sp,-16]!         // save  registers
    stp x4,x5,[sp,-16]!         // save  registers
    stp x6,x7,[sp,-16]!         // save  registers
    mov x5,x0                   // save table address
    mov x6,x1                   // save number of elements
    mov x2,0                    // start index
1:
    mov x0,x1
    bl genererAlea
    ldr x3,[x5,x2,lsl 3]        // swap number on the table
    ldr x4,[x5,x0,lsl 3]
    str x4,[x5,x2,lsl 3]
    str x3,[x5,x0,lsl 3]
    add x2,x2,1                 // next number
    cmp x2,x6                   // end ?
    blt 1b                      // no -> loop
 
100:
    ldp x6,x7,[sp],16           // restaur  2 registers
    ldp x4,x5,[sp],16           // restaur  2 registers
    ldp x2,x3,[sp],16           // restaur  2 registers
    ldp x1,lr,[sp],16           // restaur  2 registers
    ret
/******************************************************************/
/*     affichage de tous les individus population                 */ 
/******************************************************************/
/* x0 contient l'adresse de la table population  */
afficherPop:
    stp x20,lr,[sp,-16]!      // save  registres
    stp x21,x23,[sp,-16]!     // save  registres
    mov x21,x0                // save structure
    mov x23,ind_fin
    mov x20,0
1:
    madd x0,x20,x23,x21
    bl afficherInd
    add x20,x20,1
    cmp x20,NBIND
    blt 1b
100:
    ldp x21,x23,[sp],16       // restaur des  2 registres
    ldp x20,lr,[sp],16        // restaur des  2 registres
    ret                       // retour adresse lr x30
