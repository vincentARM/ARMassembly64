/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* calcul avec les instructions float asm 64 bits  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"

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

szAfficheVal1:         .asciz "Valeur = %+09.15f\n"

/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
dfRacine:            .skip 8
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    affichelib affichage_valeur
    fmov d0,0.25                 // valeur immediate en float
    ldr x0,qAdrszAfficheVal1
    bl printf                    // affichage par fonction C du registre d0
    mov x0,50                    // valeur immédiate dans registre général
    fmov d0,x0                   // transfert dans registre float
    scvtf d0,d0                  // et conversion en float (obligatoire)
    ldr x0,qAdrszAfficheVal1
    bl printf 
    ldr d0,dfPI                  // chargement d'une valeur en mémoire
    ldr x0,qAdrszAfficheVal1
    bl printf 
    affichelib  recup_entier
    ldr d0,dfPI                  // chargement d'une valeur en mémoire
    fcvtzu d1,d0                 // conversion en entier non signé 
    fmov x0,d1                   // tranfert dans le registre général
    affregtit entier 0
    affichelib  calculs
    fmov d0,5
    fmov d1,1.25
    fadd d0,d0,d1                // addition
    ldr x0,qAdrszAfficheVal1
    bl printf 
    fmov d0,9
    fmov d1,1.25
    fmul d0,d0,d1                // multiplication
    ldr x0,qAdrszAfficheVal1
    bl printf 
    fmov d0,5
    fmov d1,1.25
    fdiv d0,d0,d1                // division
    ldr x0,qAdrszAfficheVal1
    bl printf 
    fmov d1,1.25
    frinta d0,d1                // arrondi inférieur
    ldr x0,qAdrszAfficheVal1
    bl printf 
    fmov d1,3
    fsqrt d0,d1                 // racine carrée
    ldr x0,qAdrdfRacine
    str d0,[x0]
    ldr x0,qAdrszAfficheVal1
    bl printf 
    affichelib Comparaisons
    fmov d0,5
    fmov d1,3
    fcmp d0,d1
    affetattit compar1
    fcmp d1,d0
    affetattit compar2
    fmin d2,d0,d1               // minimum de 2 valeurs
    fmov d0,d2
    ldr x0,qAdrszAfficheVal1
    bl printf 
    affichelib verifmemoire
    ldr x0,qAdrdfRacine
    ldr d0,[x0]
    ldr x0,qAdrszAfficheVal1
    bl printf 
    mov x0,0xA2                // pour 10 avant la virgule et 
    scvtf d0,x0,4              // pour 4 bits indique la position de la virgule 
    ldr x0,qAdrszAfficheVal1   // entre le A et le 2 
    bl printf 

//test 32 bits
    mov w0,5
    fmov s31,w0
    scvtf s30,s31               // et conversion en float (obligatoire)
    ldr x0,qAdrszAfficheVal1
    fcvt d0,s30                 // conversion simple -> double
    bl printf                   // pour l'affichage 

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
qAdrszAfficheVal1:       .quad szAfficheVal1
dfPI:                    .double 0f314116E-5     // Pi
qAdrdfRacine:            .quad dfRacine


