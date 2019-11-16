/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* test extra registre asm 64 bits  */
/* et test generateur aléatoire */

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
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
.align 4
qGraine:            .skip 8
qZonesTest:         .skip 8 * 20
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                          // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    affichelib Exemple
    mov x0,10
    mov w1,5
    add x0,x0,w1,UXTW #2      //Non signé(U) et registre complet 32 bits (W) 
    affregtit testregistre 0  // et W1 est multipli par 4
    mov x0,10
    mov w1,-15
    add x0,x0,w1,UXTW #0      //Non signé(U) et registre complet 32 bits (W) 
    affregtit negatif 0
    mov x0,10
    mov w1,-15
    add x0,x0,w1,SXTW #0      //signé(S) et registre complet 32 bits (W) 
    affregtit negatifsigne 0  // C'est ok = - 5

    ldr x1,qAdriZonesTest
    mov w2,2                  // registre 32 bits
    mov x0,5
    str x0,[x1,w2,UXTW 3]     // stockage à x1 + (2 * 8)

    affmemtit verifstore x1 4 

    /* verification générateur aléatoire */
    mov x0,0x1234
    bl gen_init
    mov x0,6
    bl gen_alea
   affregtit alea1 0 
    mov x0,6
    bl gen_alea
   affregtit alea2 0 
    mov x0,6
    bl gen_alea
   affregtit alea3 0 
    mov x0,6
    bl gen_alea
    affregtit alea4 0 
    /*verif moyenne */
    mov x1,10                   // coef multiplicateur pour calcul moyenne
    mov x10,0                   // total
    mov x11,1000                // nombre de tests
    mov x12,0                   // compteur de tests
10:
    mov x0,100                  // plage maxi  donc de 0 à(n-1)
    bl gen_alea
    mul x0,x0,x1                // multiplie par le coef
    add x10,x10,x0              // ajout au total
    add x12,x12,1               // increment compteur
    cmp x12,x11                 // maxi atteint ?
    blt 10b
    udiv x0,x10,x11             // calcul moyenne (* coef)
    affregtit verifmoyenne 0    // attention x0 est en hexa !!!
    affregtit verifmoyenne 10 

1000:                            // fin standard du programme
    ldr x0,qAdrszMessFinPgm     // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdriZonesTest:          .quad qZonesTest

/***************************************************/
/*   Initialisation de la graine                   */
/***************************************************/
/* x0 contient une valeur initiale */
gen_init:                      // fonction
    stp x1,lr,[sp,-16]!        // save  registres
    ldr x1,qAdriGraine
    str x0,[x1]
100:                           // fin standard de la fonction
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdriGraine:      .quad qGraine
/***************************************************/
/*   génération d'un nombre aléatoire              */
/***************************************************/
/* x0 contient la borne superieure */
/* x0 retourne le nombre aléatoire */
gen_alea:                      // fonction
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    mov x3,x0                  // valeur maxi
    ldr x0,qAdriGraine         // graine
    ldr x2,qVal1 
    ldr x1,[x0]                // charger la graine
    mul x1,x2,x1
    ldr x2,qVal2
    add x1,x1,x2
    str x1,[x0]                // sauver graine
    udiv x2,x1,x3
    msub x0,x2,x3,x1           // calcul resultat modulo plage

100:                           // fin standard de la fonction
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

qVal1:         .quad 0x0019660d //0x343FD   autres valeurs possibles
qVal2:         .quad 0x3c6ef35f //0x269EC3
