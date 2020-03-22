/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/* création fenetre X11 pour affichage simulation   */
/* d'un banc de poisson dans un aquarium   */


    /* attention x19  pointeur display */
    /* attention x20  pointeur ecran   */
    /* attention x21  référence fenêtre principale   */
    /* attention x22  pointeur vers la structure fenêtre principale */
    /* attention x23  pointeur vers le contexte graphique principal */

/*********************************************/
/*constantes                                 */
/********************************************/
.equ NBPOISSONS,     300
.equ NBMAXOBSTACLES, 50
.equ PAS,           3
.equ DISTANCE_MIN,  10
.equ DISTANCE_MIN_CARRE,  DISTANCE_MIN * DISTANCE_MIN
.equ DISTANCE_MAX,  40 
.equ DISTANCE_MAX_CARRE,  DISTANCE_MAX * DISTANCE_MAX
.equ ATTENTE,       50000000   // en microsecondes
.equ RAYONOBS,      10         // rayon des obstacles
.equ TEMPSMAXI,     100        // temps de vie d'un obstacle

// le ficher des constantes générales est en fin du programme
.equ LARGEUR,           600   // largeur de la fenêtre
.equ HAUTEUR,           400   // hauteur de la fenêtre
.equ LGBUFFER,          1000  // longueur du buffer 

//.equ O_RDONLY,     0
//.equ OPEN,         56
//.equ CLOSE,        57
.equ PSELECT,        72       // call system Linux
//.equ AT_FDCWD,    -100

/* constantes X11 */
.equ KeyPressed,    2
.equ ButtonPress,   4
.equ MotionNotify,  6
.equ EnterNotify,   7
.equ LeaveNotify,   8
.equ Expose,        12
.equ ClientMessage, 33
.equ KeyPressMask,  1
.equ ButtonPressMask,     4
.equ ButtonReleaseMask,   8
.equ ExposureMask,        1<<15
.equ StructureNotifyMask, 1<<17
.equ EnterWindowMask,     1<<4
.equ LeaveWindowMask,     1<<5 
.equ ConfigureNotify,     22


.equ GCForeground,   1<<2
.equ GCBackground,   1<<3
.equ GCLine_width,   1<<4
.equ GCLine_style,   1<<5
.equ GCFont,         1<<14

.equ CWBackPixel,    1<<1
.equ CWBorderPixel,  1<<3
.equ CWEventMask,    1<<11
.equ CWX,            1<<0
.equ CWY,            1<<1
.equ CWWidth,        1<<2
.equ CWHeight,       1<<3
.equ CWBorderWidth,  1<<4
.equ CWSibling,      1<<5
.equ CWStackMode,    1<<6


.equ InputOutput,    1
.equ InputOnly,      2

.equ InputHint,        1 << 0
.equ StateHint,        1 << 1
.equ IconPixmapHint,   1<< 2
.equ IconWindowHint,   1 << 3
.equ IconPositionHint, 1<< 4
.equ IconMaskHint,     1<< 5
.equ WindowGroupHint,  1<< 6
.equ UrgencyHint,      1 << 8
.equ WithdrawnState,   0
.equ NormalState,      1   /* most applications start this way */
.equ IconicState,      3   /* application wants to start as an icon */

.equ USPosition,   1 << 0   /* user specified x, y */
.equ USSize,       1 << 1   /* user specified width, height */
.equ PPosition,    1 << 2   /* program specified position */
.equ PSize,       (1 << 3)   /* program specified size */
.equ PMinSize,    (1 << 4)   /* program specified minimum size */
.equ PMaxSize,    (1 << 5)   /* program specified maximum size */
.equ PResizeInc,  (1 << 6)   /* program specified resize increments */
.equ PAspect,     (1 << 7)   /* program specified min and max aspect ratios */
.equ PBaseSize,   (1 << 8)
.equ PWinGravity,  (1 << 9)

.equ Button1MotionMask, 1<<8
.equ Button2MotionMask, 1<<9 
.equ ButtonMotionMask,  (1<<13)

.equ CoordModeOrigin,   0
.equ CoordModePrevious, 1
.equ XYPixmap,          1
.equ ZPixmap,           2


/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/***********************************/
/* description des structures */
/***********************************/
.include "../defStruct64.inc"

/* structures internes au programme */
/* INFO: structure poisson  */
    .struct  0
poisson_X:                     // position X
    .struct  poisson_X + 8 
poisson_Y:                     // position Y
    .struct  poisson_Y + 8 
poisson_vitesseX:                     // vitesse X
    .struct  poisson_vitesseX + 8 
poisson_vitesseY:                     // vitesse Y
    .struct  poisson_vitesseY + 8 
poisson_fin:
/* INFO: structure obstacle  */
    .struct  0
obstacle_X:                       // position X
    .struct  obstacle_X + 8 
obstacle_Y:                       // position Y
    .struct  obstacle_Y + 8 
obstacle_rayon:                   // rayon
    .struct  obstacle_rayon + 8 
obstacle_temps:                   // temps restant de vie
    .struct  obstacle_temps + 8 
obstacle_fin:
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szNomFenetre:            .asciz "Fenetre Raspberry"
szRetourligne:           .asciz  "\n"
szMessDebutPgm:          .asciz "Debut du programme. \n"
szMessFinPgm:            .asciz "Fin normale du programme. \n" 
szMessErreurGen:         .asciz "Erreur rencontrée. Arrêt programme.\n"
szMessErreur:            .asciz "Serveur X non trouvé.\n"
szMessErrfen:            .asciz "Création fenetre impossible.\n"
szMessErreurX11:         .asciz "Erreur fonction X11. \n"
szMessErrGc:             .asciz "Création contexte graphique impossible.\n"
szMessErrGcBT:           .asciz "Création contexte graphique Bouton impossible.\n"
szMessErrbt:             .asciz "Création bouton impossible.\n"
szMessErrGPolice:        .asciz "Chargement police impossible.\n"
szTitreFenRed:           .asciz "Pi"   
szTitreFenRedS:          .asciz "PiS"  
szRouge:                 .asciz "red"
szBleu:                  .asciz "blue"
szBlack:                 .asciz "black"
szWhite:                 .asciz "white"

szMessErrAngle:          .asciz "Erreur angle > 2PI."

/* libellé special pour correction pb fermeture */
szLibDW:                 .asciz "WM_DELETE_WINDOW"

//szNomRepDepart:          .asciz "."

/* polices de caracteres */
szNomPolice:             .asciz  "-*-helvetica-bold-*-normal-*-14-*"
szNomPolice1:            .asciz  "-*-fixed-bold-*-normal-*-14-*"

szMessErreur1:           .asciz "Erreur ouverture fichier.\n"
szMessErreur2:           .asciz "Erreur lecture fichier.\n"
.align 4
hauteur:                 .quad HAUTEUR
largeur:                 .quad LARGEUR

/* tables constantes départ algorithme CORDIC*/
tbArcTanC:          .double 0.7854
                    .double 0.46365
                    .double 0.24498
                    .double 0.12435
                    .double 0.06242
                    .double 0.03124
                    .double 0.01562
                    .double 0.00781
                    .double 0.00391
                    .double 0.00195
                    .double 0.00098
                    .double 0.00049
                    .double 0.00024
                    .double 0.00012
                    .double 0.00006

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
qAdrFicName:            .skip 8     // addresse du nom de fichier dans ligne de commande
ptDisplay:              .skip 8     // pointeur display
ptEcran:                .skip 8     // pointeur ecran standard
ptGC:                   .skip 8     // pointeur contexte graphique
ptGC1:                  .skip 8     // pointeur contexte graphique 1
ptGC2:                  .skip 8     // pointeur contexte graphique 2
ptPolice:               .skip 8     // pointeur police de caractères
ptPolice1:              .skip 8     // pointeur police de caractères 1
ptCurseur:              .skip 8     // pointeur curseur
idFenSec2:              .skip 8     // pointeur curseur

.align 4
wmDeleteMessage:        .skip 16      // identification message de fermeture
event:                  .skip 400     // TODO revoir cette taille 
sBuffer:                .skip LGBUFFER 

