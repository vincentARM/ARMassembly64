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
table1_cle:             /* adresse de la clé */ 
    .struct  table1_cle + 8
table1_valeur:          /* valeur de l'enregistrement */ 
    .struct  table1_valeur + 8
table1_pointeur:       /* pointeur vers suivant sur 8 octets*/ 
    .struct  table1_pointeur + 8
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
szMessAffEnreg:           .asciz "N° : @  clé : @ valeur : @  suivant : @\n"
szMessValeurTrouvee:      .asciz "Valeur : @ \n"
szStringTest1:   .asciz "Abcde"
szStringTest2:   .asciz "Abcd"
szStringTest3:   .asciz "A"
szStringTest4:   .asciz "K"
szStringCh1:     .asciz "K"

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
    ldr x21,qAdrstTable
    mov x22,NBPOSTESTABLE
    mov x0,x21
    ldr x1,qAdrszStringTest1
    mov x2,50
    mov x3,x22                    // nombre total de postes
    bl insertionTable
    mov x0,x21
    ldr x1,qAdrszStringTest3
    mov x2,60
    mov x3,x22                    // nombre total de postes
    bl insertionTable

    mov x0,x21
    ldr x1,qAdrszStringTest4
    mov x2,70
    mov x3,x22                    // nombre total de postes
    bl insertionTable

    mov x0,x21
    ldr x1,qAdrszStringTest2
    mov x2,110
    mov x3,x22                    // nombre total de postes
    bl insertionTable

                                  // affichage table
    affichelib Affichagetable
    mov x1,0                      // 1er enregistrement
2:
    mov x0,x21
    bl affichageTable
    add x1,x1,1
    cmp x1,x22                    // nombre de poste ?
    blt 2b                        // et boucle
    affichelib RechercheTable
    mov x0,x21
    ldr x1,qAdrszStringCh1
    mov x2,x22
    bl rechTable
    bcs 3f                      // carry mis -> non trouvé
    affichelib Recherche_ok
    ldr x1,qAdrsBuffer
    bl conversion10            // conversion décimale
    ldr x0,qAdrszMessValeurTrouvee
    ldr x1,qAdrsBuffer
    bl strInsertAtChar
    bl affichageMess

    b 100f
3:
    affichelib Non_trouve

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
qAdrszStringTest1:       .quad szStringTest1
qAdrszStringTest2:       .quad szStringTest2
qAdrszStringTest3:       .quad szStringTest3
qAdrszStringTest4:       .quad szStringTest4
qAdrszStringCh1:         .quad szStringCh1
qAdrszMessValeurTrouvee: .quad szMessValeurTrouvee
/******************************************************************/
/*     recherche dans la table                      */ 
/******************************************************************/
/* x0 : adresse de la table  */
/* x1 : cle */
/* x2 : Nombre d'enregistrement maxi */
/* x0 : retourne le N° d'enregistement trouvé ou - 1*/
/* Attention pas de save des registres x9-x11 */
rechTable:
    stp x1,lr,[sp,-16]!        // save  registres
    mov x13,x0
    mov x14,x1
    mov x0,x1                  // adresse chaine
    mov x1,x2
    bl calcHashString
    mov x10,table1_fin         // longueur d'un enregistrement
    madd x12,x0,x10,x13        // calcul adresse enregistrement
    ldr x11,[x12,table1_cle]
    cbz x11,99f                // non trouvé
1:                             // comparaison des clés
    mov x0,x11
    mov x1,x14
    bl Comparaison
    cbz x0,98f                 // les 2 clés sont égales
    ldr x12,[x12,table1_pointeur]
    cbz x12,99f                // le pointeur suivant est nul donc non trouvé
    ldr x11,[x12,table1_cle]   //cle suivante
    b 1b                       // et boucle

98: 
    ldr x0,[x12,table1_valeur] // trouvé retour de la valeur
    cmn x0,0                   // carry ok
    b 100f
99:
    mov x0,-1                  // non trouvé
    cmp x0,0                   // positionnement du carry car -1 peut être OK
100:
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     insertion dans une table                                   */ 
/******************************************************************/
/* x0 : adresse de la table  */
/* x1 : adresse de la chaine  clé */
/* x2 : valeur               */
/* x3 : nombre de postes de la table
/* x0 : retourne le N° d'enregistrement . */
/* Attention pas de save des registres x12-x15 */
insertionTable:
    stp x1,lr,[sp,-16]!        // save  registres
    mov x13,x0
    mov x14,x1
    mov x0,x1
    mov x1,x3
    bl calcHashString
    mov x15,x0
    mov x10,table1_fin         // longueur d'un enregistrement
    madd x12,x0,x10,x13         // calcul adresse enregistrement
                               // avec x0 contenant le hach
    ldr x11,[x12,table1_cle]   // cle à zéro ?
    cbz x11,1f                 // oui -> insertion
    //affregtit Collision 0
    mov x0,x14                  // clé
    mov x1,x2                  // valeur
    mov x2,0
    bl creerNoeud
    mov x1,x0                  // adresse du noeud crée
    mov x0,x12                 // insertion après entête
    bl insertNoeud
    mov x0,x15
    b 100f
1:
    str x14,[x12,table1_cle]     // insertion cle  à l'adresse trouvée
    str x2,[x12,table1_valeur]   // insertion valeur
    str xzr,[x12,table1_pointeur] // pointeur suivant à zero
    mov x0,x15

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
    mov x11,x0
    mov x13,x1
    mov x0,x1                  // N° enregistrement
    ldr x1,qAdrsBuffer
    bl conversion10            // conversion décimale
    ldr x0,qAdrszMessAffEnreg
    ldr x1,qAdrsBuffer
    bl strInsertAtChar
    mov x15,x0
    mov x16,x0
    madd x12,x13,x10,x11       // calcul de l'adresse
1:
    ldr x0,[x12,table1_cle]    // conversion pour affichage de la clé
    ldr x1,qAdrsBuffer
    bl conversion10
    mov x0,x15
    ldr x1,qAdrsBuffer
    bl strInsertAtChar
    mov x15,x0
    ldr x0,[x12,table1_valeur] // idem pour la valeur
    ldr x1,qAdrsBuffer
    bl conversion10
    mov x0,x15
    ldr x1,qAdrsBuffer
    bl strInsertAtChar

    mov x15,x0
    ldr x0,[x12,table1_pointeur] // idem pour le pointeur
    mov x17,x0
    ldr x1,qAdrsBuffer
    bl conversion10
    mov x0,x15
    ldr x1,qAdrsBuffer
    bl strInsertAtChar
    bl affichageMess
    cbz x17,100f                 // pointeur suivant nul ?
    mov x12,x17                  // sinon boucle avec pointeur suivant
    mov x15,x16                  // et libellé adéquat
    b 1b
   

100:

    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrsBuffer:            .quad sBuffer
qAdrszMessAffEnreg:     .quad szMessAffEnreg
/******************************************************************/
/*     calcul du hash d'une chaine                                */ 
/******************************************************************/
/* x0 : adresse de la chaine  */
/* x1 : valeur du modulo */
/* Attention pas de save des registres x9-x12 */
calcHashString:
    stp x8,lr,[sp,-16]!        // save  registres
    mov x8,0
    mov x9,127
    mov x10,0
1:
    ldrb w11,[x0,x10]
    cbz w11,2f
    mul x12,x8,x9
    add x12,x12,x11
    udiv x11,x12,x1
    msub x8,x11,x1,x12

    add x10,x10,1
    b 1b
2:
    mov x0,x8
100:

    ldp x8,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     creation noeud                                             */ 
/******************************************************************/
/* x0 contient la clé   */
/* x1 contient la valeur
/* x2 contient zero ou l'adresse du noeud suivant */
/* x0 retourne l'adresse du noeud sur le tas */
creerNoeud:
    stp x3,lr,[sp,-16]!        // save  registres
    mov x3,x0
    mov x0,table1_fin
    bl allocPlace
    cmp x0,-1
    beq 100f
    str x3,[x0,table1_cle]
    str x1,[x0,table1_valeur]
    str x2,[x0,table1_pointeur]
    //affregtit creat 0
100:
    ldp x3,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     insert Noeud dans liste                                    */ 
/******************************************************************/
/* x0 contient l'adresse du noeud apres lequel il faut inserer */
/* x1 contient l'adresse du noeud à inserer */
insertNoeud:
    stp x2,lr,[sp,-16]!        // save  registres
    ldr x2,[x0,table1_pointeur]
    str x2,[x1,table1_pointeur]
    str x1,[x0,table1_pointeur]
    //affregtit insert 0
100:
    ldp x2,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/************************************/      
/* comparaison de chaines           */
/************************************/     
/* x0 et x1 contiennent les adresses des chaines */
/* retour 0 dans x0 si egalite -1 plus petit et 1 plus grand */
Comparaison:
    stp x1,lr,[sp,-16]!   // save  registres
    stp x2,x3,[sp,-16]!   // save  registres
1:    
    ldrb w3,[x0],1        // octet chaine 1
    ldrb w2,[x1],1        // octet chaine 2
    cmp w3,w2
    blt 2f                // plus petit
    bgt 3f                // plus grand
    cbz w3,4f             // 0 final c'est la fin
    b 1b                  // et boucle
2:
    mov x0,#-1            // plus petit
    b 100f
3:
    mov x0,#1             // plus grand 
    b 100f
4:
    mov x0,#0             // egalite
100:
    ldp x2,x3,[sp],16     // restaur des  2 registres
    ldp x1,lr,[sp],16     // restaur des  2 registres
    ret                   // retour adresse lr x30
