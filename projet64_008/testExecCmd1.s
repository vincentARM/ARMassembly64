/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* test de lancement d'une commande Linux  asm 64 bits  */

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
szMessDebutPgm:       .asciz "Début programme.\n"
.equ LGMESSDEBUT,     . - szMessDebutPgm
szMessFinPgm:         .asciz "Fin ok du programme.\n"
.equ LGMESSFIN,       . - szMessFinPgm
szRetourLigne:        .asciz "\n"
.equ LGRETLIGNE,      . - szRetourLigne
szMessErreur:         .asciz "Erreur  !!!\n"
szCommande:           .asciz "/bin/sh"
szCommandeCpl:        .asciz "-c"
szCommandeArg:        .asciz "ls -l"
//szCommandeArg:           .asciz "ping www.google.fr -c 1"     // commande linux host
.align 4
stArg1:               .quad szCommande             // adresse de la commande
                      .quad szCommandeCpl
                      .quad szCommandeArg         // adresse de l'argument
                      .quad 0                   // zeros
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
    affichelib Exemple

    ldr    x0, qAdrszCommande    // adresse de /bin/sh
    ldr    x1, qAdrstArg1        // adresse structure commande à executer 
    mov x2,xzr
    mov x8,221                   // call system linux (execve)
    svc #0                       // si ok -> fin commande sans retour !!!
    affregtit retourcommande 0
    cbnz x0,99f                 // si erreur 
    b 100f                      // cette instruction n'est jamais executée
    
99:                             // affichage erreur
    ldr x1,qAdrszMessErreur
    bl afficheErreur 
    mov x0, #1                  // code retour erreur
    b 100f
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
qAdrszCommande:          .quad szCommande
qAdrstArg1:              .quad stArg1
qAdrszMessErreur:        .quad szMessErreur

