/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* Gestion tables, Shell tri, recherche sequentielle
         et dichotomique  asm 64 bits  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"
.equ NBPOSTESTABLE,   100
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
table1_valeur:       /* valeur sur 4 octets*/ 
    .struct  table1_valeur + 4
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
szMessAffEnreg:           .asciz "N° : @  clé : @ valeur : @ \n"

/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
stTable:            .skip table1_fin * NBPOSTESTABLE
sBuffer:            .skip 100
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    affichelib Exemple
                                  // chargement table avec des clé aléatoires
    mov x20,0                     // indice départ
    ldr x21,qAdrstTable
1:
    mov x0,49                     // borne maxi
    bl genererAlea
    add x0,x0,1                   // pour eviter clé à 0
    mov x1,x0                     // cle aléatoire
    mov x0,x21                    // adresse table
    mov x2,x20                    // valeur = N° enregistrement
    bl insertionTable
    add x20,x20,1
    cmp x20,NBPOSTESTABLE - 10    // chargement de 90 postes
    ble 1b
    mov x22,x0                    // nombre de postes
                                  // affichage table
    affichelib Affichagetable
    mov x1,0                      // 1er enregistrement
1:
    mov x0,x21
    bl affichageTable
    add x1,x1,1
    cmp x1,x22                    // nombre de poste ?
    blt 1b                        // et boucle
                                  // recherche sequentielle
    affichelib Recherchesequentielle
    mov x0,x21
    mov x1,47
    mov x2,x22                    // nombre de postes
    bl rechSeqTable
    cmp x0,-1                     // clé trouvée ?
    beq 2f
    mov x1,x0
    mov x0,x21
    bl affichageTable
2:
                                  // tri de la table
    mov x0,x21                    // adresse table
    mov x1,0                      // premier poste
    mov x2,x22                    // nombre de postes
    mov x3,table1_fin             // taille d'un poste
    bl triShell
    affichelib AffichagetableApresTri
    mov x1,0                      // 1er enregistrement
3:
    mov x0,x21
    bl affichageTable
    add x1,x1,1
    cmp x1,x22                    // nombre de poste ?
    blt 3b                        // et boucle

    affichelib Recherchedicho
    mov x0,x21
    mov x1,x22                    // nombre de postes
    mov x2,47                     // clé à rechercher
    bl rechdichoTable
    cmp x0,-1
    beq 4f
    affregtit finrech 0
    mov x1,x0
    mov x0,x21
    bl affichageTable
4:
    affichelib InsertionTableTriee
    mov x0,x21                     // adresse table
    mov x1,20                      // cle
    mov x2,99                      // valeur
    mov x3,x22
    bl insertionTableTriee
    cmp x0,-1
    beq 5f
    mov x22,x0
                                   // insertion dernier poste
    mov x0,x21                     // adresse table
    mov x1,55                      // cle
    mov x2,99                      // valeur
    mov x3,x22
    bl insertionTableTriee
    cmp x0,-1
    beq 5f
    mov x22,x0
5:
    affichelib AffichagetableApresInsertion
    mov x1,0                       // 1er enregistrement
6:
    mov x0,x21
    bl affichageTable
    add x1,x1,1
    cmp x1,x22                     // nombre de poste ?
    blt 6b                         // et boucle
100:                               // fin standard du programme
    ldr x0,qAdrszMessFinPgm        // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                       // code retour
    mov x8,EXIT
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdrstTable:             .quad stTable
/******************************************************************/
/*     recherche sequentielle dans une table                      */ 
/******************************************************************/
/* x0 : adresse de la table  */
/* x1 : cle */
/* x2 : Nombre d'enregistrement maxi */
/* x0 : retourne le N° d'enregistement trouvé ou - 1*/
/* Attention pas de save des registres x9-x11 */
rechSeqTable:
    stp x1,lr,[sp,-16]!        // save  registres
    mov x9,0
    mov x10,table1_fin
1:
    madd x12,x9,x10,x0         // calcul de l'adresse
    ldr w11,[x12,table1_cle]
    cmp x11,x1
    beq 2f
    add x9,x9,1                // increment indice
    cmp x9,x2
    blt 1b
    mov x0,-1                  // non trouvé
    b 100f
2:
    mov x0,x9
100:
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     insertion dans une table                                   */ 
/******************************************************************/
/* x0 : adresse de la table  */
/* x1 : cle */
/* x2 : valeur */
/* x0 : retourne le nombre d'enregistrement. */
/* Attention pas de save des registres x9-x12 */
insertionTable:
    stp x1,lr,[sp,-16]!        // save  registres
    mov x9,#0
    mov x10,table1_fin         // longueur d'un enregistrement
1:
    madd x12,x9,x10,x0         // calcul adresse enregistrement
    ldr w11,[x12,table1_cle]   // clé à zéro ?
    cbz w11,2f                 // oui -> insertion
    add x9,x9,#1               // non enregistrement suivant
    cmp x9,NBPOSTESTABLE       // nb de postes maxi ?
    bge 99f                    // oui -> erreur
    b 1b                       // sinon boucle
2:
    str w1,[x12,table1_cle]    // insertion à l'adresse trouvée
    str w2,[x12,table1_valeur]
    mov x0,x9                  // retourne le nombre de postes
    b 100f
99:                            // erreur taille table
    ldr x0,qadrszMessErreurTable
    mov x1,LGMESSERREURTABLE
    bl affichageMessSP
    mov x0,-1
100:
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qadrszMessErreurTable:       .quad szMessErreurTable
/******************************************************************/
/*     insertion dans une table  déjà trié                        */ 
/******************************************************************/
/* x0 : adresse de la table  */
/* x1 : cle */
/* x2 : valeur */
/* x3 : nombre maxi d'enregistrement */
/* x0 : retourne le nombre d'enregistrement. */
/* Attention pas de save des registres x9-x14 */
insertionTableTriee:
    stp x1,lr,[sp,-16]!        // save  registres
    mov x9,#0
    mov x10,table1_fin         // longueur d'un enregistrement
1:
    madd x12,x9,x10,x0         // calcul adresse enregistrement
    ldr w11,[x12,table1_cle]   // clé > cle à inserer
    cmp w11,w1                 // clé > cle à inserer
    bge 2f                     // oui -> insertion
    add x9,x9,#1               // non enregistrement suivant
    cmp x9,x3                  // nb de postes maxi ?
    blt 1b
                               // insertion en fin
    cmp x9,NBPOSTESTABLE       // nb de postes maxi ?
    bge 99f                    // oui -> erreur
    b 4f
2:                             // deplacement des postes
    add x13,x3,1
    cmp x13,NBPOSTESTABLE       // nb de postes maxi ?
    bge 99f                     // oui -> erreur
3:
    sub x14,x13,1
    madd x12,x14,x10,x0         // calcul adresse enregistrement
    ldr x11,[x12]
    madd x12,x13,x10,x0         // calcul adresse enregistrement
    str x11,[x12]
    sub x13,x13,1
    cmp x13,x9
    bge 3b
4:
    madd x12,x9,x10,x0         // calcul adresse enregistrement
    str w1,[x12,table1_cle]    // insertion à l'adresse trouvée
    str w2,[x12,table1_valeur]
    add x0,x3,1                // Nouveau nombre d'enregistrement
    b 100f
99:                            // erreur taille table
    ldr x0,qadrszMessErreurTable
    mov x1,LGMESSERREURTABLE
    bl affichageMessSP
    mov x0,-1
100:
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     affichage des valeurs                                    */ 
/******************************************************************/
/* x0 : adresse de la table  */
/* x1 : numero enregistrement */
affichageTable:
    stp x1,lr,[sp,-16]!        // save  registres
    mov x10,table1_fin
    madd x12,x1,x10,x0           // calcul de l'adresse
    mov x0,x1                  // N° enregistrement
    ldr x1,qAdrsBuffer
    bl conversion10            // conversion décimale
    ldr x0,qAdrszMessAffEnreg
    ldr x1,qAdrsBuffer
    bl strInsertAtChar
    mov x15,x0

    ldr w0,[x12,table1_cle]    // idem pour la clé
    ldr x1,qAdrsBuffer
    bl conversion10
    mov x0,x15
    ldr x1,qAdrsBuffer
    bl strInsertAtChar
    mov x15,x0

    ldr w0,[x12,table1_valeur] // idem pour la valeur
    ldr x1,qAdrsBuffer
    bl conversion10
    mov x0,x15
    ldr x1,qAdrsBuffer
    bl strInsertAtChar

    bl affichageMess