/* Structures des données */  
.align 4
stAttributs:           .skip Att_fin       // reservation place structure Attibuts 
.align 4
stXGCValues:           .skip XGC_fin       // reservation place structure XGCValues
.align 4
stFenetreAtt:          .skip Win_fin       // reservation place attributs fenêtre
.align 4  
stWmHints:             .skip  Hints_fin    // reservation place pour structure XWMHints 
.align 4
stAttrSize:            .skip XSize_fin     // reservation place structure XSizeHints
.align 4

.align 4
Closest:               .skip XColor_fin    // reservation place structure XColor
Exact:                 .skip XColor_fin
Front:                 .skip XColor_fin
Backing:               .skip XColor_fin
TableFenetres:
stFenetrePrinc:        .skip  Win_fin      // reservation place structure fenêtre
stFenetreSec1:         .skip  Win_fin      // reservation place structure fenêtre
stFenetreFin:          .skip  Win_fin     // structure de la fin de la table des fenetre
.align 4
qColorType:            .skip 8
qBit_depth:            .skip 8

in_fds:                .skip 128
timeval:
    tv_sec:            .skip 8           // secondes
    tv_usec:           .skip 8           // microsecondes
qNbObstacles:           .skip 8
tbPoisson:             .skip poisson_fin * NBPOISSONS      // table des poissons
tbObstacle:            .skip obstacle_fin * NBMAXOBSTACLES // table des onstacles
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text           
.global main                            // 'main' point d'entrée doit être  global 

main:                                   // INFO:programme principal
    ldr x0,qAdrszMessDebutPgm           // adresse message debut 
    bl affichageMess                    // affichage message dans console

    /* ouverture du serveur X */
    bl ConnexionServeur
    cbz x0,erreurServeur

    /* chargement des polices */
    bl chargementPolices
    cmp x0,#0
    cbz x0,erreurGénérale

    /* chargement couleurs */
    bl chargementCouleurs
    cbz x0,erreurGénérale

    /* création de la fenetre principale */
    ldr x22,qAdrstFenetrePrinc
    bl creationFenetrePrincipale
    cmp x0,#0
    cbz x0,erreurF

    /*  creation des contextes graphiques */
    bl creationGC
    cbz x0,erreurGC

    mov x0,x19    // display
    bl XFlush

    affichelib creationocean
    bl creerOcean

   /* boucle des evenements */
    bl gestionAttenteEvenements

                                           // fin des évenements liberation des ressources
    mov x0,x19                             // adresse du display 
    ldr x1,qAdrptGC
    ldr x1,[x1]                            // adresse du contexte 
    bl XFreeGC
    cmp x0,#0
    blt erreurX11
    mov x0,x19                             // adresse du display 
    ldr x1,qAdrptGC1
    ldr x1,[x1]                            // adresse du contexte 
    bl XFreeGC
    cmp x0,#0
    blt erreurX11
    mov x0,x19                             // adresse du display 
    mov x1,x21                             // adresse de la fenetre 
    bl XDestroyWindow
    cmp x0,#0
    blt erreurX11
    mov x0,x19
    bl XCloseDisplay
    cmp x0,#0
    blt erreurX11
    ldr x0,qAdrszMessFinPgm               // fin programme OK
    bl affichageMess                      // affichage message dans console   
    mov x0,#0                             // code retour OK  
    b 100f

erreurF:                                  // erreur creation fenêtre mais ne sert peut être à  rien car erreur directe X11  */
    ldr x1,qAdrszMessErrfen   
    bl   afficheErreur   
    mov x0,#1                             // code erreur
    b 100f
erreurGC:                                 // erreur creation contexte graphique
    ldr x1,qAdrszMessErrGc  
    bl   afficheErreur  
    mov x0,#1                             // code erreur
    b 100f
erreurX11:                                // erreur X11
    ldr x1,qAdrszMessErreurX11   
    bl   afficheErreur   
    mov x0,#1                             // retour erreur
    b 100f
erreurServeur:                            // erreur car pas de serveur X   (voir doc putty et serveur Xming )*/
    ldr x1,qAdrszMessErreur  
    bl   afficheErreur   
    mov x0,#1                             // retour erreur
    b 100f
erreurGénérale:                            // erreur car pas de serveur X   (voir doc putty et serveur Xming )*/
    ldr x1,qAdrszMessErreurGen
    bl   afficheErreur   
    mov x0,#1                             // retour erreur
    b 100f
100:                                      // fin de programme standard
    mov x8, #EXIT                         // appel fonction systeme pour terminer
    svc 0 

qAdrszMessDebutPgm:     .quad szMessDebutPgm
qAdrszMessFinPgm:       .quad szMessFinPgm
qAdrszMessErreur:       .quad szMessErreur
qAdrptDisplay:          .quad ptDisplay
qAdrptEcran:            .quad ptEcran
qAdrstFenetrePrinc:     .quad stFenetrePrinc
qAdrszMessErreurGen:    .quad szMessErreurGen
qAdridFenSec2:          .quad idFenSec2
/********************************************************************/
/*   Connexion serveur X et recupération informations du display  ***/
/********************************************************************/    
/* retourne dans x19 le pointeur vers le Display */
/* retourne dans x20 le pointeur vers l'écran  */
ConnexionServeur:                      // INFO: ConnexionServeur
    stp x2,lr,[sp,-16]!               // save  registres
    mov x0,#0
    bl XOpenDisplay                   // ouverture du serveur X
    mov x19,x0
    cmp x0,#0
    beq 100f                          // serveur non actif 
    ldr x2,[x19,#Disp_default_screen] // recup ecran par defaut
    ldr x20,[x19,#Disp_screens]       // pointeur de la liste des écrans
    // remarque : dans ce programme utilisation du seul premier ecran
    // sinon revoir les instructions de récupèration du bon écran 
    //add x1,x1,x2,lsl #3                 // récup du pointeur de l'écran par defaut
    //affmemtit ecrans_disp x0 20
    //mov x1,x20
    //affmemtit ecrans_ecr x1 10
100:
    ldp x2,lr,[sp],16                // restaur des  2 registres
    ret                             // retour adresse lr x30
/********************************************************************/
/*   Chargement des polices utilisées                             ***/
/********************************************************************/    
// x19 pointeur vers le Display
chargementPolices:                     // INFO: chargementPolices
    stp x1,lr,[sp,-16]!              // save  registres  
    mov x0,x19
    ldr x1,qAdrszNomPolice           // nom de la police 
    bl XLoadQueryFont
    cmp x0,#0
    beq 99f                          // police non trouvée  
    //affregtit police1 0
    ldr x1,qAdrptPolice
    str x0,[x1]
    mov x0,x19                        // Display
    ldr x1,qAdrszNomPolice1          // nom de la police 
    //affregtit police2 0 
    bl XLoadQueryFont
    cmp x0,#0
    beq 99f                          // police non trouvée 
    ldr x1,qAdrptPolice1
    str x0,[x1]
    b 100f

99:                                  // police non trouvée 
    ldr x1,qAdrszMessErrGPolice  
    bl   afficheErreur   
    mov x0,#0

100:
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszNomPolice:      .quad szNomPolice
qAdrszNomPolice1:     .quad szNomPolice1
qAdrptPolice:         .quad ptPolice
qAdrptPolice1:        .quad ptPolice1
qAdrszMessErrGPolice: .quad szMessErrGPolice
/********************************************************************/
/*   Chargement des couleurs utilisées                             ***/
/********************************************************************/    
// x19 pointeur vers le Display
// x20 pointeur vers l'écran
chargementCouleurs:                     // INFO:chargementCouleurs
    stp x21,lr,[sp,-16]!        // save  registres 

    /* chargement couleurs */
    mov x0,x19
    mov x1,#0
    bl XDefaultColormap
    cmp x0,#0
    beq 2f
    mov x21,x0                     // save colormap
    mov x1,x0                      // pointeur colormap
    mov x0,x19                      // display
    ldr x2,qAdrszBleu
    ldr x3,qAdrExact
    ldr x4,qAdrClosest
    bl XAllocNamedColor
    cmp x0,#0
    beq 2f
    //ldr x0,qAdrClosest
    //ldr x0,[x0,#XColor_pixel]
    mov x1,x21                     // pointeur colormap
    mov x0,x19                      // display
    ldr x2,qAdrszBlack             // couleur noir
    ldr x3,qAdrExact
    ldr x4,qAdrFront
    bl XAllocNamedColor
    cmp x0,#0
    beq 2f
    mov x1,x21                      // pointeur colormap
    mov x0,x19                      // display
    ldr x2,qAdrszWhite             // couleur blanc
    ldr x3,qAdrExact
    ldr x4,qAdrBacking
    bl XAllocNamedColor
    cmp x0,#0
    beq 2f

    b 100f
2:                                 // pb couleur 
    ldr x1,qAdrszMessErreurX11 
    bl   afficheErreur   
    mov x0,#0                      // code erreur
100:
    ldp x21,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

qAdrszRouge:  .quad szRouge
qAdrszBleu:  .quad szBleu
qAdrszBlack:  .quad szBlack
qAdrszWhite:  .quad szWhite
qAdrClosest:  .quad Closest
qAdrExact:    .quad Exact
qAdrBacking:  .quad Backing
qAdrFront:    .quad Front
/********************************************************************/
/*   Creation de la fenêtre principale                                   ***/
/********************************************************************/
/* x19 contient le Display */
/* x20 le pointeur écran */
/* x22 le poniteur structure fenêtre */
/* x21 contiendra l'identifiant de la fenêtre  */
creationFenetrePrincipale:                  // INFO: creationFenetrePrincipale
    stp x22,lr,[sp,-16]!                    // save  registres 

                                            // calcul de la position X pour centrer la fenetre
    ldr x2,[x20,#Screen_width]              // récupération de la largeur de l'écran racine
    sub x2,x2,#LARGEUR                      // soustraction de la largeur de notre fenêtre
    lsr x2,x2,#1                            // division par 2 et résultat pour le parametre 3
    ldr x3,[x20,#Screen_height]             // récupération de la hauteur de l'écran racine
    sub x3,x3,#HAUTEUR                      // soustraction de la hauteur de notre fenêtre
    lsr x3,x3,#1                            // division par 2 et résultat pour le parametre 4
    
    /* CREATION DE LA FENETRE */
    mov x0,x19                              // display
    ldr x1,[x20,#Screen_root]               // identification écran racine
                                            // x2 et x3 ont été calculés plus haut
    mov x4,#LARGEUR                         // largeur 
    mov x5,#HAUTEUR                         // hauteur
    mov x6,#3                               // bordure
    ldr x7,[x20,#Screen_black_pixel]        // couleur bordure
    ldr x8,qAdrClosest
    ldr x8,[x8,#XColor_pixel]               // couleur du fond
    stp x8,x8,[sp,-16]!                     // passé par la pile
    bl XCreateSimpleWindow
    add sp,sp,16                            // alignement pile
    cmp x0,#0
    beq 98f
    mov x21,x0                             // stockage adresse fenetre dans le registre x9 pour usage ci dessous
    str x0,[x22,#Win_id]                   // et dans la structure

    /* ajout directives pour le serveur */
    mov x0,x19                             // display
    mov x1,x21                             // adresse fenêtre
    ldr x2,qAdrstAttrSize                  // structure des attributs 
    ldr x3,qatribmask                      // masque des attributs
    str x3,[x2,#XSize_flags]
    bl XSetWMNormalHints
    /* ajout directives pour etat de la fenêtre */
    ldr x2,qAdrstWmHints                  // structure des attributs 
    mov x3,#NormalState                   // etat normal pour la fenêtre
    str x3,[x2,#Hints_initial_state]
    mov x3,#StateHint                     // etat initial
    str x3,[x2,#Hints_flags]
    mov x0,x19                             // adresse du display 
    mov x1,x21                             // adresse fenetre 
    bl XSetWMHints
    //affregtit apresWMhints 0
        /* ajout de proprietes de la fenêtre */
    mov x0,x19                             // adresse du display 
    mov x1,x21                             // adresse fenetre 
    ldr x2,qAdrszNomFenetre               // titre de la fenêtre 
    ldr x3,qAdrszTitreFenRed              // titre de la fenêtre reduite 
    mov x4,#0                             // pointeur vers XSizeHints éventuellement
    mov x5,#0                             // nombre d'aguments ligne de commande 
    mov x6,#0                             // adresse arguments de la ligne de commande
    mov x7,#0
    bl XSetStandardProperties
    /* Correction erreur fermeture fenetre */
    mov x0,x19                             // adresse du display
    ldr x1,qAdrszLibDW                    // adresse nom de l'atome
    mov x2,#1                             // False  création de l'atome s'il n'existe pas
    bl XInternAtom
    cmp x0,#0
    ble 99f
    ldr x1,qAdrwmDeleteMessage            // adresse de reception
    str x0,[x1]
    mov x2,x1                             // adresse zone retour precedente
    mov x0,x19                             // adresse du display
    mov x1,x21                             // adresse fenetre
    mov x3,#1                             // nombre de protocoles 
    bl XSetWMProtocols
    cmp x0,#0
    ble 99f
    
    /* affichage de la fenetre */
    mov x0,x19                             // adresse du display
    mov x1,x21                             // adresse fenetre
    bl XMapWindow
    
    /* autorisation des saisies */
    mov x0,x19                             // adresse du display
    mov x1,x21                             // adresse de la fenetre
    ldr x2,qFenetreMask                   // masque pour autoriser saisies
    bl XSelectInput
    cmp x0,#0
    ble 99f
    /* chargement des donnees dans la structure */
    mov x0,x19                             // adresse du display
    mov x1,x21                             // adresse de la fenetre
    mov x2,x22
    bl XGetWindowAttributes
    cmp x0,#0
    ble 99f
    // pas d'erreur



    ldr x0,qAdrevtFenetrePrincipale
    str x0,[x22,#Win_procedure]
    mov x0,x21                              // retourne l'identification de la fenetre
    b 100f
    
98:                                        // erreur fenetre 
    ldr x1,qAdrszMessErrfen   
    bl   afficheErreur  
    mov x0,#0                              // code erreur 
    b 100f
99:                                        // erreur X11
    ldr x1,qAdrszMessErreurX11  
    bl   afficheErreur  
    mov x0,#0                              // code erreur 
    b 100f

100:
    ldp x22,lr,[sp],16                     // restaur des  2 registres
    ret                                    // retour adresse lr x30

qFenetreMask:             .quad  KeyPressMask|ButtonPressMask|StructureNotifyMask|ExposureMask|EnterWindowMask
qGris1:                   .quad 0xFFA0A0A0
qAdrhauteur:              .quad hauteur
qAdrlargeur:              .quad largeur
qAdrszNomFenetre:         .quad  szNomFenetre
qAdrszTitreFenRed:        .quad szTitreFenRed
qAdrszMessErreurX11:      .quad szMessErreurX11
qAdrszMessErrfen:         .quad szMessErrfen
qAdrszLibDW:              .quad szLibDW
qAdrwmDeleteMessage:      .quad wmDeleteMessage
qAdrstAttrSize:           .quad stAttrSize
qatribmask:               .quad USPosition | USSize
qAdrstWmHints :           .quad stWmHints 
qAdrevtFenetrePrincipale: .quad evtFenetrePrincipale

/********************************************************************/
/*   Création contexte graphique                                  ***/
/********************************************************************/    
/* x19 contient le display, x20 l'écran, x21 la fenêtre */
creationGC:                    // INFO: creationGC
    stp x19,lr,[sp,-16]!       // save  registres 
    /* creation contexte graphique simple */
    mov x0,x19                // adresse du display
    mov x1,x21                // adresse fenetre
    mov x2,#0
    mov x3,#0
    bl XCreateGC
    cmp x0,#0
    beq 99f    
    ldr x1,qAdrptGC
    str x0,[x1]               // stockage adresse contexte graphique   
    mov x23,x0                // et stockage dans x23
    mov x0,x19                // adresse du display 
    mov x1,x23                // adresse GC 
    ldr x2,[x20,#Screen_white_pixel]
    bl XSetForeground
    cmp x0,#0
    beq 99f    
    mov x0,x19                // adresse du display 
    mov x1,x23                // adresse GC 
    ldr x2,[x20,#Screen_black_pixel]
    bl XSetBackground
    cmp x0,#0
    beq 99f    

    /* création contexte graphique avec autre couleur de fond */
    mov x0,x19                 // adresse du display 
    mov x1,x21                 // adresse fenetre 
    mov x2,#0
    mov x3,#0
    bl XCreateGC
    cmp x0,#0
    beq 99f
    ldr x1,qAdrptGC1
    str x0,[x1]                 // stockage adresse contexte graphique dans zone gc2 
    mov x1,x0                   // adresse du nouveau GC
    mov x0,x19                   // adresse du display 
    ldr x2,qAdrClosest
    ldr x2,[x2,#XColor_pixel]   // fond rouge identique à la fenêtre principale
    bl XSetBackground
    cmp x0,#0
    beq 99f    
    mov x0,x19                   // adresse du display 
    ldr x1,qAdrptGC1
    ldr x1,[x1]                 // stockage adresse contexte graphique dans zone gc2 
    //ldr x2,[x20,#Screen_white_pixel]
    ldr x2,qAdrClosest
    ldr x2,[x2,#XColor_pixel]   // fond rouge identique à la fenêtre principale
    bl XSetForeground
    cmp x0,#0
    beq 99f    
    
    /* creation contexte graphique simple BIS */
    mov x0,x19                   // adresse du display
    mov x1,x21                   // adresse fenetre
    mov x2,#0
    mov x3,#0
    bl XCreateGC
    cmp x0,#0
    beq 99f    
    ldr x1,qAdrptGC2
    str x0,[x1]                 // stockage adresse contexte graphique  
    b 100f

99:                             // erreur creation contexte graphique
    ldr x1,qAdrszMessErrGc  
    bl   afficheErreur  
    mov x0,#0                   //code erreur
    b 100f

100:
    ldp x19,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qRouge:             .quad 0xFFFF0000
qAdrptGC:           .quad ptGC
qAdrptGC1:          .quad ptGC1
qAdrptGC2:          .quad ptGC2
qAdrszMessErrGc:    .quad szMessErrGc
qGC1mask:           .quad GCFont
qGCmask:            .quad GCFont
qAdrstXGCValues:    .quad stXGCValues
/********************************************************************/
/*   Gestion des évenements                                       ***/
/********************************************************************/
gestionAttenteEvenements:        //INFO: gestionAttenteEvenements
    stp x19,lr,[sp,-16]!         // save  registres 
    mov x0,x19                   // display
    bl XConnectionNumber         // recup FD connexion
    mov x25,x0
    ldr x26,qAdrin_fds
1:
    mov x11,0                    // boucle init zone set FD
11:
    str xzr,[x26,x11,lsl 3]      // init zones FD
    add x11,x11,1
    cmp x11,128/8
    blt 11b
    mov x1,1
    lsl x1,x1,x25                // mise à jour du bit correspondant au FD
    str x1,[x26]                 // mise à jour zones FD 
    ldr x12,qAdrtv_usec          // mise à jour du délai d'attente
    ldr x13,qAttente             // délai en microsecondes
    str x13,[x12]
    ldr x12,qAdrtv_sec
    mov x13,0                    // delai en seconde
    str x13,[x12]

    add x0,x25,1                 // emplacement bit FD
    ldr x1,qAdrin_fds
    mov x2,0
    mov x3,0
    ldr x4,qAdrtimeval
    mov x5,0
    mov x8,PSELECT               // call system pselect6
    svc 0
    cmp x0,0                     // evenement ?
    bne 3f                       // oui
    bl mettreAJourPoissons

3:
    mov x0,x19
    bl XPending                 // recup nb evenements
    cbz x0,4f                   // pas d'evt
    bl gestionEvenements
    cbnz x0,100f                // fin du programme
    b 3b
4:
    b 1b                        // boucle
100:
    ldp x19,lr,[sp],16          // restaur des  2 registres
    ret                         // retour adresse lr x30
qAdrin_fds:            .quad in_fds
qAdrtimeval:           .quad timeval
qAdrtv_usec:           .quad tv_usec
qAdrtv_sec:            .quad tv_sec
qAttente:              .quad ATTENTE
/********************************************************************/
/*   Gestion des évenements                                       ***/
/********************************************************************/
gestionEvenements:               // INFO: gestionEvenements
    stp x19,lr,[sp,-16]!         // save  registres 
    mov x0,x19                   // adresse du display
    ldr x1,qAdrevent             // adresse evenements
    bl XNextEvent
    //affregtit nexeevent  0
    ldr x0,qAdrevent
                                // Quelle fenêtre est concernée ?
    ldr x0,[x0,#XAny_window]
    ldr x3,qAdrTableFenetres    // tables des structures des fenêtres
    mov x2,#0                   // indice de boucle
1:                              // debut de boucle de recherche de la fenêtre
    mov x4,#Win_fin             // longueur de chaque structure
    mul x4,x2,x4                // multiplié par l'indice de boucle
    add x4,x4,x3                   // et ajouté au début de table 
    ldr x1,[x4,#Win_id]         // recup ident fenêtre dans table des structures
    //affregtit rechfen 0
    cmp x1,#0                   // fin de la table ?
    beq 3f                      // on termine la recherche
    cmp x0,x1                   // fenetre table = fenetre évenement ?
    beq 2f
    add x2,x2,#1                // non
    b 1b                        // on boucle
2:
    ldr x2,[x4,#Win_procedure]  // fenetre trouvée, chargement de la procèdure à executer
    ldr x0,qAdrevent            // adresse de l'évenement
    cmp x2,#0                   // vérification si procédure est renseigne avant l'appel
    beq 3f                      // on termine la recherche
    blr x2                      // appel de la procèdure à executer pour la fenêtre
                                // le code retour dans x0 est positionné dans la routine
    b 100f
3:
    mov x0,0
100:
    ldp x19,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

qAdrevent:         .quad event
qAdrTableFenetres: .quad TableFenetres
/********************************************************************/
/*   Evenements de la fenêtre principale                          ***/
/********************************************************************/
// x0 doit contenir le pointeur sur l'evenement
// sauvegarde des registres
evtFenetrePrincipale:           // INFO: evtFenetrePrincipale
    stp x19,lr,[sp,-16]!        // save  registres 
    ldr w0,[x0,#XAny_type]      // 4 premiers octets
    cmp w0,#ClientMessage       // cas pour fermeture fenetre sans erreur 
    beq fermetureFen
    cmp w0,#ButtonPress         // cas d'un bouton souris
    beq evtboutonsouris
    cmp w0,#Expose              // cas d'une modification de la fenetre ou son masquage
    beq evtexpose
    cmp w0,#ConfigureNotify     // cas pour modification de la fenetre 
    beq evtconfigure
    cmp w0,#EnterNotify         // la souris passe sur une fenêtre
    beq evtEnterNotify
    mov x0,#0
    b 100f
/***************************************/    
fermetureFen:                   // clic sur menu systeme */
    //affregtit fermeture 0
    ldr x0,qAdrevent            // evenement de type XClientMessageEvent
    ldr x1,[x0,#XClient_data]   // position code message
    ldr x2,qAdrwmDeleteMessage
    ldr x2,[x2]
    mov x3,1
    cmp x1,x2
    csel x0,x3,xzr,eq

    b 100f
/***************************************/    
evtexpose:                       // masquage ou modification fenetre
    mov x0,x19                    // adresse du display


    mov x0,#0
    b 100f
evtconfigure:
    ldr x0,qAdrevent
    ldr x1,[x0,#+XConfigureEvent_width]
    ldr x2,qAdrlargeur
    ldr x3,[x2]
    cmp x1,x3                    // modification de la largeur ?
    beq evtConfigure1
    str x1,[x2]                  // maj nouvelle largeur
evtConfigure1:
    mov x0,#0
    b 100f
evtEnterNotify:
    mov x0,x19                    // adresse du display 

    mov x0,#0
    b 100f
evtboutonsouris:
    ldr x0,qAdrevent
    //affmemtit souris x0 6
    ldr w1,[x0,64]      //Recup position X clic
    ldr w2,[x0,68]      // Recup position Y clic
    //affregtit souris 0
    ldr x10,qAdrtbObstacle
    ldr x11,qAdrqNbObstacles
    ldr x12,[x11]
    cmp x12,NBMAXOBSTACLES
    bge 1f
    mov x13,obstacle_fin
    madd x14,x12,x13,x10
    //affregtit souris1 10
    str x1,[x14,obstacle_X]
    str x2,[x14,obstacle_Y]
    mov x13,RAYONOBS
    str x13,[x14,obstacle_rayon]
    mov x13,TEMPSMAXI
    str x13,[x14,obstacle_temps]
    add x12,x12,1
    str x12,[x11]        // mise à jour compteur
   //affregtit souris2 10
1:
    mov x0,#0
    b 100f

99:
    ldr x1,qAdrszMessErreurX11   // erreur X11
    bl   afficheErreur   
    mov x0,#0
100:
    ldp x19,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrqNbObstacles:         .quad qNbObstacles
/********************************************************************/
/*   Création des poissons dans l'océan                           ***/
/********************************************************************/
creerOcean:                  // INFO: creerOcean
    stp x20,lr,[sp,-16]!     // save  registres 
    ldr d1,dfPI2
    mov x20,0
    mov x10,100             // multiplicateur
    fmov d20,x10
    scvtf d20,d20              // et conversion en float
1:
    mov x0,LARGEUR
    bl genererAlea
    mov x1,x0               // pos X aléatoire
    mov x0,HAUTEUR
    bl genererAlea
    mov x2,x0               // pos Y aléatoire
    mov x0,628              // maxi 2PI * 100
    bl genererAlea
    fmov d0,x0              // angle aléatoire
    scvtf d0,d0             // et conversion en float 
    fdiv d0,d0,d20           // division par 100 pour l'avoir en radian
    mov x0,x20              // index
    bl creerPoisson
    mov x0,x20
    bl dessinerPoisson

    add x20,x20,1
    cmp x20,NBPOISSONS
    blt 1b                  // et boucle 
100:
    ldp x20,lr,[sp],16      // restaur des  2 registres
    ret                     // retour adresse lr x30
/******************************************************************/
/*     mise à jour des poissons                               */ 
/******************************************************************/
mettreAJourPoissons:         //INFO: mettreAJourPoissons
    stp x24,lr,[sp,-16]!     // save  registres
    stp x25,x26,[sp,-16]!    // save  registres
    stp x27,x28,[sp,-16]!    // save  registres
    ldr x24,qAdrtbPoisson
    mov x25,poisson_fin
    mov x26,0
1:                           // début de boucle de maj
    mov x0,x26               // effacement ancienne position
    bl effacerPoisson
    mov x0,x26
    mov x1,0
    mov x2,0
    mov x3,LARGEUR
    mov x4,HAUTEUR
    bl eviterMur             // 1ère régle : eviter les murs
    cbnz x0,2f
    mov x0,x26
    //b 11f
    bl eviterObstacles       // puis éviter les obstacles
    cbnz x0,2f
    mov x0,x26
    bl eviterPoissons        // puis eviter les autres poissons
    cbnz x0,2f
11:
    mov x0,x26               // puis s'aligner sur les autres
    bl calculerDirectionMoyenne
2:                           // calcul nouvelle position
    madd x12,x25,x26,x24
    mov x2,PAS
    mov x3,100
    fmov d3,x3
    scvtf d3,d3
    ldr d0,[x12,poisson_vitesseX]
    fmul d0,d0,d3
    fcvtas x1,d0
    mul x1,x1,x2
    sdiv x1,x1,x3 
    ldr x0,[x12,poisson_X]
    add x0,x0,x1
    str x0,[x12,poisson_X]
    ldr d0,[x12,poisson_vitesseY]
    fmul d0,d0,d3
    fcvtas x1,d0
    mul x1,x1,x2
    sdiv x1,x1,x3 
    ldr x0,[x12,poisson_Y]
    add x0,x0,x1
    str x0,[x12,poisson_Y]
    mov x0,x26
    bl dessinerPoisson

    add x26,x26,1
    cmp x26,NBPOISSONS
    blt 1b
                             // affichage des onstacles
    ldr x1,qAdrqNbObstacles  // et mise à jour de leur temps de vie
    ldr x25,[x1]
    cbz x25,100f
    mov x24,0
2:
    mov x0,x24
    bl dessinerObstacle
    mov x0,x24
    bl mettreAjourObstacle
    add x24,x24,1
    cmp x24,x25
    blt 2b 
100:
    ldp x27,x28,[sp],16          // restaur des  2 registres
    ldp x25,x26,[sp],16          // restaur des  2 registres
    ldp x24,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/********************************************************************/
/*   creation d'un poisson                          ***/
/********************************************************************/
// x0 doit contenir le pointeur sur la table des poissons
// x1 la position axe des X
// x2 la position axe Y
// d0 la direction en radian
creerPoisson:                     // INFO: creerPoisson
    stp x20,lr,[sp,-16]!          // save  registres 
    ldr x10,qAdrtbPoisson
    mov x11,poisson_fin
    madd x20,x11,x0,x10
    str x1,[x20,poisson_X]
    str x2,[x20,poisson_Y]
                                  // calcul cosinus et sinus à partir de d0
    bl cordic
    str d0,[x20,poisson_vitesseX] // cosinus
    str d1,[x20,poisson_vitesseY] // sinus
100:
    ldp x20,lr,[sp],16            // restaur des  2 registres
    ret                           // retour adresse lr x30
qAdrtbPoisson:          .quad tbPoisson
/********************************************************************/
/*   dessin d'un poisson                          ***/
/********************************************************************/
// x0 doit contenir l'index de la table */
dessinerPoisson:                // INFO: dessinerPoisson
    stp x10,lr,[sp,-16]!        // save  registres 
    stp d1,d2,[sp,-16]!        // save  registres 
    ldr x10,qAdrtbPoisson
    mov x11,poisson_fin
    madd x12,x11,x0,x10
    mov x0,x19                 // display address
    mov x1,x21                 // window ident
    mov x2,x23                 // contexte graphique
    ldr x3,[x12,poisson_X]
    ldr x4,[x12,poisson_Y]
    ldr d1,[x12,poisson_vitesseX]
    fmov d2,10                 // valeur immediate ok -> float
    fmul d1,d1,d2
    fcvtas x5,d1               // conversion float en entier signé
    sub x5,x3,x5
    ldr d1,[x12,poisson_vitesseY]
    fmul d1,d1,d2
    fcvtas x6,d1               // conversion float en entier signé
    sub x6,x4,x6
    bl XDrawLine
100:
    ldp d1,d2,[sp],16
    ldp x10,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
/********************************************************************/
/*   dessin d'un obstacle                          ***/
/********************************************************************/
// x0 doit contenir l'index de la table */
dessinerObstacle:              // INFO: dessinerObstacle
    stp x10,lr,[sp,-16]!       // save  registres 
    ldr x10,qAdrtbObstacle
    mov x11,obstacle_fin
    madd x12,x11,x0,x10
    ldr x0,[x12,obstacle_temps]
    cbz x0,100f                // pas d'affichage si le temps est zero
    //affregtit obstacle 10
    mov x0,x19                 // display address
    mov x1,x21                 // window ident
    mov x2,x23
    ldr x3,[x12,obstacle_X]
    ldr x4,[x12,obstacle_Y]
    ldr x5,[x12,obstacle_rayon]
    mov x6,x5                  // cercle
    mov x7,0                   // angle départ
    mov x8,360 * 64            // angle fin en degré * 64
    stp x8,x8,[sp,-16]!        // passé sur la pile
    bl XDrawArc
    add sp,sp,16               // pour réaligner la pile aorès l'appel
100:
    ldp x10,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrtbObstacle:           .quad tbObstacle
/********************************************************************/
/*   maj temps de vie d'un obstacle                          ***/
/********************************************************************/
// x0 doit contenir l'index de la table */
mettreAjourObstacle:            // INFO: mettreAjourObstacle
    stp x10,lr,[sp,-16]!        // save  registres 
    ldr x10,qAdrtbObstacle
    mov x11,obstacle_fin
    madd x12,x11,x0,x10
    ldr x0,[x12,obstacle_temps]
    cbz x0,100f                // raf si le temps est zero
    sub x0,x0,1
    str x0,[x12,obstacle_temps]
100:
    ldp x10,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
/********************************************************************/
/*   effacement d'un poisson                          ***/
/*   même instructions que le dessin mais               */
/*  avec un GC dont la couleur de dessin est la couleur du fond */
/********************************************************************/
/* x0 doit contenir l'index de la table */
effacerPoisson:                // INFO: effacerPoisson
    stp x10,lr,[sp,-16]!        // save  registres 
    ldr x10,qAdrtbPoisson
    mov x11,poisson_fin
    madd x12,x11,x0,x10
    mov x0,x19                 // display address
    mov x1,x21                 // window ident
    ldr x2,qAdrptGC1           // autre Contexte Graphique
    ldr x2,[x2]
    ldr x3,[x12,poisson_X]
    ldr x4,[x12,poisson_Y]
    ldr d1,[x12,poisson_vitesseX]
    fmov d2,10
    fmul d1,d1,d2
    fcvtas x5,d1
    sub x5,x3,x5
    ldr d1,[x12,poisson_vitesseY]
    fmul d1,d1,d2
    fcvtas x6,d1
    sub x6,x4,x6
    bl XDrawLine
100:
    ldp x10,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     un autre poisson est dans l'alignement                                          */ 
/******************************************************************/
/* x0 contient la valeur de l'index de la table   */
/* x1 contient l'index d'un autre poisson */
dansAlignement:                 //INFO: dansAlignement
    stp x10,lr,[sp,-16]!        // save  registres
    bl calculerDistanceCarre
    mov x10,x0
    mov x0,0
    cmp x10,DISTANCE_MAX_CARRE
    bgt 100f
    cmp x10,DISTANCE_MIN_CARRE
    blt 100f
    mov x0,1                   // le poisson est dans la zone
100:
    ldp x10,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     distance au mur                                          */ 
/******************************************************************/
/* x0 contient la valeur de l'index de la table   */
/* x1 contient la position X mini mur */
/* x2 contient la position Y mini mur */
/* x3 contient la position X maxi mur */
/* x4 contient la position Y maxi mur */
distanceAuMur:                 //INFO: distanceAuMur
    stp x10,lr,[sp,-16]!       // save  registres
    ldr x10,qAdrtbPoisson
    mov x11,poisson_fin
    madd x12,x11,x0,x10        // adresse poisson
    ldr x15,[x12,poisson_X]
    ldr x16,[x12,poisson_Y]
    sub x13,x15,x1             // distance poisson au mur x mini
    sub x14,x16,x2             // distance poisson au mur Y mini 
    cmp x13,x14
    csel x11,x13,x14,lt        // mini entre x1 et x2
    sub x14,x3,x15             // distance poisson au mur X maxi
    cmp x14,x11                // mini 
    csel x11,x14,x11,lt
    sub x13,x4,x16             // distance poisson au mur Y maxi
    cmp x13,x11
    csel x0,x13,x11,lt         // retourne distance mini
    //affregtit distanceMini 0
100:
    ldp x10,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     eviter les murs                                          */ 
/******************************************************************/
/* x0 contient la valeur de l'index de la table   */
/* x1 contient la position X mini mur */
/* x2 contient la position Y mini mur */
/* x3 contient la position X maxi mur */
/* x4 contient la position Y maxi mur */
eviterMur:                        //INFO: eviterMur
    stp x22,lr,[sp,-16]!        // save  registres
    stp x23,x24,[sp,-16]!        // save  registres
    mov x23,x0
    ldr x10,qAdrtbPoisson
    mov x11,poisson_fin
    madd x22,x11,x0,x10        // adresse poisson
    ldr x15,[x22,poisson_X]
    ldr x16,[x22,poisson_Y]
    //affregtit mur 10
    cmp x15,x1
    bge 1f
    str x1,[x22,poisson_X]
    b 10f
1:
    cmp x16,x2
    bge 2f
    str x2,[x22,poisson_Y]
    b 10f
2:
    cmp x15,x3
    ble 3f
    str x3,[x22,poisson_X]
    b 10f
3:
    cmp x16,x4
    ble 10f
    str x4,[x22,poisson_Y]
10:
    bl distanceAuMur
    cmp x0,DISTANCE_MIN
    cset x24,le            // x24 = 1 ou 0
    bgt 90f
    //affregtit change 20
    ldr x15,[x22,poisson_X]  // recharge les positions car peuvent avoir changé
    ldr x16,[x22,poisson_Y]  // et routine distanceaumur utilise X10 à x16 
    //affregtit change1 11
    ldr d3,dfMultiVit
    sub x11,x15,x1
    cmp x0,x11
    bne 11f
    //affregtit changeXmini 0
    ldr d0,[x22,poisson_vitesseX]
    fadd d0,d0,d3
    str d0,[x22,poisson_vitesseX]
    b 20f
11:
    sub x11,x16,x2
    //affregtit change2 11
    //affregtit changeYmini 0
    //affregtit changeYmini 11
    cmp x0,x11
    bne 12f

    ldr d0,[x22,poisson_vitesseY]
    fadd d0,d0,d3
    str d0,[x22,poisson_vitesseY]
    b 20f
12:
    sub x11,x3,x15
    cmp x0,x11
    bne 13f
    ldr d0,[x22,poisson_vitesseX]
    fsub d0,d0,d3
    str d0,[x22,poisson_vitesseX]
    b 20f
13:
    sub x11,x4,x16
    cmp x0,x11
    bne 20f
    ldr d0,[x22,poisson_vitesseY]
    fsub d0,d0,d3
    str d0,[x22,poisson_vitesseY]

20:
    mov x0,x23
    bl normaliser
90:
    mov x0,x24
100:
    ldp x23,x24,[sp],16         // restaur des  2 registres
    ldp x22,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
dfMultiVit:           .double 0.3 
/******************************************************************/
/*     normalisation du vecteur vitesse                          */ 
/******************************************************************/
/* x0 contient la valeur de l'index de la table   */
normaliser:                        //INFO: normaliser
    stp x10,lr,[sp,-16]!        // save  registres
    ldr x10,qAdrtbPoisson
    mov x11,poisson_fin
    madd x12,x11,x0,x10        // premier poisson
    ldr d0,[x12,poisson_vitesseX]
    ldr d1,[x12,poisson_vitesseY]
    fmul d2,d0,d0
    fmul d3,d1,d1
    fadd d3,d3,d2
    fsqrt d2,d3
    fdiv d0,d0,d2
    str d0,[x12,poisson_vitesseX]
    fdiv d1,d1,d2
    str d1,[x12,poisson_vitesseY]
100:
    ldp x10,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     eviter les poissons proches                                */ 
/******************************************************************/
/* x0 contient la valeur de l'index de la table   */
eviterPoissons:                        //INFO: eviterPoissons
    stp x20,lr,[sp,-16]!        // save  registres
    stp x21,x22,[sp,-16]!        // save  registres
    stp x23,x24,[sp,-16]!        // save  registres
    mov x23,x0                  // poisson courant
    mov x24,0                   // poisson de départ
    cbnz x0,2f                  // si c'est le poisson courant
    mov x24,1                   //On prend le 1
2:
    mov x0,x23
    mov x1,x24
    bl calculerDistanceCarre
    mov x21,x0
    mov x22,0
3:
    cmp x22,x23                // c'est le poisson courant
    beq 4f
    mov x0,x23
    mov x1,x22
    bl calculerDistanceCarre
    cmp x0,x21
    bge 4f
    mov x24,x22       // nouveau poisson plus près
    mov x21,x0        // et nouvelle distance
4:
    add x22,x22,1
    cmp x22,NBPOISSONS
    blt 3b
    //affregtit evitement 20
    /* evitement */
    mov x0,0
    cmp x21,DISTANCE_MIN_CARRE
    bge 100f                  // pas à eviter
    // calcul racine carree
    mov x0,x21
    bl calRacineCarree
    cmp x0,-1
    beq 99f
    //affregtit evitement 0
    ldr x20,qAdrtbPoisson
    mov x11,poisson_fin
    madd x12,x11,x23,x20        // poisson courant
    madd x24,x11,x24,x20        // poisson le + proche
    //affregtit evitement1 20
    ldr x11,[x12,poisson_X]
    ldr x13,[x24,poisson_X]
    sub x13,x13,x11             // calcul distance X entre les 2 poissons
    sdiv x13,x13,x0             // Divisée par la distance entre les 2 
    asr x13,x13,2               // divisé par 4
    fmov d1,x13
    scvtf d1,d1                 // et conversion en float
    ldr d0,[x12,poisson_vitesseX]
    fsub d0,d0,d1               // puis enlevé de la vitesse X
    str d0,[x12,poisson_vitesseX]

    ldr x11,[x12,poisson_Y]
    ldr x14,[x24,poisson_Y]
    sub x14,x14,x11             // idem pour Y
    sdiv x14,x14,x0
    asr x14,x14,2
    fmov d1,x14
    scvtf d1,d1              // et conversion en float
    ldr d0,[x12,poisson_vitesseY]
    fsub d0,d0,d1
    str d0,[x12,poisson_vitesseY]
    //affregtit evitement2 20
    mov x0,x23
    bl normaliser
    mov x0,1                      // poisson à eviter
    b 100f
99:
    affichelib erreurracineCarree
    affregtit erreur 0
100:
    ldp x23,x24,[sp],16         // restaur des  2 registres
    ldp x21,x22,[sp],16         // restaur des  2 registres
    ldp x20,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     eviter les obstacles proches                                */ 
/******************************************************************/
/* x0 contient la valeur de l'index de la table   */
eviterObstacles:                        //INFO: eviterObstacles
    stp x20,lr,[sp,-16]!        // save  registres
    stp x21,x22,[sp,-16]!        // save  registres
    stp x23,x24,[sp,-16]!        // save  registres
    mov x20,x0                  // poisson courant
    ldr x1,qAdrqNbObstacles
    mov x0,0    // pas d'obstacles
    ldr x21,[x1]
    cbz x21,100f
    //mov x1,0
    //bl calculerDistanceCarreObstacle

    mov x22,9999
    mov x23,0
    mov x24,0
1:
    ldr x10,qAdrtbObstacle
    mov x11,obstacle_fin
    madd x12,x11,x23,x10
    ldr x10,[x12,obstacle_temps]
    cbz x10,2f
    mov x0,x20
    mov x1,x23
    bl calculerDistanceCarreObstacle
    cmp x0,x22
    bge 2f
    mov x24,x23      // obstacle plus proche
    mov x22,x0
2:
    add x23,x23,1
    cmp x23,x21      // nb objet total atteint ?
    blt 1b
    ldr x10,qAdrtbObstacle
    mov x11,obstacle_fin
    madd x12,x11,x24,x10
    ldr x13,[x12,obstacle_rayon]
    mul x14,x13,x13
    mov x0,0
    cmp x22,x14
    bge 100f
    //affregtit evtObstacle 20
    mov x0,x22
    bl calRacineCarree
    mov x15,x0
    ldr x13,[x12,obstacle_X]    // position X obstacle
    ldr x10,qAdrtbPoisson
    mov x11,obstacle_fin
    madd x16,x11,x20,x10
    ldr x10,[x16,poisson_X]
    sub x13,x13,x10
    sdiv x13,x13,x0
    asr x13,x13,1
    fmov d0,x13
    scvtf d0,d0
    ldr d1,[x16,poisson_vitesseX]
    fsub d1,d1,d0
    str d1,[x16,poisson_vitesseX]

    ldr x14,[x12,obstacle_Y]    // position Y obstacle
    ldr x10,[x16,poisson_Y]
    sub x14,x14,x10
    sdiv x14,x14,x0
    asr x14,x14,1
    fmov d0,x14
    scvtf d0,d0
    ldr d1,[x16,poisson_vitesseY]
    fsub d1,d1,d0
    str d1,[x16,poisson_vitesseY]
    mov x0,x20
    mov x0,1
100:
    ldp x23,x24,[sp],16         // restaur des  2 registres
    ldp x21,x22,[sp],16         // restaur des  2 registres
    ldp x20,lr,[sp],16          // restaur des  2 registres
    ret                         // retour adresse lr x30

/******************************************************************/
/*     direction moyenne pour regroupement                         */ 
/******************************************************************/
/* x0 contient la valeur de l'index de la table   */
calculerDirectionMoyenne:      //INFO: calculerDirectionMoyenne
    stp x20,lr,[sp,-16]!       // save  registres
    stp x21,x22,[sp,-16]!      // save  registres
    stp x23,x24,[sp,-16]!      // save  registres
    mov x23,x0
    ldr x20,qAdrtbPoisson
    mov x22,poisson_fin
    mov x21,0
    fmov d0,x21                // init vitesse X totale
    scvtf d0,d0                // conversion float
    fmov d1,x21                // init vitesse Y totale
    scvtf d1,d1
    mov x24,0                  // compteur de poissons pris en compte
1:
    mov x0,x23
    mov x1,x21
    bl dansAlignement
    cbz x0,2f
    //affregtit alignement 20
    madd x12,x22,x21,x20        // poisson courant
    ldr d2,[x12,poisson_vitesseX]
    fadd d0,d0,d2
    ldr d2,[x12,poisson_vitesseY]
    fadd d1,d1,d2
    add x24,x24,1
2:
    add x21,x21,1
    cmp x21,NBPOISSONS
    blt 1b
    //affregtit aligncpt 20
    cmp x24,0                   // compteur trouvé > 0 ?
    ble 100f

    madd x12,x22,x23,x20        // poisson début
    ldr d2,[x12,poisson_vitesseX]
    fmov d4,x24                 // compteur
    scvtf d4,d4                 // conversion float
    fdiv d5,d0,d4               // calcul vitesse moyenne X
    fadd d2,d2,d5               // addition à la vitesse X du poisson
    mov x6,2                    // diviseur
    fmov d6,x6
    scvtf d6,d6
    fdiv d2,d2,d6               // division par 2
    str d2,[x12,poisson_vitesseX] // et mise à jour
    ldr d2,[x12,poisson_vitesseY] // idem pour vitesse Y
    fdiv d5,d1,d4
    fadd d2,d2,d5
    fdiv d2,d2,d6
    str d2,[x12,poisson_vitesseY]
    mov x0,x23
    bl normaliser
100:
    ldp x23,x24,[sp],16         // restaur des  2 registres
    ldp x21,x22,[sp],16         // restaur des  2 registres
    ldp x20,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     un autre poisson est dans l'alignement                                          */ 
/******************************************************************/
/* x0 contient la valeur de l'index de la table   */
/* x1 contient l'index d'un autre poisson */
calculerDistanceCarre:                        //INFO: calculerDistanceCarre
    stp x10,lr,[sp,-16]!        // save  registres
    ldr x10,qAdrtbPoisson
    mov x11,poisson_fin
    madd x12,x11,x0,x10        // premier poisson
    ldr x13,[x12,poisson_X]
    ldr x14,[x12,poisson_Y]
    madd x12,x11,x1,x10       // deuxieme poisson
    ldr x15,[x12,poisson_X]
    ldr x16,[x12,poisson_Y]
    sub x15,x15,x13           // calcul ecart X
    mul x13,x15,x15           // au carré
    sub x15,x16,x14           // calcul écart Y
    mul x14,x15,x15           // au carré
    add x0,x13,x14            // retour distance au carre
    //affregtit distcarre 0
100:
    ldp x10,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     un autre poisson est dans l'alignement                                          */ 
/******************************************************************/
/* x0 contient la valeur de l'index de la table   */
/* x1 contient l'index d'un obstacle*/
calculerDistanceCarreObstacle:      //INFO: calculerDistanceCarreObstacle
    stp x10,lr,[sp,-16]!        // save  registres
    ldr x10,qAdrtbPoisson
    mov x11,poisson_fin
    madd x12,x11,x0,x10        // poisson
    ldr x13,[x12,poisson_X]
    ldr x14,[x12,poisson_Y]
    ldr x10,qAdrtbObstacle
    mov x11,obstacle_fin
    madd x12,x11,x1,x10       // obstacle
    ldr x15,[x12,obstacle_X]
    ldr x16,[x12,obstacle_Y]
    sub x15,x15,x13
    mul x13,x15,x15
    sub x15,x16,x14
    mul x14,x15,x15
    add x0,x13,x14         // distance au carre
    //affregtit distcarre 0
100:
    ldp x10,lr,[sp],16         // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     calcul cosinus   algorithme cordic                                          */ 
/******************************************************************/
/* d0 contient la valeur de l'angle en radians   */
/* d0 retourne le cosinus */
/* d1 le sinus */
/* ATTENTION : aucun registre d. n'est sauvegardé */
cordic:                        //INFO: cordic
    stp x9,lr,[sp,-16]!        // save  registres
    //affichelib cosinus
    ldr d1,dfPI2               // verification > 2PI
    fcmp d0,d1
    bgt 99f                    // erreur angle trop grand
    mov x9,0                   // calcul du quadrant
    ldr d1,dfPIDIV2
1:                             // boucle calcul quadrant
    fcmp  d0,d1
    blt 2f
    fsub d0,d0,d1              // moins pi/2
    add x9,x9,1
    b 1b                       // et boucle
2:
    fmov d9,d0                 // l'angle est dans la plage 0, PI/2
    ldr d6,dfValDep           // x valeur initiale
    mov x10,0                  // y
    fmov d2,x10               // transfert dans registre float
    scvtf d2,d2

    mov x10,0                  //indice calcul
    ldr x11,qAdrtbArcTanC      // table des valeurs initiale
3:                             // début de boucle
    fmov d8,1
    fcmp d9,0
    bge 4f
    fmov d8,-1                 // signe négatif
4:

    mov x1,1
    lsl x2,x1,x10             // calcul de 2 à la puissance indice
    fmov d4,x2                // d4 = d23
    scvtf d4,d4               // et conversion en float

    fdiv d5,d2,d4             // y / 2 puissance i
    fmul d5,d5,d8             // multiplié par le signe
    fsub d7,d6,d5            // x temporaire
    fdiv d5,d6,d4             // x / 2 puissance i
    fmul d5,d5,d8             // multiplié par le signe
    fadd d2,d2,d5             // y
    fmov d6,d7               // et temporaire dans x

    ldr d7,[x11,x10,lsl 3]    // valeur table pour l'indice
    fmul d7,d7,d8             // multiplié par le signe
    fsub d9,d9,d7             // nouvel angle
    add x10,x10,1
    cmp x10,14                 // maxi ?
    ble 3b                     // boucle

    fmov d0,d6                // retour cosinus
    fmov d1,d2                // retour sinus
    mov x0,0                  // calcul OK
    cmp x9,0                  // quadrant 0
    beq 100f
    cmp x9,1                  // quadrant 1
    bne 6f
    fmov d3,d0
    fmov d0,d1
    fmov d1,d3
    fneg d0,d0

    b 100f
6:
    cmp x9,2                  // quadrant 2
    bne 7f
    fneg d0,d0
    fneg d1,d1
    b 100f
7:                             // quadrant 3
    fmov d3,d0
    fmov d0,d1
    fmov d1,d3
    fneg d1,d1
    b 100f
99:
    ldr x0,qAdrszMessErrAngle
    bl affichageMess
    mov x0,-1
100:
    ldp x9,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
dfValDep:            .double .60725
qAdrtbArcTanC:       .quad tbArcTanC
qAdrszMessErrAngle:  .quad szMessErrAngle
dfPI2:               .double 6.28318           // pi * 2
dfPIDIV2:          .double 1.57079632679     // Pi / 2
/***************************************************/
/*   Calcul racine carre                          */
/***************************************************/
/* x0 contient le nombre                         */
/* x0 retourne la racine carrée   ou - 1               */
calRacineCarree:              // INFO: calRacineCarree
    stp x1,lr,[sp,-16]!       // save  registres
    stp x2,x3,[sp,-16]!       // save  registres
    stp x4,x5,[sp,-16]!       // save  registres
    cmp x0,0
    beq 100f                  // si zero fin
    bgt 1f
    mov x0,-1                 // si negatif retourne - 1
    b 100f
1:
    cmp x0,#4                 // si inférieur à 4 retourne 1
    bge 2f 
    mov x0,#1
    b 100f
2:                    // début calcul
    mov x3,64
    clz x2,x0         // nombre de zéros à gauche
    sub x2,x3,x2      // donc nombre de chiffres utiles à droite
    bic x2,x2,#1         // pour avoir un nombre pair de chiffres
    mov x3,#0b11      // masque pour extraitre 2 bits consécutif du registre origine
    lsl x3,x3,x2         // et placement sur les 2 premiers bits utiles
    mov x1,#0         // init résultat avec 0
    mov x4,#0         // raz zone reste
3:                    // boucle de calcul
    and x5,x0,x3      // extraction de 2 bits avec le masque
    lsr x6,x5,x2       // deplacement à droite 
    add x4,x4,x6      // addition avec le reste précedent 
    lsl x5,x1,1       // multiplication du résultat par 2 
    lsl x5,x5,#1      // deplacement d'un bit à gauche
    orr x5,x5,#1      // et on met 1 pour voir si le calcul est bon
    lsl x1,x1,#1      // on decale x1 à gauche
    mov x6,x4
    subs x4,x4,x5     // on l'enleve du reste
    csel x4,x6,x4,mi  // si negatif on remet x4 à l'état d'avant
    add x6,x1,1
    csel x1,x6,x1,pl  // et on met 1 au dernier bit de la racine si resultat positif  (sinon il reste à 0)
    subs x2,x2,#2     // passage aux 2 autre caractères à droite.
    bmi 4f            // c'est fini ?
    lsl x4,x4,#2      // non donc déplacement du reste de 2 caractères sur la gauche
    lsr x3,x3,#2      // et deplacement du masque de 2 caractères vers la droite
    b 3b              // et boucle
4:                    // fin du calcul
    mov x0,x1         // retour résultat

100:
    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/*********************************************************************/
/* constantes Générales              */
.include "../constantesARM64.inc"
/* affiche float */
/* d29 contient le float à afficher */
afficherFloat:                // INFO: afficherFloat
    stp x0,lr,[sp,-16]!       // save  registres
    stp x1,x2,[sp,-16]!       // save  registres
    stp x3,x4,[sp,-16]!       // save  registres
    stp x5,x6,[sp,-16]!       // save  registres
    stp x10,x12,[sp,-16]!       // save  registres
    stp d0,d1,[sp,-16]!       // save  registres
    stp d2,d3,[sp,-16]!       // save  registres
    stp d4,d5,[sp,-16]!       // save  registres
    affichelib floatreg29
    fmov d0,d29
    ldr x0,qAdrszAfficheVal1
    bl printf 
    ldp d4,d5,[sp],16          // restaur des  2 registres
    ldp d2,d3,[sp],16          // restaur des  2 registres
    ldp d0,d1,[sp],16          // restaur des  2 registres
    ldp x10,x12,[sp],16          // restaur des  2 registres
    ldp x5,x6,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/*  format affichage float */
qAdrszAfficheVal1:     .quad szAfficheVal1
szAfficheVal1:         .asciz "Valeur = %+09.15f\n"
