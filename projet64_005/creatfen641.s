/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* creation fenêtre simple X11 assembleur ARM64 */
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM64.inc"

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne: .asciz  "\n"
szMessErreur: .asciz "Serveur X non trouvé.\n"
.equ LGMESSERREUR, . -  szMessErreur /* calcul de la longueur de la zone precedente */
szMessErrfen: .asciz "Création fenetre impossible.\n"
.equ LGMESSERRFEN, . -  szMessErreur /* calcul de la longueur de la zone precedente */

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
qDisplay:   .skip 8      /* pointeur vers Display */
ds:         .skip 8      /* pointeur vers l'écran par defaut */
w:          .skip 8      /* pointeur vers la fenêtre */
eve:        .skip 400    /* revoir cette taille */

buffer:  .skip 500 

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text           
.global main                   // 'main' point d'entrée doit être  global

main:                          // programme principal
    mov x0,#0                  // ouverture du serveur X
    bl XOpenDisplay
    cmp x0,#0
    beq erreur
                               //  Ok retour zone display */
    ldr x1,qAdrqDisplay
    str x0,[x1]                // stockage adresse du DISPLAY dans zone d
    mov x28,x0                 // mais aussi dans le registre 28
    add x1,x0,200
    //affmemtit debut x1 10
                               // recup ecran par defaut
    ldr x2,[x0,#264]           // situé à la 264 position */
    ldr x1,=ds
    str x2,[x1]                //stockage   default_screen
    affregtit debut1 0
    mov x2,x0
    ldr x0,[x2,#232]           // pointeur de la liste des écrans
    //add x1,x2,232
    affmemtit debut x0 10
    affregtit debut1_0 0
    //zones ecran
    ldr x5,[x0,#+88]          // white pixel
    ldr x3,[x0,#+96]          // black pixel
    ldr x4,[x0,#+56]          // bits par pixel
    ldr x1,[x0,#+16]          // root windows
    affregtit debut1_1 0
    /* CREATION DE LA FENETRE       */
    mov x0,x28               //display
    mov x2,#0                // position X 
    mov x3,#0                // position Y
    mov x4,600               // largeur
    mov x5,400               // hauteur
    mov x6,0                 // bordure ???
    ldr x7,0                 // ?
    ldr x8,qBlanc            // fond
    str x8,[sp,-16]!         // passé par la pile
    bl XCreateSimpleWindow
    add sp,sp,16             // alignement pile
    cmp x0,#0
    beq erreurF
    mov x3,sp
    affregtit debut3 0
    ldr x1,=w
    str x0,[x1]          /   / stockage adresse fenetre dans zone w
    
    /* affichage de la fenetre */
    mov x1,x0               // adresse fenetre
    mov x0,x28              // adresse du display
    bl XMapWindow
    //mov x0,x28           // adresse du display
    //bl XFlush           // TODO Voir utilisation

1:                          // boucle des evenements
    mov x0,x28              // adresse du display
    ldr x1,=eve             // adresse evenements
    bl XNextEvent
    affregtit event 0
    b 1b
    
    b 100f                 // saut vers fin normale du programme
erreurF:                   // erreur creation fenêtre mais ne sert peut être à rien car erreur directe X11  */
    ldr x0,=szMessErrfen   // x0 ← adresse chaine
    mov x1,#LGMESSERRFEN   // longueur de la chaine
    bl affichageMess       // appel procedure
    b 100f
erreur:                    // erreur car pas de serveur X   (voir doc putty et serveur Xming )*/
    ldr x0,=szMessErreur   // x0 ← adresse chaine
    mov x1,#LGMESSERREUR   // longueur de la chaine
    bl affichageMess       // appel procedure

100:                       // fin de programme standard
    mov x0,#0              // code retour  *
    mov x8, #EXIT          // appel fonction systeme pour terminer
    svc 0 
qBlanc:             .quad 0xF0F0F0F0
qAdrqDisplay:       .quad qDisplay
/************************************/
 