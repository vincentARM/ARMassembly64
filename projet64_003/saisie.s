/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* saisie chaine et conversion décimale asm 64 bits  */
/* allocation place sur le tas */
/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"
.equ READ,            63
.equ BRK,            214

.equ TAILLEBUFFER,    100
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
szMessSaisieN:            .asciz "Veuillez saisir un nombre :"
.equ LGMESSSAISIEN,          . - szMessSaisieN
szRetourLigne:            .asciz "\n"
.equ LGRETLIGNE,         . - szRetourLigne
szMessErreurGen:            .asciz "Erreur rencontrée :\n"

/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  

/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    /* allocation de la place pour le buffer de saisie */
    mov x0,TAILLEBUFFER
    bl allocPlace               // allocation place sur le tas
    mov x28,x0                  // save début buffer
    /* Saisie d'une chaine */
    affichelib Saisie:
    mov x0,0                    //STDIN
    mov x1,x28                  // adresse du buffer de lecture
    mov x2,TAILLEBUFFER         // taille buffer
    mov x8,READ                 // call system linux
    svc 0 
    cmp x0,#0                   // erreur ?
    blt 99f
    affregtit saisie1 0         // x0 contient le nombre de caractères saisis
    mov x0,x28                  // et la chaine saisie se termine par 0A
    affmemtit AffMemoire x0 2

    /* Saisie d'un nombre positif ou négatif */
    ldr x0,qAdrszMessSaisieN
    mov x1,LGMESSSAISIEN
    bl affichageMessSP
    mov x0,0                    //STDIN
    mov x1,x28                  // adresse du buffer de lecture
    mov x2,TAILLEBUFFER         // taille buffer
    mov x8,READ                 // call system linux
    svc 0 
    cmp x0,#0                   // erreur ?
    blt 99f
    mov x0,x28                  // adresse du buffer
    bl conversionAtoD           // conversion en valeur numerique
    bcs 99f                     // erreur si carry positionné ?
    affregtit saisieNombre 0    // dans le registre x0
    mov x0,x28                  // vérification contenu buffer
    affmemtit AffMemoire x0 2
    b 100f
99:                             // erreur détectée
    ldr x1,qAdrszMessErreurGen
    bl   afficheErreur 
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
qAdrszMessSaisieN:       .quad szMessSaisieN
qAdrszMessErreurGen:     .quad szMessErreurGen
/******************************************************************/
/*     conversion chaine ascii en nombre                          */ 
/******************************************************************/
/* x0 contient l'adresse de la chaine terminée par 0x0 ou 0xA */
/* x0 retourne le nombre */ 
conversionAtoD:
    stp x5,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    mov x1,#0
    mov x2,#10             // facteur
    mov x4,x0              // save de l'adresse dans x4
    mov x3,#0              // signe positif par defaut
    mov x0,#0              // initialisation à 0
    mov x5,#0
1:                         // boucle d'élimination des blancs du debut
    ldrb w5,[x4],1         // chargement dans w5 de l'octet situé au debut + la position
    cbz w5,100f            // fin de chaine -> fin routine
    cmp w5,#0x0A           // fin de chaine -> fin routine
    beq 100f
    cmp w5,#' '            // blanc au début
    beq 1b                 // non on continue
2:
    cmp x5,#'-'            // premier caractere est -
    bne 3f
    mov x3,#1              // signale un nombre négatif
    b 4f                   // puis on avance à la position suivante
3:                         // debut de boucle de traitement des chiffres
    cmp x5,#'0'            // caractere n'est pas un chiffre
    blt 4f
    cmp x5,#'9'            // caractere n'est pas un chiffre
    bgt 4f
                           // caractère est un chiffre
    sub w5,w5,#48

    mul x0,x2,x0           // multiplier par facteur
    smulh x1,x2,x0         // partie haute
    cbnz x1,99f            // depassement de capacité
    add x0,x0,x5           // sinon ajout à x0
4:
    ldrb w5,[x4],1         // chargement de l'octet et avancement
    cbz w5,5f              // fin de chaine -> fin routine
    cmp w5,#0xA            // fin de chaine ?
    bne 3b                 // non alors boucler
5:
    cmp x3,#1              // test du registre x3 pour le signe
    cneg x0,x0,eq          // si egal inversion de la valeur
    cmn x0,0               // carry à zero pas d'erreur
    b 100f
99:                        // erreur de dépassement
    adr x1,szMessErr
    bl  afficheErreur 
    cmp x0,0               // carry à un car erreur
    mov x0,#0              // en cas d'erreur on retourne toujours zero
100:
    ldp x1,x2,[sp],16      // restaur des  2 registres
    ldp x3,x4,[sp],16      // restaur des  2 registres
    ldp x5,lr,[sp],16      // restaur des  2 registres
    ret                    // retour adresse lr x30
szMessErr:      .asciz "Nombre trop grand : dépassement de capacite de 64 bits. :\n"
.align 4                   // instruction pour réaligner les routines suivantes
/******************************************************************/
/*     Allocation place sur le tas                                */ 
/******************************************************************/
/* x0 contient la taille demandée en octet */
/* x0 retourne l'adresse de début de la zone allouée */
/*  ou -1 si l'allocation n'a pu être faite */
allocPlace:
    stp x8,lr,[sp,-16]!       // save  registres
    stp x1,x2,[sp,-16]!       // save  registres
    bic x2,x0,0b111           // pour raz des 3 derniers bits
    add x2,x2,8               // pour respecter alignement
    mov x0,0                  // recuperation de l'adresse du tas
    mov x8,BRK                // code de l'appel systeme 'brk'
    svc 0                     // appel systeme
    cmp x0,#-1                // erreur allocation
    beq 100f
    mov x1,x0                 // save du début
    add x0,x0,x2              // reservation place demandé
    mov x8,BRK                // code de l'appel systeme 'brk'
    svc 0                     // appel systeme
    cmp x0,-1                 // erreur allocation
    beq 100f
    mov x0,x1                 //retour adresse début 

100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x8,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30


