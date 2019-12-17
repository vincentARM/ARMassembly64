/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/* création fenetre X11 pour affichage image png  */
/* affichage image png à partir de zones mémoire */
/* allocation place sur le tas */

    /* attention x19  pointeur display */
    /* attention x20  pointeur ecran   */
    /* attention x21  référence fenêtre principale   */
    /* attention x22  pointeur vers la structure fenêtre principale */
    /* attention x23  pointeur vers le contexte graphique principal */

/*********************************************/
/*constantes                                 */
/********************************************/
// le ficher des constantes générales est en fin du programme
.equ LARGEUR,           600   // largeur de la fenêtre
.equ HAUTEUR,           400   // hauteur de la fenêtre
.equ LGBUFFER,          1000  // longueur du buffer 

.equ O_RDONLY,     0
.equ OPEN,         56
.equ CLOSE,        57

.equ AT_FDCWD,    -100

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

/* color type masks */
.equ PNG_COLOR_MASK_PALETTE,    1
.equ PNG_COLOR_MASK_COLOR,      2
.equ PNG_COLOR_MASK_ALPHA,      4
.equ PNG_COLOR_TYPE_GRAY,       0
.equ PNG_COLOR_TYPE_PALETTE,  (PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_PALETTE)
.equ PNG_COLOR_TYPE_RGB,        (PNG_COLOR_MASK_COLOR)
.equ PNG_COLOR_TYPE_RGB_ALPHA,  (PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_ALPHA)
.equ PNG_COLOR_TYPE_GRAY_ALPHA, (PNG_COLOR_MASK_ALPHA)

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/***********************************/
/* description des structures */
/***********************************/
.include "../defStruct64.inc"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szNomFenetre:            .asciz "Fenetre Raspberry"
szRetourligne:           .asciz  "\n"
szMessDebutPgm:          .asciz "Debut du programme. \n"
szMessFinPgm:            .asciz "Fin normale du programme. \n" 
szMessErrComm:           .asciz "Nom du fichier absent de la ligne de commande. \n"
szMessErreurGen:         .asciz "Erreur rencontrée. Arrêt programme.\n"
szMessErreur:            .asciz "Serveur X non trouvé.\n"
szMessErrfen:            .asciz "Création fenetre impossible.\n"
szMessErreurX11:         .asciz "Erreur fonction X11. \n"
szMessErrGc:             .asciz "Création contexte graphique impossible.\n"
szMessErrGcBT:           .asciz "Création contexte graphique Bouton impossible.\n"
szMessErrbt:             .asciz "Création bouton impossible.\n"
szMessErrGPolice:        .asciz "Chargement police impossible.\n"
szMessErrCImage:         .asciz "Erreur, création image X11.\n"
szTitreFenRed:           .asciz "Pi"   
szTitreFenRedS:          .asciz "PiS"  
szRouge:                 .asciz "red"
szBlack:                 .asciz "black"
szWhite:                 .asciz "white"
/* libellé special pour correction pb fermeture */
szLibDW:                 .asciz "WM_DELETE_WINDOW"

//szNomRepDepart:          .asciz "."

/* polices de caracteres */
szNomPolice:             .asciz  "-*-helvetica-bold-*-normal-*-14-*"
szNomPolice1:            .asciz  "-*-fixed-bold-*-normal-*-14-*"

szMessErreur1:           .asciz "Erreur ouverture fichier.\n"
szMessErreur2:           .asciz "Erreur lecture fichier.\n"
szMessErreurPNG:         .asciz "Image non PNG.\n"
.align 4
hauteur:                 .quad HAUTEUR
largeur:                 .quad LARGEUR


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
//stFenetreChge:         .skip XWCH_fin      // reservation place   XWindowChanges
//.align 4
stWmHints:             .skip  Hints_fin    // reservation place pour structure XWMHints 
.align 4
stAttrSize:            .skip XSize_fin     // reservation place structure XSizeHints
.align 4
stFichier:              .skip file_fin
.align 4
stIMGPNG:               .skip PNG_fin
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
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text           
.global main                            // 'main' point d'entrée doit être  global 

main:                                   // programme principal // fonction
    mov fp,sp                           // recup adresse pile  registre x29 fp
    ldr x0,qAdrszMessDebutPgm           // adresse message debut 
    bl affichageMess                    // affichage message dans console
    ldr x4,[fp]                         // nombre de paramètres ligne de commande
    cmp x4,#1                           // TODO voir avec 2 !!
    ble erreurCommande                  // erreur
    add x5,fp,#16                       // adresse du 2ième paramètre
    ldr x5,[x5]                         // recup adresse nom du fichier image
    ldr x0,qAdrqAdrFicName              // et stockage adresse dans zone mémoire
    str x5,[x0]

    /* chargement d'une image de type PNG */
    mov x0,x5                           // adresse nom du fichier 
    ldr x1,qAdrstFichier                // structure fichier
    bl lectfichierPNG                   // lecture fichier image
    cbz x0,erreurGénérale
    ldr x0,qAdrstFichier                // structure fichier
    bl chargePNGMem                     // conversion image PNG
    cbz x0,erreurGénérale

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
    /* création de l'image X11   */
    ldr x0,qAdrstIMGPNG                // pointeur structure image
    bl creationImageX11PNG
    cbz x0,erreurGénérale
    /* création fenetre avec dimension de l'image JPEG et affichage image */
    ldr x0,qAdrstFenetreSec1
    bl creationFenetreSec1
    cbz x0,erreurGénérale
    /* boucle des evenements */     
boucleevt:
    bl gestionEvenements
    cbz x0,boucleevt                       // si zero on boucle sinon on termine 
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
erreurCommande:
    ldr x1,qAdrszMessErrComm
    bl   afficheErreur   
    mov x0,#1                             // code erreur
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
qAdrszMessErrComm:      .quad szMessErrComm
qAdrptDisplay:          .quad ptDisplay
qAdrptEcran:            .quad ptEcran
qAdrstFenetrePrinc:     .quad stFenetrePrinc
qAdrstFenetreSec1:      .quad stFenetreSec1
qAdrstIMGPNG:        .quad stIMGPNG
qAdrqAdrFicName:        .quad qAdrFicName
qAdrstFichier:          .quad stFichier
qAdrszMessErreurGen:    .quad szMessErreurGen
/********************************************************************/
/*   Connexion serveur X et recupération informations du display  ***/
/********************************************************************/    
/* retourne dans x19 le pointeur vers le Display */
/* retourne dans x20 le pointeur vers l'écran  */
ConnexionServeur:                      // fonction
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
chargementPolices:                     // fonction
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
chargementCouleurs:                     // fonction
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
    ldr x2,qAdrszRouge
    ldr x3,qAdrExact
    ldr x4,qAdrClosest
    bl XAllocNamedColor
    cmp x0,#0
    beq 2f
    ldr x0,qAdrClosest
    ldr x0,[x0,#XColor_pixel]
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
creationFenetrePrincipale:                  // fonction
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
creationGC:                    // fonction
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
    ldr x2,[x20,#Screen_white_pixel]
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
/*   Creation d 'une fenêtre secondaire                         ***/
/********************************************************************/
/* x0 contient la structure de la fenêtre */
creationFenetreSec1:                     // fonction
    stp x25,lr,[sp,-16]!               // save  registres 
    str x24,[sp,-16]!                  // save  registres 
    mov x25,x0                         // save de la structure

    /* CREATION DE LA FENETRE */
    mov x0,x19                         // display
    mov x1,x21                        // identification fenêtre mère
    mov x2,#10                        // position X
    mov x3,#10                        // position Y 
    ldr x4,qAdrstIMGPNG
    ldr x4,[x4,#PNG_largeur]
    ldr x5,qAdrstIMGPNG
    ldr x5,[x5,#PNG_hauteur]
    mov x6,#1                          // bordure
    ldr x7,[x20,#Screen_white_pixel]   // couleur bordure
    ldr x8,[x20,#Screen_black_pixel]   // couleur du fond
    str x8,[sp,-16]!                   // passé par la pile
    bl XCreateSimpleWindow
    add sp,sp,16                       // alignement pile
    cmp x0,#0
    beq 98f
    mov x24,x0                         // stockage adresse fenetre dans le registre x9 pour usage ci dessous
    str x0,[x25,#Win_id]               // et dans la structure

    /* affichage de la fenetre */
    mov x0,x19                         // adresse du display
    mov x1,x24                         // adresse fenetre locale
    bl XMapWindow
    /* autorisation des saisies */
    mov x0,x19                         // adresse du display
    mov x1,x24                         // adresse de la fenetre
    ldr x2,qFenetreMaskS4              // masque pour autoriser saisies
    bl XSelectInput
    cmp x0,#0
    ble 99f
    /* chargement des donnees dans la structure */
    mov x0,x19                         // adresse du display
    mov x1,x24                         // adresse de la fenetre
    mov x2,x25
    bl XGetWindowAttributes
    cmp x0,#0
    ble 99f
1:                                    // pas d'erreur
    ldr x0,qAdrevtFenetreSec1
    str x0,[x25,#Win_procedure] 
    mov x0,x24                         // adresse de la fenetre
    ldr x1,qAdrstIMGPNG
    bl affichageImagePNG
    mov x0,x24                         // retourne l'identification de la fenetre
    b 100f
98:                                   // erreur fenetre 
    ldr x1,qAdrszMessErrfen   
    bl   afficheErreur  
    mov x0,#0                         // code erreur 
    b 100f
99:                                   // erreur X11
    ldr x1,qAdrszMessErreurX11  
    bl   afficheErreur  
    mov x0,#0                         // code erreur 
    b 100f
100:
    ldr x24,[sp],16                   // restaur registre
    ldp x25,lr,[sp],16                // restaur des  2 registres
    ret                               // retour adresse lr x30

qFenetreMaskS4:      .quad StructureNotifyMask|ExposureMask
qAdrevtFenetreSec1:  .quad evtFenetreSec1
/********************************************************************/
/*   Gestion des évenements                                       ***/
/********************************************************************/
gestionEvenements:                     // fonction
    stp x19,lr,[sp,-16]!         // save  registres 
    mov x0,x19                   // adresse du display
    ldr x1,qAdrevent             // adresse evenements
    bl XNextEvent
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
    add x2,x2,#1                   // non
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
evtFenetrePrincipale:           // fonction
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
    affregtit fermeture 0
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

    // il faut redessiner l'image png

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

    mov x0,#0
    b 100f

99:
    ldr x1,qAdrszMessErreurX11   // erreur X11
    bl   afficheErreur   
    mov x0,#0
100:
    ldp x19,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

/********************************************************************/
/*   Evenements de la fenêtre secondaire                          ***/
/********************************************************************/
// x0 doit contenir le pointeur sur l'evenement
// x1 doit contenir l'identification de la fenêtre
// sauvegarde des registres
evtFenetreSec1:                     // fonction
    stp x19,lr,[sp,-16]!            // save  registres 
    ldr x0,qAdrevent
    ldr w0,[x0,#XAny_type]
    cmp w0,#Expose                  // cas d'une modification de la fenetre ou son masquage
    bne 2f
    mov x0,x1
    ldr x1,qAdrstIMGPNG
    bl affichageImagePNG
2:
    mov x0,#0

100:
    ldp x19,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     lecture fichier image PNG                                       */ 
/******************************************************************/
/* x0 contient l'adresse du nom du fichier image   */
/* x1 contient la structure fichier */
/* x0 retourne l'adresse du buffer de lecture ou zéro si erreur */
lectfichierPNG:                     // fonction
    stp x26,lr,[sp,-16]!         // save  registres
    stp x27,x28,[sp,-16]!        // save  registres
    mov x28,0
    mov x26,x1                   // save structure
    /* recopie du nom du fichier dans la structure */
    mov x2,0                     // indice
1:
    ldrb w3,[x0,x2]             // charger un octet
    strb w3,[x26,x2]            // stocker un octet
    cbz w3,2f                   // si zero -> fin
    add x2,x2,1                 // sinon boucle
    b 1b
2:
    mov x1,x0                   // ouverture du fichier
    mov x0,AT_FDCWD             // valeur pour indiquer le répertoire courant
    mov x2,O_RDONLY             //  flags
    mov x3,0                    // mode
    mov x8,OPEN                 // appel fonction systeme pour ouvrir
    svc 0                       //
    cmp x0,0                    // si erreur
    ble erreur1Fic
    mov x27,x0                  // File Descriptor
    /* lecture taille pour l'allocation du buffer */
                                // x0 contient le FD du fichier 
    ldr x1,qAdrsBuffer          //  adresse du buffer de reception
    mov x8,80                   // appel fonction systeme pour FSTAT
    svc 0 
    cmp x0,#0
    blt erreur2Fic
    ldr x0,qAdrsBuffer
    ldr x0,[x0,48]        // voir description de la structure stats
    str x0,[x26,file_size]
    mov x3,x0
    /* allouer l'espace sur le tas */
    bl allocPlace          //allouer la place sur le tas suivant taille
    cbz x0,100f
    mov x28,x0             // adresse debut tas
    str x28,[x26,file_datas]
    /* lecture fichier image dans buffer tas */
    mov x0,x27               // FD fichier
    mov x1,x28               // adresse du buffer de reception
    mov x2,x3                // nb de caracteres
    mov x8,READ              // appel fonction systeme pour lire
    svc 0 
    cmp x0,#0
    blt erreur2Fic
    mov x0,x28
    //affmemtit buffer x0 4
    ldrh w1,[x0,18]              // largeur image
    rev w1,w1
    lsr w1,w1,16                 // hauteur image
    ldrh w2,[x0,22]
    rev w2,w2
    lsr w2,w2,16
    mul x0,x1,x2
    lsl x0,x0,2
    bl allocPlace                //allouer la place sur le tas suivant taille
    cbz x0,100f
    mov x23,x0                  // save adresse tas dans x23
    affregtit finlect 0
fermetureFic:
    mov x0,x27                  // Fd  fichier
    mov x8, #CLOSE              // appel fonction systeme pour fermer
    svc 0 
    mov x0,x28                 // retourne l'adresse du tas  
    b 100f
erreur1Fic:    
    ldr x1,qAdrszMessErreur1   // x0 <- adresse chaine 
    bl   afficheErreur     
    mov x0,0                   // erreur
    b 100f
erreur2Fic:    
    ldr x1,qAdrszMessErreur2     // x0 <- adresse chaine 
    bl   afficheErreur 
    mov x0,0                    // code retour erreur
    b 100f    
100:
    ldp x27,x28,[sp],16          // restaur des  2 registres
    ldp x26,lr,[sp],16           // restaur des  2 registres
    ret                          // retour adresse lr x30
qAdrszMessErreur1:         .quad szMessErreur1
qAdrszMessErreur2:         .quad szMessErreur2
qAdrsBuffer:               .quad sBuffer

/******************************************************************/
/*     copie des donnees pour lecture                                       */ 
/******************************************************************/
/* x0 contient le pointeur sur la structure de lecture png    */
/* x1 contient l'adresse des donnees    */
/* x2  le nombre de caractères à copier */
png_read_from_memPNG:                     // fonction
    stp x20,lr,[sp,-16]!          // save  registres
    stp x21,x22,[sp,-16]!         // save  registres
    mov x20,x0
    mov x21,x1
    mov x22,x2
    bl png_get_io_ptr              // récupération du pointeur
                                   // faut recuperer data et offset à partir de ce pointeur
    ldr x1,[x0,file_datas]         // init datas
    ldr x3,[x0,file_offset]        // init compteur
    mov x2,0
1:                                 // boucle de copie 
    ldrb w4,[x1,x3]
    strb w4,[x21,x2]
    add x3,x3,1
    add x2,x2,1
    cmp x2,x22
    blt 1b
    str x3,[x0,file_offset]       // maj offset
    mov x0,0
100:
    ldp x21,x22,[sp],16           // restaur des  2 registres
    ldp x20,lr,[sp],16            // restaur des  2 registres
    ret                           // retour adresse lr x30
/******************************************************************/
/*     chargement image PNG                                       */ 
/******************************************************************/
/* x0 contient l'adresse de la structure file    */
chargePNGMem:   // fonction
    stp x20,lr,[sp,-16]!         // save  registres
    stp x21,x22,[sp,-16]!        // save  registres
    stp x23,x24,[sp,-16]!        // save  registres
    stp x25,x26,[sp,-16]!        // save  registres
    stp x27,x28,[sp,-16]!        // save  registres
    mov x27,x0                   // save structure file
    ldr x0,[x27,file_datas]
    /*  vérifier la signature du fichier */
    mov x1,0
    mov x2,8                   // nombre de caractères lus
    bl png_sig_cmp             // verification signature fichier
    cbnz x0,nonPng             // ce n'est pas une image png
    /* création des structures suivant la version de la librairie */
    adr x0,szVERSION           // N° de version PNG
    mov x1,0
    mov x2,0
    mov x3,0
    bl png_create_read_struct   // création structure de lecture
    cbz x0,erreurSTR
    mov x26,x0                  // save pointeur structure 
    bl png_create_info_struct   // création structure information
    cbz x0,erreurSTR1
    /* préparation des lectures */
    mov x25,x0                  // save pointeur ptr_info
    mov x0,x26                  // pointeur structure lecture
    mov x1,x27                  // structure fichier
    adr x2,png_read_from_memPNG // adresse de la fonction de copie
    bl png_set_read_fn
    mov x0,x26                  // pointeur structure lecture
    mov x1,x25                  // pointeur structure info
    mov x2,0
    bl png_read_info            // lecture des infos
    mov x0,x26                  // pointeur structure lecture
    mov x1,x25                  // pointeur structure info
    bl png_get_bit_depth
    mov x24,x0                  // récup nombre bits par pixel
    //affregtit depth 0
    mov x0,x26
    mov x1,x25
    bl png_get_color_type
    mov x28,x0                 // récup type couleur
    //affregtit colortype 0
    /* modifications en fonction des informations précédentes */
    /* convert index color images to RGB images */
    cmp x28,PNG_COLOR_TYPE_PALETTE
    bne 1f
    mov x0,x26                  // pointeur structure lecture
    bl png_set_palette_to_rgb
1:
    /* autres vérification à voir */
    /* puis elles sont vérifiées avec l'appel ci dessous */
    mov x0,x26                  // pointeur structure lecture
    mov x1,x25                  // pointeur structure info
    ldr x20,qAdrstIMGPNG        // adresse structure image png
    add x2,x20,PNG_largeur      // adresse reception largeur
    add x3,x20,PNG_hauteur      // adresse reception hauteur
    ldr x4,qAdrqBit_depth       // Adresse reception nombre de bits
    ldr x5,qAdrqColorType       // adresse reception type couleurs
    mov x6,0
    mov x7,0
    mov x8,0
    str x8,[sp,-16]!            // dernier paramètre stocké sur la pile
    bl png_get_IHDR             // lecture des informations
    add sp,sp,16                // alignement pile

    /* allocation table pointeurs */
    ldr x0,[x20,PNG_hauteur]  // hauteur image
    lsl x0,x0,3               // * 8 octets
    bl allocPlace
    cbz x0,100f
    mov x22,x0                // adresse zone pointeurs
    /* initialisation de la table des pointeurs */
    mov x0,x22
    mov x1,x23                // recup addresse zone pixel
    str x1,[x20,PNG_debut_pixel]
    mov x2,0                  // indice table pointeurs
    ldr x3,[x20,PNG_largeur]  // largeur image
    ldr x4,[x20,PNG_hauteur]  // hauteur image
    mov x5,4                  //taille d'un pixel en octets
                              // attention à modifier suivant le type
3:
    add x6,x2,1               // indice + 1
    mov x6,x2
    //sub x6,x4,x6              // taille - indice car image inversée
    mul x6,x6,x5              // * par taille pixel
    mul x6,x6,x3              // * par largeur
    add x6,x6,x1              // ajout à l'adresse du début de table
    str x6,[x0,x2,lsl 3]      // et stockage dans la table des pointeurs
    add x2,x2,1               // ligne suivante
    cmp x2,x4                 // nombre de lignes atteint ?
    blt 3b                    // non -> boucle
    /* lecture des pixels de l'image */
    /* Attention il est indiqué que l'image est inversée */
    /* mais l'affichage de l'image par X11 ne le montre pas */
    mov x0,x26                // pointeur structure lecture
    mov x1,x22
    bl png_read_image         // lecture des pixels
    ldr x0,[x20,PNG_debut_pixel] // table des pixels
    ldr x1,[x20,PNG_largeur]  // largeur image
    ldr x2,[x20,PNG_hauteur]  // hauteur image
    bl inversionPixel         // inversion des couleurs pour affichage correct

    mov x0,x26
    mov x1,0
    bl png_read_end          // lecture fin fichier
    mov x0,x26
    mov x1,x25
    mov x2,0
    bl png_destroy_read_struct // destruction des structures
    mov x0,1                   // Pas d'erreur
    b 100f
erreurSTR:
    affregtit erreurSTR 0
    mov x0,0
    b 100f
erreurSTR1:
    mov x0,x26
    bl png_destroy_read_struct
    affregtit erreurSTR1 0
    mov x0,0
    b 100f
nonPng:
    ldr x1,qAdrszMessErreurPNG   // x0 <- adresse chaine 
    bl   afficheErreur     
    mov x0,0                     // erreur
100:
    ldp x27,x28,[sp],16          // restaur des  2 registres
    ldp x25,x26,[sp],16          // restaur des  2 registres
    ldp x23,x24,[sp],16          // restaur des  2 registres
    ldp x21,x22,[sp],16          // restaur des  2 registres
    ldp x20,lr,[sp],16           // restaur des  2 registres
    ret                          // retour adresse lr x30

qAdrszMessErreurPNG:       .quad szMessErreurPNG
qAdrqColorType:            .quad qColorType
qAdrqBit_depth:            .quad qBit_depth
szVERSION:                 .asciz "1.6.36"
.align 4                      //obligatoire pour réalignement instructions

/********************************************************/
/*   inversion des couleurs sur chaque pixel de 4 octets */
/********************************************************/
/* x0 pointeur vers buffer pixels */
/* x1 largeur image en pixel      */
/* x2 hauteur image en pixel      */
/* remarque : doit être adapté pour des pixels de longueur <> 4 octets */
/* attention aucune sauvegarde des registres */
inversionPixel:                     // fonction
    mul x3,x1,x2
    mov x4,#0
1:
    ldr w5,[x0,x4,lsl 2]
    and w6,w5,0xFF
    lsl x7,x4, 2
    add x7,x7,2
    strb w6,[x0,x7]
    and w6,w5,0xFF0000
    lsr w6,w6,16
    lsl x7,x4, 2
    add x7,x7,0
    strb w6,[x0,x7]

    add x4,x4,1
    cmp x4,x3
    ble 1b
100:
    ret

/***************************************************/
/*   Création de de XImage à partir buffer image PNG  */
/***************************************************/
/* x0 pointeur vers structure image */
/* x0 retourne le pointeur vers l'image crée */ 
creationImageX11PNG:                     // fonction
    stp x24,lr,[sp,-16]!               // save  registres 
    mov x24,x0                         // save structure
    mov x0,x19                         // display
    ldr x1,[x20,#Screen_root_visual]   // visual defaut
    ldr x2,[x20,#Screen_root_depth]    // Nombre de bits par pixel
    mov x3,#ZPixmap
    mov x4,#0                          // offset debut image
    ldr x5,[x24,#PNG_debut_pixel]      // adresse image PNG
    ldr x6,[x24,#PNG_largeur]
    ldr x7,[x24,#PNG_hauteur]
    mov x8,8                           // nombre de bit de décalage !!!!!!!! à revoir
    mov x9,0                           //
    stp x8,x9,[sp,-16]!   
    bl XCreateImage
    add sp,sp,#16                      // remise à  niveau pile 
    cbz x0,99f                         // erreur création image

    str x0,[x24,#PNG_imageX11]         // maj adresse image X11 dans structure
    b 100f
99:
    ldr x1,qAdrszMessErrCImage         // x0 <- adresse chaine 
    bl   afficheErreur 
    mov x0,0                           // code retour erreur
    b 100f    
100:
    ldp x24,lr,[sp],16                 // restaur des  2 registres
    ret                                // retour adresse lr x30
qAdrszMessErrCImage:              .quad szMessErrCImage
/***************************************************/
/*   Affichage de XImage dans fenetre        */
/***************************************************/
/* x0 pointeur fenêtre  */
/* x1 pointeur vers structure image */
affichageImagePNG:                     // fonction
    stp x24,lr,[sp,-16]!         // save  registres 
    mov x24,x1                   // save structure
    mov x1,x0                    // pointeur fenêtre
    mov x0,x19                   // display
    ldr x2,qAdrptGC              // contexte graphique 
    ldr x2,[x2]
    ldr x3,[x24,#PNG_imageX11]   // adresse de l'image
    mov x4,0                     // position X de l'image dans la source
    mov x5,0                     // position Y de l'image dans la source
    mov x6,0                     // position X de l'image dans la destination
    mov x7,0                     // position Y de l'image dans la destination
    ldr x9,[x24,#PNG_largeur]
    ldr x10,[x24,#PNG_hauteur]
    stp x9,x10,[sp,-16]!
    bl XPutImage
    add sp,sp,#16                // alignement pile
100:
    ldp x24,lr,[sp],16           // restaur des  2 registres
    ret                          // retour adresse lr x30

/*********************************************************************/
/* constantes Générales              */
.include "../constantesARM64.inc"

