/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/* verification fonction Clone 0x220 */
/* attente de la fin du tread    */
/* pgm à lancer par testThread64 &  puis faire ps pour voir les pid */
/* puis faire kill -STOP pidfils puis kill -CONT pidfils puis kill -TERM pidfils */
/*********************************************/
/*           CONSTANTES                      */
/********************************************/
.include "../constantesARM64.inc"
.equ WNOHANG,               1  //  Wait, do not suspend execution
.equ WUNTRACED,             2   // Wait, return status of stopped child
.equ WCONTINUED,            8   // Wait, return status of continued child
//.equ WEXITED,              8   // Wait for processes that have exited
//.equ WSTOPPED,            16   // Wait, return status of stopped child
.equ WNOWAIT,               32    //Wait, return status of a child without
//.equ CLONE_NEWUTS, 0x04000000
.equ SIG_BLOCK,      1
.equ SIGCHLD,  17
//.equ CLONE_VM, 0x100
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne:      .asciz  "\n"
szMessageThread:    .asciz "Execution thread du fils. \n" 
szMessageFinThread: .asciz "Fin du thread. \n" 
szMessageParent:    .asciz "C'est moi le papa !!\n"
szMessDebutPgm:     .asciz "Début programme.\n"
.equ LGMESSDEBUT,   . - szMessDebutPgm
szMessFinPgm:       .asciz "Fin ok du programme.\n"
.equ LGMESSFIN,     . - szMessFinPgm
szRetourLigne:      .asciz "\n"
.equ LGRETLIGNE,    . - szRetourLigne
szMessErreur:       .asciz "Erreur rencontrée.\n"
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
qStatus:          .skip 8

/* zones pour l'appel fonction sleep */
qZonesAttente:
 qSecondes:      .skip 8
 qMicroSecondes: .skip 8
qZonesTemps:     .skip 16

qSet:            .skip 160
zRusage:         .skip 1000

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text
.global main

main:                          // programme principal
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    mov x19,1                  // pour verification variable
    mov x20,2
    mov x0,0
    mov x8,178                 // recup identifiant du père gettid
    svc 0
    mov x4,x0                  // identifiant père passé dans paramètre x4
                               // lancement du thread fils
    ldr x0,qFlags
    mov x1,0
    mov x2,0
    mov x3,0
    mov x5,0
    mov x8, 220                // appel fonction systeme clone
    svc 0 
    cmp x0,#0
    blt erreur
    bne parent                 // si <> zero x0 contient le pid du pere
                               // sinon c'est le fils 
    bl exec_thread
    b 100f                     // normalement on ne revient jamais ici

parent:    
    affregtit parent 0         // le PID du fils est dans x0
    mov x19,x0                 // save du pid fils
    ldr x0,qAdrszMessageParent
    bl affichageMess

    //ldr x0,qAdrqSecondes
    //mov x1,#5                  // temps d'attente 5s
    //str x1,[x0]
    //ldr x0,qAdrqZonesAttente
    //ldr x1,qAdrqZonesTemps
    //affregtit parent1 0
    //mov x8,101                 // appel fonction systeme
    //svc 0 
    //affregtit attente 0
1:                                 // debut de boucle d'attente des signaux du fils
    mov x0,x19
    ldr x1,qAdrqStatus             // contient le status de retour
    mov x2,#WCONTINUED | WUNTRACED // revoir options
    ldr x3,qAdrzRusage             // structure contenant les infos de retour 
    mov x8,260                     // appel fonction systeme WAIT4
    svc 0 
    cmp x0,#0
    blt erreur
    //affregtit suite 0
    ldr x0,qAdrqStatus             // analyse du status
    affmemtit status x0 2
    ldr x0,qAdrqStatus             // recup du status
    ldrb w0,[x0]                   // premier octet
    cmp w0,#0X0F                   // fin du thread par kill ?
    beq 2f                         // oui  arret boucle 
    cmp w0,#0                      // fin normale du tread
    beq 2f                         // oui  arret boucle et le 2iéme octet de qStatus contient le code retour
    //affregtit boucle 0
    b 1b                           // sinon on boucle 
2:    
    ldr x0,qAdrzRusage
    affmemtit affzRusage x0 2
   
    affregtit variablespere 18

    ldr x0,qAdrszMessFinPgm     // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                    // code retour
    b 100f
erreur:                         // affichage erreur
    ldr x1,qAdrszMessErreur
    bl   afficheErreur
    mov x0,#1                   // code erreur
    b 100f

100:                            // fin standard du programme
    mov x8,EXIT                 // system call "Exit"
    svc #0
qFlags:                  .quad SIGCHLD
qAdrqZonesAttente:       .quad qZonesAttente
qAdrqZonesTemps:         .quad qZonesTemps
qAdrszMessageParent:     .quad szMessageParent
qAdrszMessErreur:        .quad szMessErreur
qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdrzRusage:             .quad zRusage
qAdrqStatus:             .quad qStatus
qAdrqSecondes:           .quad qSecondes
/***************************************************/
/*   Exemple d'appel du thread               */
/***************************************************/
exec_thread:
    stp x1,lr,[sp,-16]!        // save  registres
    mov x8,173                 // getppid appel fonction systeme pour trouver le pid du pére */
    svc 0 
    affregtit fils1 0          // voir dans le registre zero
    affregtit variablesfils 18
    mov x20,5                  // pour verif variables
    ldr x0,qAdrszMessageThread
    bl affichageMess
    ldr x0,qAdrqSecondes
    mov x1,#2                  // temps d'attente 5s
    str x1,[x0]
    ldr x0,qAdrqZonesAttente
    ldr x1,qAdrqZonesTemps
    mov x8,101                 // appel fonction systeme
    svc 0 
    affregtit variablesfils 18
                               // remplace l'appel systeme  PAUSE
    mov x0,SIG_BLOCK
    mov x1,0
    ldr x2,qAdrqSet
    mov x3,8
    mov x8,135                 // appel fonction systeme rt_sigprocmask
    svc 0
    cbnz x0,99f                // erreur ?
    ldr x0,qAdrqSet
    mov x1,8
    mov x8,133                 // appel fonction systeme rt_sigsuspend
    svc 0 
    //affregtit retour133 0
    ldr x0,qAdrszMessageFinThread
    bl affichageMess
    affregtit variablesfils1 18
    mov x0,#100                // pour verif de ce code retour
    b 100f
99:                            // affichage erreur fils
    ldr x1,qAdrszMessErreur
    bl   afficheErreur
    mov x0,#-1                 // code erreur
    b 100f
100:
    ldp x1,lr,[sp],16          // restaur des  2 registres
    //ret
    mov x8,EXIT                // appel fonction systeme pour terminer
    svc 0
qAdrqSet:                 .quad qSet
qAdrszMessageFinThread:   .quad szMessageFinThread
qAdrszMessageThread:      .quad szMessageThread
