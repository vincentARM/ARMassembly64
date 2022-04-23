/* programm draw lines on the framebuffer raspberry pi 3 */

/*********************************************/
/*    Constantes                            */
/********************************************/
.equ STDIN,    0      // Linux input console
.equ STDOUT,   1      // Linux output console

.equ CHARPOS,     '@'

.equ IOCTL,        29
.equ OPEN,         56
.equ CLOSE,        57
.equ READ,         63 
.equ WRITE,        64 
.equ EXIT,         93 
.equ MMAP,         222
.equ MSYNC,        227

.equ O_RDWR,   0x0002          // read and write

.equ  PROT_READ,    0x1       /* Page can be read.  */
.equ PROT_WRITE,    0x2       /* Page can be written.  */
.equ PROT_EXEC,    0x4        /* Page can be executed.  */
.equ PROT_NONE,    0x0        /* Page can not be accessed.  */

.equ MAP_SHARED,    0x01      /* Share changes.  */
.equ MAP_PRIVATE,   0x02      /* Changes are private.  */

.equ MAP_FIXED,    0x10       /* Interpret addr exactly.  */
.equ MAP_FILE,     0
.equ MAP_ANONYMOUS,    0x20    /* Don't use a file.  */
.equ MAP_ANON,    MAP_ANONYMOUS

.equ MS_ASYNC,        1        /* sync memory asynchronously */
.equ MS_SYNC,         2        /* synchronous memory sync */
.equ MS_INVALIDATE,   4        /* invalidate the caches */

/* for structure description see at end of this program */

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne:   .asciz  "\n"
szParamNom:      .asciz "/dev/fb0"
szMessErrFix:    .asciz "Impossible lire info fix framebuffer  \n"
szMessErrVar:    .asciz "Impossible lire info var framebuffer  \n"
szMessErreur:    .asciz "Erreur ouverture fichier.\n"
szMessErreur1:   .asciz "Erreur fermeture fichier.\n"
szMessErreur2:   .asciz "Erreur mapping fichier.\n"
szMessFinOK:     .asciz "Fin normale du programme. \n"


/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
sZoneConv:        .skip 24
taille:           .skip 8
fbfd:             .skip 8                     // file descriptor framebuffer
Fix_info:         .skip FBFIXSCinfo_fin       // memory reserve for structure FSCREENINFO
.align 4
Var_info:         .skip FBVARSCinfo_fin       // memory reserve for structure VSCREENINFO
    
sBuffer:             .skip 500 
sBuffer1:            .skip 500 
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main

main:                     // programm entry
    mov x0,#0
    ldr x1,qAdrszParamNom
    mov x2,#O_RDWR
    mov x3,#0
    mov x8, #OPEN         // file framebuffer open
    svc 0 
    cmp x0,#0
    ble erreur
    mov x19,x0            // save du FD
    ldr x1,qAdrFbfd
    str x0,[x1]
                          // read fix datas
    ldr x1,FBIOGET_FSCREENINFO
    ldr x2,qAdrFix_info
    mov x8,#IOCTL         // read framebuffer fix datas
    svc 0 
    cmp x0,#0
    bge 1f
    ldr x0,qAdrszMessErrFix         // error display
    bl afficherMessage
    b 100f
1:    
    ldr x0,qAdrFix_info
    ldr x20,[x0,#FBFIXSCinfo_smem_len]  // load framebuffer memory size

    ldr x0,qAdrFbfd
    ldr x0,[x0]
    ldr x1,FBIOGET_VSCREENINFO
    ldr x2,qAdrVar_info
    mov x8, #IOCTL                      // read variable datas
    svc 0 
    cmp x0,#0
    bge 5f
    ldr x0,qAdrszMessErrVar            // error display
    bl afficherMessage 
    b 100f
5:
                              // mapping screen data in memory
    mov x0,#0
    mov x1,x20                // size
    ldr x2,iFlagsMmap
    mov x3,#MAP_SHARED
    mov x4,x19               // FD 
    mov x5,#0
    mov x8,#MMAP             // mapping
    svc #0 
    cmp x0,#0                // error ?
    beq erreur2
    mov x21,x0               // save address return by mmap

    mov x0,#255                       // red
    mov x1,#255                       // green
    mov x2,#255                       // blue    3 bytes 255 = white
    bl codeRGB                        // code color RGB  32 bits
    mov x2,x0                         // background color
    mov x0,x21                        // map address
    mov x1,x20                        // size
    bl coloriageFond                  // 

    mov x0,#255                       // red
    mov x1,#0                         // green
    mov x2,#0                         // blue    fist byte 255 = red
    bl codeRGB                        // code color RGB  32 bits
    mov x4,x0
    
    mov x0,x21                        // map address
    mov x1,100                        // x start
    mov x2,200                        // x end
    ldr x3,qAdrVar_info
    ldr w3,[x3,FBVARSCinfo_xres]     // screen line  4 bytes
    mov x5,100                       // position y
    bl traceDroiteH
    
    mov x0,x21                        // map address
    mov x1,100
    mov x2,300
    ldr x3,qAdrVar_info
    ldr w3,[x3,FBVARSCinfo_xres]     // screen line  4 bytes
    mov x5,200                       // line length
    bl traceDroiteH2
    
    mov x0,x21                        // map address
    mov x1,100                        // start position x
    mov x2,200                        // start position y
    ldr x3,qAdrVar_info
    ldr w3,[x3,FBVARSCinfo_xres]     // screen line  4 bytes
    mov x5,200                       // end position y
    bl traceDroiteV

    mov x0,x21                        // map address
    mov x1,100                        // start position x
    mov x2,200                        // start position y
    ldr x3,qAdrVar_info
    ldr w3,[x3,FBVARSCinfo_xres]      // screen line  4 bytes
    mov x5,200                        // end position x
    mov x6,400                        // end position y
    bl traceLigne
    
    mov x0,x21                        // map address
    mov x1,400                        // center position x
    mov x2,200                        // center position y
    ldr x3,qAdrVar_info
    ldr w3,[x3,FBVARSCinfo_xres]      // screen line  4 bytes
    mov x5,40                         //  Ray
    mov x6,1                          // 0 = empty 1 = full
    bl traceCercle
                                     // close device
    ldr x0,qAdrFbfd
    ldr x0,[x0]
    mov x8,CLOSE 
    svc 0 
    ldr x0,qAdrszMessFinOK            // end program message
    bl afficherMessage
    b 100f
    
erreur:
    ldr x0,qAdrszMessErreur
    bl  afficherMessage
    mov x0,#1                        // error
    b 100f
erreur1:
    ldr x0,qAdrszMessErreur1
    bl  afficherMessage 
    mov x0,#1                       // error
    b 100f
erreur2:
    ldr x0,qAdrszMessErreur2
    bl  afficherMessage
    mov x0,#1                       // error
    b 100f            
100:                      // end program
    mov x0,#0
    mov x8,EXIT 
    svc 0 
/************************************/
qAdrszParamNom:      .quad szParamNom
qAdrFbfd:            .quad fbfd
qAdrFix_info:        .quad Fix_info
qAdrVar_info:        .quad Var_info
qAdrszMessErrFix:    .quad szMessErrFix
qAdrszMessErrVar:    .quad szMessErrVar
qAdrszRetourligne:   .quad szRetourligne
qAdrsZoneConv:       .quad sZoneConv
qAdrszMessFinOK:     .quad szMessFinOK
FBIOGET_FSCREENINFO: .quad 0x4602
FBIOGET_VSCREENINFO: .quad 0x4600
iFlagsMmap:          .quad PROT_READ|PROT_WRITE
qAdrszMessErreur:    .quad szMessErreur
qAdrszMessErreur1:   .quad szMessErreur1
qAdrszMessErreur2:   .quad szMessErreur2
/********************************************************/
/*   Code color RGB                                     */
/********************************************************/
/* x0 red x1 green  x2 blue */
/* x0 returns RGB code      */
codeRGB:
    lsl x0,x0,#16          // shift red color 16 bits
    lsl x1,x1,#8           // shift green color 8 bits
    eor x0,x0,x1           // or two colors
    eor x0,x0,x2           // or 3 colors in x0
    ret
/********************************************************/
/*   set background color                               */
/********************************************************/
/* x0 contains screen memory address */
/* x1 contains size screen memory  */
/* x2 contains rgb code color      */
coloriageFond:
    stp x3,lr,[sp,-16]!        // save  registres
    mov x3,#0                  // counter 
1:                             // begin loop
    str w2,[x0,x3]
    add x3,x3,#4
    cmp x3,x1
    blt 1b
    
    ldp x3,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
    
/********************************************************/
/*   Traçage droite horizontale                         */
/*   Horizontal line tracing                            */
/********************************************************/
/* x0 addresse mémoire mapping */
/* x1 position x  */
/* x2 position x fin  */
/* x3 lenght screen line */
/* x4 color RGB 32 bits */
/* x5 position y */
traceDroiteH:
    stp x1,lr,[sp,-16]!     // save  registres
    stp x2,x6,[sp,-16]!     // save  registres
    cmp x1,x2               // control start x  < end x
    bge 100f
    mov x6,x2               // start indice
    mov x2,x5               // position y
1:
    bl aff_pixel_codeRGB32
    add x1,x1,#1
    cmp x1,x6
    ble 1b
 
100:
    ldp x2,x6,[sp],16        // restaur des  2 registres
    ldp x1,lr,[sp],16        // restaur des  2 registres
    ret                      // retour adresse lr x30
/********************************************************/
/*   Tracage droite horizontale                         */
/*    avec indication de la longeur                     */
/* Horizontal line tracing with length                   */
/********************************************************/
/* x0 address memory mapping */
/* x1 position x  */
/* x2 position y  */
/* x3 lenght screen line */
/* x4 couleur RGB 32 bits */
/* x5 line length */
traceDroiteH2:
    stp x1,lr,[sp,-16]!      // save  registres
    stp x5,x6,[sp,-16]!      // save  registres
    cmp x5,#0                // verif si longueur <> zero 
    beq 100f
    mov x6,x1                // position start
1:
    add x1,x6,x5             // add length
    bl  aff_pixel_codeRGB32
    subs x5,x5,#1            // decrement length
    bge 1b                   // and loop if > 0
 
100:                         // fin standard de la fonction
    ldp x5,x6,[sp],16        // restaur des  2 registres
    ldp x1,lr,[sp],16        // restaur des  2 registres
    ret                      // retour adresse lr x30
/********************************************************/
/*   Tracage droite verticale                         */
/*   vertical line tracing                             */
/********************************************************/
/* x0 address mapping */
/* x1 position y  */
/* x2 end position y  */
/* x3 lenght screen line */
/* x4 color RGB 32 bits */
/* x5 position x */
traceDroiteV:
    stp x1,lr,[sp,-16]!      // save  registres
    stp x2,x6,[sp,-16]!      // save  registres
    cmp x2,x1                // control y end > y start
    ble 100f
    mov x6,x2
    mov x2,x1
    mov x1,x5                // position x
1:
    bl  aff_pixel_codeRGB32
    add x2,x2,#1
    cmp x2,x6
    ble 1b
 
100:                         // fin standard de la fonction
    ldp x2,x6,[sp],16        // restaur des  2 registres
    ldp x1,lr,[sp],16        // restaur des  2 registres
    ret                      // retour adresse lr x30
/********************************************************/
/*   line tracing                                       */
/*   Merci au site http://betteros.org pour cet algoritme */
/********************************************************/
/* x0 addresse mémoire mapping */
/* x1 position x depart */
/* x2 position y  depart */
/* x3 longueur ligne */
/* x4 couleur RGB 32 bits */
/* x5 position x arrivée */
/* x6 position y arrivée */
traceLigne:
    stp x1,lr,[sp,-16]!  // save  registres
    stp x5,x6,[sp,-16]!  // save  registres
    cmp x5,x1            // end x > start x 
    blt 1f
    sub x7,x5,x1         // yes compute gap
    mov x10,#1           // and indice = 1
    b 2f
1:
    sub x7,x1,x5         // else compute  gap dxabs 
    mov x10,#-1          //  and indice = -1 sdx
2:
    cmp x6,x2            // compute gap for y
    blt 3f
    sub x8,x6,x2
    mov x11,#1
    b 4f
3:
    sub x8,x2,x6         // dyabs
    mov x11,#-1          // sdy
4:
    lsr x5,x8,#1         // x  Ok is dyabs !!
    lsr x6,x7,#1         // y 
    cmp x7,x8            // variations compare
    blt 6f               // cas 2  variation de x < variation de y
    mov x9,#0            // cas 1 variation x > variation y  init loop indice
 5:                      // loop begin     
    add x6,x6,x8         // y + dyabs
    cmp x6,x7
    blt 51f
    sub x6,x6,x7         // y - dxabs
    add x2,x2,x11
51:
    add  x1,x1,x10       // add or substract 1  to x
    
    bl  aff_pixel_codeRGB32  // pixel display
    add x9,x9,#1
    cmp x9,x7            // maxi pixels number axe x  ?
    blt 5b               // no -> loop
    b 100f
 6:  
    mov x9,#0            // cas 2  init loop indice
 7:
    add x5,x5,x7         // x + dxabs
    cmp x5,x8
    blt 8f
    sub x5,x5,x8         // y - dyabs
    add x1,x1,x10
8:
    add  x2,x2,x11       // add or substract 1 to y
    
    bl  aff_pixel_codeRGB32   // display pixel
    add x9,x9,#1
    cmp x9,x8             // maxi pixels number axe y  ?
    blt 7b                // no ->  loop
 
100: 
    ldp x5,x6,[sp],16        // restaur des  2 registres
    ldp x1,lr,[sp],16        // restaur des  2 registres
    ret                      // retour adresse lr x30
/********************************************************/
/*                 drawing a circle                     */
/********************************************************/
/* x0 addresse mémoire mapping */
/* x1 position x  */
/* x2 position y  */
/* x3 longueur ligne */
/* x4 couleur RGB 32 bits */
/* x5 rayon (anc r3)     */
/* x6 0 = vide  1 = plein  */
traceCercle:
    stp x1,lr,[sp,-16]!  // save  registres
    stp x5,x6,[sp,-16]!  // save  registres
    cmp x5,#0            // verif rayon différent de zero
    beq 100f
    mov x10,x5           // save du rayon
    mov x7,#0    
    sub x5,x7,x10       // x5 <-   -rayon
    mov x8,x1           // position x
    mov x9,x2           // position y
 1:                     // début de boucle
    add x1,x8,x10       // ajout du rayon à la position x de départ
    add x2,x9,x7   
    bl  aff_pixel_codeRGB32
   sub x1,x8,x10
   add x2,x9,x7
   bl  aff_pixel_codeRGB32
   add x1,x8,x10
   sub x2,x9,x7
   bl  aff_pixel_codeRGB32
   sub x1,x8,x10
   sub x2,x9,x7
   bl  aff_pixel_codeRGB32 
   // 2ième
   add x1,x8,x7
   add x2,x9,x10
   bl  aff_pixel_codeRGB32
   sub x1,x8,x7
   add x2,x9,x10
   bl  aff_pixel_codeRGB32
   add x1,x8,x7
   sub x2,x9,x10
   bl  aff_pixel_codeRGB32
   sub x1,x8,x7
   sub x2,x9,x10
   bl  aff_pixel_codeRGB32
   cmp x6,#0          //  cercle vide ou plein ?
   beq 2f
   mov x11,x5         // on le remplit en tracant des droites horizontales  
   add x2,x8,x7
   sub x1,x8,x7
   add x5,x9,x10
   bl traceDroiteH
   //b 2f
   add x2,x8,x7
   sub x1,x8,x7
   sub x5,x9,x10
   bl traceDroiteH
   add x2,x8,x10
   sub x1,x8,x10
   add x5,x9,x7
   bl traceDroiteH
   add x2,x8,x10
   sub x1,x8,x10
   sub x5,x9,x7
   bl traceDroiteH
   mov x5,x11
   
2:                  // suite des calculs pour les boucles  
   add x5,x5,x7
   add x7,x7,#1    // Y + 1
   add x5,x5,x7
   cmp x5,#0
   blt 3f
   sub x5,x5,x10
   sub x10,x10,#1  // x - 1
   sub x5,x5,x10
3:
   cmp x10,x7
   bge 1b
                   // c'est fini   
100:   
    ldp x5,x6,[sp],16        // restaur des  2 registres
    ldp x1,lr,[sp],16        // restaur des  2 registres
    ret                      // retour adresse lr x30
/***************************************************/
/*   display pixels  32 bits                       */
/***************************************************/
/* x0 framebuffer memory address */
/* x1 = x */
/* x2 = y */
/* x3 screen width in pixels */
/* x4 code color RGB 32 bits  */
aff_pixel_codeRGB32:
    stp x1,x5,[sp,-16]!   // save  registres
                          // compute location pixel
    mul x5,x2,x3          // compute y * screen width          
    add x1,x1,x5          // + x
    lsl x1,x1,#2          // * 4 octets
    str w4,[x0,x1]        // store rgb code in mmap memory
    ldp x1,x5,[sp],16     // restaur des  2 registres
    ret                   // retour adresse lr x30
/******************************************************************/
/*     Affichage d une chaine avec calcul de sa longueur          */ 
/******************************************************************/
/* x0 contient l'adresse du texte (chaine terminée par zero) */
affichageMess:                 // fonction
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!          // save  registres
    mov x2,#0                  // compteur taille
1:                             // boucle calcul longueur chaine
    ldrb w1,[x0,x2]            // lecture un octet
    cbz w1,2f                  // fin de chaine si zéro
    add x2,x2,#1
    b 1b
2:                             // ici x2 contient la longueue de la chaine
    mov x1,x0                  // adresse du texte
    mov x0,#STDOUT             // sortie Linux standard
    mov x8, #WRITE             // code call system "write" */
    svc #0                     // call systeme Linux
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     conversion décimale non signée                             */ 
/******************************************************************/
/* x0 contient la valeur à convertir  */
/* x1 contient la zone receptrice  longueur >= 21 */
/* la zone receptrice contiendra la chaine ascii cadrée à gauche */
/* et avec un zero final */
/* x0 retourne la longueur de la chaine sans le zero */
.equ LGZONECONV,   20
conversion10:
    stp x5,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    mov x4,#LGZONECONV        // position dernier chiffre
    mov x5,#10                // conversion decimale
1:                            // debut de boucle de conversion
    mov x2,x0                 // copie nombre départ ou quotients successifs
    udiv x0,x2,x5             // division par le facteur de conversion
    msub x3,x0,x5,x2           //calcul reste
    add x3,x3,#48              // car c'est un chiffre
    sub x4,x4,#1              // position précedente
    strb w3,[x1,x4]           // stockage du chiffre
    cbnz x0,1b                 // arret si quotient est égale à zero
    mov x2,LGZONECONV          // calcul longueur de la chaine (20 - dernière position)
    sub x0,x2,x4               // car pas d'instruction rsb en 64 bits
                               // mais il faut déplacer la zone au début
    cbz x4,3f                  // si pas complète
    mov x2,0                   // position début  
2:    
    ldrb w3,[x1,x4]            // chargement d'un chiffre
    strb w3,[x1,x2]            // et stockage au debut
    add x4,x4,#1               // position suivante
    add x2,x2,#1               // et postion suivante début
    cmp x4,LGZONECONV - 1      // fin ?
    ble 2b                     // sinon boucle
3: 
    mov w3,0
    strb w3,[x1,x2]             // zero final
    mov x0,x2                  // retour longueur
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x5,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*   insertion string in other string  */ 
/******************************************************************/
/* x0 contains the address of string 1 */
/* x1 contains the address of insertion string   */
/* x2 contains the address of result string */
/* x0 return address of result              */
strInsertAtChar:
    stp x1,lr,[sp,-16]!                      // save  registers
    stp x2,x3,[sp,-16]!                      // save  registers
    stp x4,x5,[sp,-16]!                      // save  registers
    stp x6,x8,[sp,-16]!                      // save  registers
    mov x3,#0                                // length counter 
1:                                           // compute length of string 1
    ldrb w4,[x0,x3]
    cmp w4,#0
    cinc  x3,x3,ne                           // increment to one if not equal
    bne 1b                                   // loop if not equal
    mov x5,#0                                // length counter insertion string
2:                                           // compute length to insertion string
    ldrb w4,[x1,x5]
    cmp x4,#0
    cinc  x5,x5,ne                           // increment to one if not equal
    bne 2b                                   // and loop
    cmp x5,#0
    beq 99f                                  // string empty -> error
    add x3,x3,x5                             // add 2 length
    add x3,x3,#1                             // +1 for final zero
    mov x6,x0                                // save address string 1
    mov x5,x2
    mov x2,0
    mov x4,0               
3:                                           // loop copy string begin 
    ldrb w3,[x6,x2]
    cmp w3,0
    beq 99f
    cmp w3,CHARPOS                           // insertion character ?
    beq 5f                                   // yes
    strb w3,[x5,x4]                          // no store character in output string
    add x2,x2,1
    add x4,x4,1
    b 3b                                     // and loop
5:                                           // x4 contains position insertion
    add x8,x4,1                              // init index character output string
                                             // at position insertion + one
    mov x3,#0                                // index load characters insertion string
6:
    ldrb w0,[x1,x3]                          // load characters insertion string
    cmp w0,#0                                // end string ?
    beq 7f                                   // yes 
    strb w0,[x5,x4]                          // store in output string
    add x3,x3,#1                             // increment index
    add x4,x4,#1                             // increment output index
    b 6b                                     // and loop
7:                                           // loop copy end string 
    ldrb w0,[x6,x8]                          // load other character string 1
    strb w0,[x5,x4]                          // store in output string
    cmp x0,#0                                // end string 1 ?
    beq 8f                                   // yes -> end
    add x4,x4,#1                             // increment output index
    add x8,x8,#1                             // increment index
    b 7b                                     // and loop
8:
    mov x0,x5                                // return output string address 
    b 100f
99:                                          // error
    mov x0,#-1
100:
    ldp x6,x8,[sp],16                        // restaur  2 registers
    ldp x4,x5,[sp],16                        // restaur  2 registers
    ldp x2,x3,[sp],16                        // restaur  2 registers
    ldp x1,lr,[sp],16                        // restaur  2 registers
    ret
/***************************************************/
/*      DEFINITION DES STRUCTURES                 */
/***************************************************/
/* structure FSCREENINFO */    
/* voir explication détaillée : https://www.kernel.org/doc/Documentation/fb/api.txt */
    .struct  0
FBFIXSCinfo_id:          /* identification string eg "TT Builtin" */
    .struct FBFIXSCinfo_id + 16  
FBFIXSCinfo_smem_start:    /* Start of frame buffer mem */
    .struct FBFIXSCinfo_smem_start + 8   
FBFIXSCinfo_smem_len:       /* Length of frame buffer mem */
    .struct FBFIXSCinfo_smem_len + 4   
FBFIXSCinfo_type:    /* see FB_TYPE_*        */
    .struct FBFIXSCinfo_type + 4  
FBFIXSCinfo_type_aux:      /* Interleave for interleaved Planes */
    .struct FBFIXSCinfo_type_aux + 4  
FBFIXSCinfo_visual:    /* see FB_VISUAL_*        */
    .struct FBFIXSCinfo_visual + 4  
FBFIXSCinfo_xpanstep:    /* zero if no hardware panning  */
    .struct FBFIXSCinfo_xpanstep + 2      
FBFIXSCinfo_ypanstep:    /* zero if no hardware panning  */
    .struct FBFIXSCinfo_ypanstep + 2 
FBFIXSCinfo_ywrapstep:      /* zero if no hardware ywrap    */
    .struct FBFIXSCinfo_ywrapstep + 4 
FBFIXSCinfo_line_length:    /* length of a line in bytes    */
    .struct FBFIXSCinfo_line_length + 4 
FBFIXSCinfo_mmio_start:     /* Start of Memory Mapped I/O   */
    .struct FBFIXSCinfo_mmio_start + 4     
FBFIXSCinfo_mmio_len:        /* Length of Memory Mapped I/O  */
    .struct FBFIXSCinfo_mmio_len + 4 
FBFIXSCinfo_accel:     /* Indicate to driver which    specific chip/card we have    */
    .struct FBFIXSCinfo_accel + 4 
FBFIXSCinfo_capabilities:     /* see FB_CAP_*            */
    .struct FBFIXSCinfo_capabilities + 4 
FBFIXSCinfo_reserved:     /* Reserved for future compatibility */
    .struct FBFIXSCinfo_reserved + 8    
FBFIXSCinfo_fin:

/* structure VSCREENINFO */    
    .struct  0
FBVARSCinfo_xres:           /* visible resolution        */ 
    .struct FBVARSCinfo_xres + 4  
FBVARSCinfo_yres:          
    .struct FBVARSCinfo_yres + 4 
FBVARSCinfo_xres_virtual:          /* virtual resolution        */
    .struct FBVARSCinfo_xres_virtual + 4 
FBVARSCinfo_yres_virtual:          
    .struct FBVARSCinfo_yres_virtual + 4 
FBVARSCinfo_xoffset:          /* offset from virtual to visible resolution */
    .struct FBVARSCinfo_xoffset + 4 
FBVARSCinfo_yoffset:          
    .struct FBVARSCinfo_yoffset + 4 
FBVARSCinfo_bits_per_pixel:          /* bits par pixel */
    .struct FBVARSCinfo_bits_per_pixel + 4     
FBVARSCinfo_grayscale:          /* 0 = color, 1 = grayscale,  >1 = FOURCC    */
    .struct FBVARSCinfo_grayscale + 4 
FBVARSCinfo_red:          /* bitfield in fb mem if true color, */
    .struct FBVARSCinfo_red + 4 
FBVARSCinfo_green:          /* else only length is significant */
    .struct FBVARSCinfo_green + 4 
FBVARSCinfo_blue:          
    .struct FBVARSCinfo_blue + 4 
FBVARSCinfo_transp:          /* transparency            */
    .struct FBVARSCinfo_transp + 4     
FBVARSCinfo_nonstd:          /* != 0 Non standard pixel format */
    .struct FBVARSCinfo_nonstd + 4 
FBVARSCinfo_activate:          /* see FB_ACTIVATE_*        */
    .struct FBVARSCinfo_activate + 4     
FBVARSCinfo_height:              /* height of picture in mm    */
    .struct FBVARSCinfo_height + 4 
FBVARSCinfo_width:           /* width of picture in mm     */
    .struct FBVARSCinfo_width + 4 
FBVARSCinfo_accel_flags:          /* (OBSOLETE) see fb_info.flags */
    .struct FBVARSCinfo_accel_flags + 4 
/* Timing: All values in pixclocks, except pixclock (of course) */    
FBVARSCinfo_pixclock:          /* pixel clock in ps (pico seconds) */
    .struct FBVARSCinfo_pixclock + 4     
FBVARSCinfo_left_margin:          
    .struct FBVARSCinfo_left_margin + 4 
FBVARSCinfo_right_margin:          
    .struct FBVARSCinfo_right_margin + 4 
FBVARSCinfo_upper_margin:          
    .struct FBVARSCinfo_upper_margin + 4 
FBVARSCinfo_lower_margin:          
    .struct FBVARSCinfo_lower_margin + 4 
FBVARSCinfo_hsync_len:          /* length of horizontal sync    */
    .struct FBVARSCinfo_hsync_len + 4     
FBVARSCinfo_vsync_len:          /* length of vertical sync    */
    .struct FBVARSCinfo_vsync_len + 4 
FBVARSCinfo_sync:          /* see FB_SYNC_*        */
    .struct FBVARSCinfo_sync + 4 
FBVARSCinfo_vmode:          /* see FB_VMODE_*        */
    .struct FBVARSCinfo_vmode + 4 
FBVARSCinfo_rotate:          /* angle we rotate counter clockwise */
    .struct FBVARSCinfo_rotate + 4     
FBVARSCinfo_colorspace:          /* colorspace for FOURCC-based modes */
    .struct FBVARSCinfo_colorspace + 4     
FBVARSCinfo_reserved:          /* Reserved for future compatibility */
    .struct FBVARSCinfo_reserved + 16        
FBVARSCinfo_fin:
