/* programme analyse données du framebuffer  */

/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM64.inc"

.equ CHARPOS,     '@'

.equ IOCTL,        29
.equ OPEN,         56
.equ CLOSE,        57


.equ O_RDWR,   0x0002          // read and write

.equ  PROT_READ,    0x1     /* Page can be read.  */
.equ PROT_WRITE,    0x2     /* Page can be written.  */
.equ PROT_EXEC,    0x4     /* Page can be executed.  */
.equ PROT_NONE,    0x0     /* Page can not be accessed.  */

.equ MAP_SHARED,    0x01    /* Share changes.  */
.equ MAP_PRIVATE,   0x02    /* Changes are private.  */

.equ MAP_FIXED,    0x10    /* Interpret addr exactly.  */
.equ MAP_FILE,     0
.equ MAP_ANONYMOUS,    0x20    /* Don't use a file.  */
.equ MAP_ANON,    MAP_ANONYMOUS

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
szLigneVar:      .asciz "Variables info : @ * @  Bits par pixel : @ \n"
szId:            .asciz "id : @  size : @ \n"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
sZoneConv:        .skip 24
taille:           .skip 8
fbfd:             .skip 8             /* file descriptor du framebuffer */

Fix_info:
    id:           .skip 16     /* ident sur 16c */
    smem_start:   .skip 8       /*  debut zone buffer */
    Mem_len:      .skip 8       /*  taille */
                  .skip 100    /* a revoir plus tard */

Var_info:    
    Xres:           .skip 4
    Yres:           .skip 4
    xres_virtual:   .skip 4    /* virtual resolution        */
    yres_virtual:   .skip 4
    xoffset:        .skip 4    /* offset from virtual to visible */
    yoffset:        .skip 4    /* resolution            */
    bits_per_pixel: .skip 4
                    .skip 50
    
sBuffer:             .skip 500 
sBuffer1:            .skip 500 
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main

main:                     // programme principal
    mov x0,#0
    ldr x1,qAdrszParamNom
    mov x2,#O_RDWR
    mov x3,#0
    mov x8, #OPEN        // file open
    svc 0 
    cmp x0,#0
    ble erreur
    mov x8,x0            // save du FD
    ldr x1,qAdrFbfd
    str x0,[x1]
                         /* lecture donnees */
    ldr x1,FBIOGET_FSCREENINFO
    ldr x2,qAdrFix_info
    mov x8,#IOCTL       // lecture données du fichier
    svc 0 
    cmp x0,#0
    bge 1f
    ldr x0,qAdrszMessErrFix         // error display
    bl afficherMessage
    b 100f
1:    
                               // display fic info
    ldr x1,qAdrFix_info
    ldr x0,qAdrszId
    ldr x2,qAdrsBuffer
    bl strInsertAtChar
   
    ldr x0,qAdrMem_len          // load size
    ldr x0,[x0] 
    ldr x1,qAdrsZoneConv        // decimal conversion
    bl conversion10
    ldr x0,qAdrsBuffer
    ldr x1,qAdrsZoneConv
    ldr x2,qAdrsBuffer1
    bl strInsertAtChar
    ldr x0,qAdrsBuffer1         // name and size display
    bl afficherMessage

    ldr x0,qAdrFbfd
    ldr x0,[x0]
    ldr x1,FBIOGET_VSCREENINFO
    ldr x2,qAdrVar_info
    mov x8, #IOCTL              // read variable datas
    svc 0 
    cmp x0,#0
    bge 5f
    ldr x0,qAdrszMessErrVar     // error display
    bl afficherMessage 
    b 100f
5:
                               // display variable infos
    ldr x0,qAdrszLigneVar
    ldr x0,qAdrXres
    ldr w0,[x0]
    ldr x1,qAdrsZoneConv
    bl conversion10
    ldr x0,qAdrszLigneVar
    ldr x1,qAdrsZoneConv
    ldr x2,qAdrsBuffer
    bl strInsertAtChar
    ldr x0,qAdrYres
    ldr w0,[x0]
    ldr x1,qAdrsZoneConv
    bl conversion10
    ldr x0,qAdrsBuffer
    ldr x1,qAdrsZoneConv
    ldr x2,qAdrsBuffer1
    bl strInsertAtChar
    
    ldr x0,qAdrbits_per_pixel
    ldr w0,[x0]
    ldr x1,qAdrsZoneConv
    bl conversion10
    ldr x0,qAdrsBuffer1
    ldr x1,qAdrsZoneConv
    ldr x2,qAdrsBuffer
    bl strInsertAtChar
                          /*  affichage ligne */
    ldr x0,qAdrsBuffer
    bl afficherMessage  


                          /* fermeture device */
    ldr x0,qAdrFbfd
    ldr x0,[x0]
    mov x8,CLOSE 
    svc 0 
    ldr x0,qAdrszMessFinOK
    bl afficherMessage
    b 100f
    
erreur:
    ldr x0,qAdrszMessErreur
    bl  afficherMessage
    mov x0,#1             /* erreur */
    b 100f
erreur1:
    ldr x0,qAdrszMessErreur1
    bl  afficherMessage 
    mov x0,#1             /* erreur */
    b 100f
erreur2:
    ldr x0,qAdrszMessErreur2
    bl  afficherMessage
    mov x0,#1             /* erreur */
    b 100f            
100:                      // fin de programme standard
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
qAdrszId:            .quad szId
qAdrMem_len:         .quad Mem_len
qAdrszRetourligne:   .quad szRetourligne
qAdrsZoneConv:       .quad sZoneConv
qAdrsBuffer:         .quad sBuffer
qAdrsBuffer1:         .quad sBuffer1
qAdrszLigneVar:       .quad szLigneVar
qAdrbits_per_pixel:   .quad bits_per_pixel
qAdrXres:             .quad Xres
qAdrYres:             .quad Yres
qAdrszMessFinOK:     .quad szMessFinOK
FBIOGET_FSCREENINFO: .quad 0x4602
FBIOGET_VSCREENINFO: .quad 0x4600
iFlagsMmap:    .quad PROT_READ|PROT_WRITE
qAdrszMessErreur:   .quad szMessErreur
qAdrszMessErreur1:   .quad szMessErreur1
qAdrszMessErreur2:   .quad szMessErreur2
/******************************************************************/
/*     Affichage d une chaine avec calcul de sa longueur          */ 
/******************************************************************/
/* x0 contient l'adresse du texte (chaine terminée par zero) */
affichageMess:                 // fonction
    stp x0,lr,[sp,-32]!        // save  registres
    stp x1,x2,[sp,16]          // save  registres
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
    ldp x1,x2,[sp,16]          // restaur des  2 registres
    ldp x0,lr,[sp],32          // restaur des  2 registres
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
