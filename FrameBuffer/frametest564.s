/* programm load bmp image on the framebuffer raspberry pi 3 */

/*********************************************/
/*    Constantes                            */
/********************************************/
.equ STDIN,    0      // Linux input console
.equ STDOUT,   1      // Linux output console

.equ CHARPOS,     '@'
.equ BUFFERSIZE,  500000

.equ IOCTL,        29
.equ OPEN,         56
.equ CLOSE,        57
.equ READ,         63 
.equ WRITE,        64 
.equ FSTAT,        80
.equ EXIT,         93 
.equ MMAP,         222
.equ MSYNC,        227

.equ O_RDWR,   0x0002          // read and write
.equ AT_FDCWD,    -100         // code current directory 

.equ  PROT_READ,    0x1        // Page can be read.
.equ PROT_WRITE,    0x2        // Page can be written.
.equ PROT_EXEC,    0x4         // Page can be executed.
.equ PROT_NONE,    0x0         // Page can not be accessed.

.equ MAP_SHARED,    0x01       // Share changes.
.equ MAP_PRIVATE,   0x02       // Changes are private.

.equ MAP_FIXED,    0x10        // Interpret addr exactly.
.equ MAP_FILE,     0
.equ MAP_ANONYMOUS,    0x20    // Don't use a file.
.equ MAP_ANON,    MAP_ANONYMOUS

.equ MS_ASYNC,        1        // sync memory asynchronously
.equ MS_SYNC,         2        // synchronous memory sync
.equ MS_INVALIDATE,   4        // invalidate the caches

/* for structure description see at end of this program */

//.include "../ficmacros64.s"

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne:    .asciz  "\n"
szParamNom:       .asciz "/dev/fb0"
szNomImage:       .asciz "dessinCercles1.bmp"
szMessErrFix:     .asciz "Impossible lire info fix framebuffer  \n"
szMessErrVar:     .asciz "Impossible lire info var framebuffer  \n"
szMessErreur:     .asciz "Erreur ouverture fichier.\n"
szMessErreur1:    .asciz "Erreur fermeture fichier.\n"
szMessErreur2:    .asciz "Erreur mapping fichier.\n"
szMessOuvImg:     .asciz "Erreur ouverture fichier image.\n"
szMessLectImg:    .asciz "Erreur lecture fichier image.\n"
szMessErrImg:     .asciz "Erreur ce fichier image n'a pas le format bmp.\n"
szMesslecTaiImg:  .asciz "Erreur de lecture de la taille du fichier.\n"
szMessErrNbBits:  .asciz "Taille pixel incompatible avec ce programme (24 bits).\n"
szMessErrLargImg: .asciz "Largeur image plus grande que largeur ecran.\n"
szMessErrBuffer:  .asciz "Buffer de lecture de l'image trop petit.\n"
szMessFinOK:      .asciz "Fin normale du programme. \n"


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
    
sBuffer:             .skip BUFFERSIZE
sBuffer1:            .skip BUFFERSIZE
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main

main:                               // programm entry
    mov x0,#0
    ldr x1,qAdrszParamNom
    mov x2,#O_RDWR
    mov x3,#0
    mov x8, #OPEN                   // file framebuffer open
    svc 0 
    cmp x0,#0
    ble erreur
    mov x19,x0                      // save du FD
    ldr x1,qAdrFbfd
    str x0,[x1]
                                    // read fix datas
    ldr x1,FBIOGET_FSCREENINFO
    ldr x2,qAdrFix_info
    mov x8,#IOCTL                   // read framebuffer fix datas
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
    mov x1,x20                         // size
    ldr x2,iFlagsMmap
    mov x3,#MAP_SHARED
    mov x4,x19                         // FD 
    mov x5,#0
    mov x8,#MMAP                      // mapping
    svc #0 
    cmp x0,#0                         // error ?
    beq erreur2
    mov x21,x0                        // save address return by mmap

    mov x0,#255                       // red
    mov x1,#255                       // green
    mov x2,#255                       // blue    3 bytes 255 = white
    bl codeRGB                        // code color RGB  32 bits
    mov x2,x0                         // background color
    mov x0,x21                        // map address
    mov x1,x20                        // size
    bl coloriageFond                  // 
    
    mov x0,x21                        // map address
    ldr x1,qAdrszNomImage             // address file image name
    ldr x2,qAdrVar_info
    bl chargeImage                    // load bmp image
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
qAdrszNomImage:      .quad szNomImage
/********************************************************/
/*   Code color RGB                                     */
/********************************************************/
/* x0 red x1 green  x2 blue */
/* x0 returns RGB code      */
codeRGB:                   // INFO: codeRGB
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
coloriageFond:                 // INFO: coloriageFond
    stp x3,lr,[sp,-16]!        // save  registres
    mov x3,#0                  // counter 