100:

    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrsBuffer:            .quad sBuffer
qAdrszMessAffEnreg:     .quad szMessAffEnreg

/***************************************************/
/*   Tri shell avec debut de plage  >= zéro        */
/*   avec un pas different                         */
/*   algorithmes de Sedgewick  langage JAVA        */
/***************************************************/
/* x0  pointeur vers table à trier */
/* x1  premier poste     */
/* x2  nombre maxi d'enregistrements    */
/* x3  longueur du poste */
/* Attention pas de save des registres x8-x18   */
triShell:
    stp x2,lr,[sp,-16]!        // save  registres
    sub x2,x2,1                // dernier poste
    sub x12,x2,x1              // pas = plage
    mov x13,9                  // calcul du premier pas
    udiv x17,x12,x13
    mov x12,1
    mov x9,3
1:                             // boucle de calcul du premier pas
    cmp x12,x17
    bgt 2f
    mul x12,x9,x12
    add x12,x12,1
    b 1b
2:                             // boucle de tri principale
    //affregtit pas 0
    cbz x12,100f               // pas = zero ? alors fin
    mov x13,x12                // i 
    add x13,x13,x1             // ajout premier poste
3:
    madd x8,x13,x3,x0          // calcul adresse
    ldr w14,[x8,table1_cle]    // clé à déplacer
    ldr w18,[x8,table1_valeur] // et valeur
    mov x15,x13                // j
4:  
    add x17,x12,x1
    cmp x15,x17
    blt 5f
    sub x16,x15,x12           // j - pas
    madd x10,x16,x3,x0        // calcul adresse
    ldr w17,[x10,table1_cle]
    cmp w14,w17
    bge 5f
    madd x11,x15,x3,x0        // calcul adresse
    str w17,[x11,table1_cle]
    ldr w17,[x10,table1_valeur]
    str w17,[x11,table1_valeur]
    sub x15,x15,x12           // j = j - pas
    b 4b
5:
    madd x11,x15,x3,x0        // calcul adresse
    str w14,[x11,table1_cle]
    str w18,[x11,table1_valeur]
    add x13,x13,#1
    cmp x13,x2                // poste maxi ?
    ble 3b                    // non -> boucle 1
    udiv x12,x12,x9           // pas = pas /3
    b 2b                      // oui -> boucle nouveau pas

100:
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     Recherche dichotomique dans une table                                               */ 
/******************************************************************/
/* x0 contient l'adresse de la table */
/* x1 le nombre maxi de poste        */
/* x2 la valeur à rechercher  */
/* x0 retourne le N° de poste trouvé ou -1 si non trouvé */
/* Attention pas de save des registres x10-x17   */
rechdichoTable:
    stp x1,lr,[sp,-16]!        // save  registres
    mov x17,table1_fin
    sub x10,x1,1               // indice dernier poste
    mov x13,0                  // indice premier poste
1:
    cmp x13,x10                // indice bas > indixe haut ?
    bgt 5f                     // oui non trouvé
    add x14,x13,x10
    lsr x14,x14,1              // calcul (haut + bas) / 2
    madd x16,x14,x17,x0
    ldr w15,[x16,table1_cle]   // recup cle
    cmp w15,w2                 // = clé recherchée ?
    blt 2f                     // inferieure
    bgt 3f                     // supérieure 
    mov x0,x14                 // trouvé
    b 100f
2:
    add x13,x14,1              // indice bas = indice calculé + 1
    b 1b                       // et boucle
3:
    sub x10,x14,1              // indice haut = indice calculé - 1
    b 1b                       // et boucle 
5:
    mov x0,-1                  // non trouvé
100:
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