1:                             // begin loop
    str w2,[x0,x3]
    add x3,x3,#4
    cmp x3,x1
    blt 1b
    
    ldp x3,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
    

    
/***************************************************/
/*   load image  BMP                               */
/***************************************************/
/* x0 address memory mapping  */
/* x1 address image file name */
/* x2 address variable datas framebuffer */
chargeImage:                      // INFO: chargeImage
    stp x1,lr,[sp,-16]!           // save  registres
    stp x20,x21,[sp,-16]!         // save  registres
    mov x20,x0
    mov x21,x2
                                  // open image file
    mov x0,AT_FDCWD               // current directory
    mov x2,#O_RDWR                // flags
    mov x3,#0                     // mode
    mov x8, #OPEN
    svc 0 
    cmp x0,#0                     // error ?
    ble erreurCI
    mov x11,x0                    // save Fd
                                  // search size image file 
    ldr x1,qAdrsBuffer            // address buffer
    mov x8,FSTAT                  // file statistic system call
    svc 0 
    cmp x0,#0                     // error ?
    blt erreurCI4
    mov x0,x11                    // Fd
    ldr x1,qAdrsBuffer            // address read buffer
    ldr x2,[x1,#Stat_size_t]      // file size : caution size is lost after the read
    ldr x3,qSizeBuffer            // buffer size 
    cmp x2,x3                     // size file image > size buffer ?
    bgt erreurCI7
    mov x8, #READ                 // no -> read image file
    svc 0 
    cmp x0,#0                     // error ?
    ble erreurCI2
                                  // control file type
    ldr x0,qAdrsBuffer
    ldrh w1,[x0]
    mov w2,0x4D42                 // type bmp 
    cmp w1,w2                     // code file type  = BMP ?
    bne erreurCI3
                                  // control bits by pixel
    add x0,x0,#BMFH_fin
    ldr x1,[x0,#BMIH_biBitCount]  // bits by pixel
    cmp x1,#24                    // = 24 (3 octets) ?
    bne erreurCI5
                                  // control size line screen
    ldr w6,[x0,#BMIH_biWidth]     // size line BMP en pixel 
    ldr w7,[x21,#FBVARSCinfo_xres]// size screen line 
    cmp x6,x7                     // line BMP > screen line ?
    bgt erreurCI6
                                  // TODO : control the height !!!!
                                  // compute size line image file in byte 
    mov x13,x6,lsl #1             // multiply by 2 and add one 
    add x13,x13,x6                //  = 3 bytes by pixel
                                  // if line not multiple of 4, it needs to be completed
    mov x14,x13
    mov x4,#4
    ands x14,x14,#0b011           // control if sier end by 2 bits à 00
    beq 1f
    sub x14,x4,x14                // else compute complement to 4 
    add x13,x13,x14               // and add to size line (and to use later) 
1:
                                  // calculation of the complement in bytes that will have to be added to complete a line
                                  // 
    sub x7,x7,x6                  // line complement in pixel
    lsl x7,x7,#2                  // * 4 for byte
    ldr x0,qAdrsBuffer
    ldr w4,[x0,#BMFH_bfSize]      // total number of bytes of the image including headers
    ldr w2,[x0,#BMFH_bfOffBits]   // offset which indicates the beginning of the bits of the image
    sub x4,x4,x2                  // so we remove the offset to get the exact size
                                  // and you have to start from the end because the image in BMP is reversed !!!!!!
    ldr w2,[x0,#BMFH_bfSize]      // image size in byteo
    mov x5,#0                     // total counter of bytes written in the memory of the mapping
    mov x9,#0                     // counter of the number of pixels per line
    sub x2,x2,x13                 // we remove the number of bytes of the bmp line from the total 
1:                                // line copy loop
    ldrb w3,[x0,x2]               // read byte in buffer  pixel red
    strb w3,[x20,x5]              // write byte in memory mapping
    add x2,x2,#1                  // maj counters 
    add x5,x5,#1
    ldrb w3,[x0,x2]               // store du 2ième byte   blue
    strb w3,[x20,x5]
    add x2,x2,#1
    add x5,x5,#1
    ldrb w3,[x0,x2]               // store du 3ième byte  green
    strb w3,[x20,x5]
    add x2,x2,#1    
    add x5,x5,#1
    strb wzr,[x20,x5]             // and store 0 to complete the display in 32 bits
    add x5,x5,#1
    add x9,x9,#1
    cmp x9,x6                     // Number of pixels of an image line reached ?
    blt 1b                        // no -> loop
                                  // complement and end of line
    add x2,x2,x14                 // add complement to line BMP
    sub x2,x2,x13                 // we remove the number of bytes from the bmp line to return to the beginning
    sub x2,x2,x13                 //  and we still remove the number of bytes to go to the next one
    mov x9,#0                     // reset image pixel counter
    add x5,x5,x7                  // and you have to add to the screen counter the number of bytes to complete
    cmp x2,#0                     //  It's finish ?
    bgt 1b                        // no we loop to process another line

                                  // close image BMP file
    mov x0,x11                    // Fd  
    mov x8, #CLOSE
    svc 0 
    mov x0,#0                     // return ok
    b 100f
    
erreurCI:    
    ldr x0,qAdrszMessOuvImg
    bl   affichageMess     
    mov x0,#1       // error
    b 100f
erreurCI2:    
    ldr x0,qAdrszMessLectImg
    bl   affichageMess     
    mov x0,#1       // error
    b 100f    
erreurCI3:    
    ldr x0,qAdrszMessErrImg
    bl   affichageMess  
    mov x0,#1       // error
    b 100f        
erreurCI4:    
    ldr x0,qAdrszMesslecTaiImg
    bl   affichageMess    
    mov x0,#1       // error
    b 100f  
erreurCI5:    
    ldr x0,qAdrszMessErrNbBits
    bl   affichageMess   
    mov x0,#1       // error
    b 100f     
erreurCI6:    
    ldr x0,qAdrszMessErrLargImg
    bl   affichageMess     
    mov x0,#1       // error
    b 100f  
erreurCI7:    
    ldr x0,qAdrszMessErrBuffer
    bl   affichageMess   
    mov x0,#1       // error
    b 100f      
100:
    ldp x20,x21,[sp],16        // restaur des  2 registres
    ldp x1,lr,[sp],16        // restaur des  2 registres
    ret                      // retour adresse lr x30
qAdrsBuffer:          .quad sBuffer
qSizeBuffer:          .quad BUFFERSIZE
qAdrszMessOuvImg:     .quad szMessOuvImg
qAdrszMessLectImg:    .quad szMessLectImg
qAdrszMessErrImg:     .quad szMessErrImg
qAdrszMesslecTaiImg:  .quad szMesslecTaiImg
qAdrszMessErrNbBits:  .quad szMessErrNbBits
qAdrszMessErrLargImg: .quad szMessErrLargImg
qAdrszMessErrBuffer:  .quad szMessErrBuffer
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
/* Caution : These structures are of 32-bit origin. Not all variable sizes have been used
 and therefore are unverified */
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
/*********************************/
/* structures pour fichier BMP   */
/* description des entêtes       */
/* structure de type  BITMAPFILEHEADER */
    .struct  0
BMFH_bfType:              /* identification du type de fichier */
    .struct BMFH_bfType + 2
BMFH_bfSize:              /* taille de la structure */
    .struct BMFH_bfSize + 4
BMFH_bfReserved1:              /* reservée */
    .struct BMFH_bfReserved1 + 2    
BMFH_bfReserved2:              /* reservée */
    .struct BMFH_bfReserved2 + 2    
BMFH_bfOffBits:              /* Offset pour le début de l'image */
    .struct BMFH_bfOffBits + 4    
BMFH_fin:    
/***************************************/
/* structure de type  BITMAPINFOHEADER */
    .struct  0
BMIH_biSize:              /* taille */
    .struct BMIH_biSize + 4
BMIH_biWidth:              /* largeur image */
    .struct BMIH_biWidth + 4    
BMIH_biHeight:              /* hauteur image */
    .struct BMIH_biHeight + 4
BMIH_biPlanes:              /* nombre plan */
    .struct BMIH_biPlanes + 2
BMIH_biBitCount:              /* nombre bits par pixel */
    .struct BMIH_biBitCount + 2
BMIH_biCompression:              /* type de compression */
    .struct BMIH_biCompression + 4
BMIH_biSizeImage:              /* taille image */
    .struct BMIH_biSizeImage + 4
BMIH_biXPelsPerMeter:              /* pixel horizontal par metre */
    .struct BMIH_biXPelsPerMeter + 4
BMIH_biYPelsPerMeter:              /* pixel vertical par metre */
    .struct BMIH_biYPelsPerMeter + 4
BMIH_biClrUsed:              /*  */
    .struct BMIH_biClrUsed + 4
BMIH_biClrImportant:              /*  */
    .struct BMIH_biClrImportant + 4
/* A REVOIR car BITMAPINFO */        
BMIH_rgbBlue:              /* octet bleu */
    .struct BMIH_rgbBlue + 1
BMIH_rgbGreen:              /* octet vert */
    .struct BMIH_rgbGreen + 1
BMIH_rgbRed:              /* octet rouge */
    .struct BMIH_rgbRed + 1
BMIH_rgbReserved:              /* reserve */
    .struct BMIH_rgbReserved + 1    
BMIH_fin:    
/* */
/**********************************************/
/* structure de type   stat  : infos fichier  */
    .struct  0
Stat_dev_t:               /* ID of device containing file */
    .struct Stat_dev_t + 8
Stat_ino_t:              /* inode */
    .struct Stat_ino_t + 4
Stat_mode_t:              /* File type and mode */
    .struct Stat_mode_t + 4
Stat_nlink_t:               /* Number of hard links */
    .struct Stat_nlink_t + 4
Stat_uid_t:               /* User ID of owner */
    .struct Stat_uid_t + 8
Stat_gid_t:                 /* Group ID of owner */
    .struct Stat_gid_t + 8   
Stat_rdev_t:                /* Device ID (if special file) */
    .struct Stat_rdev_t + 8
Stat_size_deb:           /* la taille est sur 8 octets si gros fichiers */
     .struct Stat_size_deb + 4 
Stat_size_t:                /* Total size, in bytes */
    .struct Stat_size_t + 4     
Stat_blksize_t:                /* Block size for filesystem I/O */
    .struct Stat_blksize_t + 4     
Stat_blkcnt_t:               /* Number of 512B blocks allocated */
    .struct Stat_blkcnt_t + 4     
Stat_atime:               /*   date et heure fichier */
    .struct Stat_atime + 8     
Stat_mtime:               /*   date et heure modif fichier */
    .struct Stat_atime + 8 
Stat_ctime:               /*   date et heure creation fichier */
    .struct Stat_atime + 8     
Stat_Fin:
