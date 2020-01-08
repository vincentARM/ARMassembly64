/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* routine de conversion d'une chaine en un nombre float  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"
.equ TAILLEBUFFER,   100
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
szMessErrComm:           .asciz "Ligne de commande incomplete : saisieFloat <nombre>\n"
szMessSaisie:            .asciz "Saississez un nombre (Par ex 4,5 ou 5.7) : "
.equ LGMESSSAISIE,       . - szMessSaisie
szMessErreurGen:         .asciz "Erreur rencontrée :\n"
szAfficheVal1:           .asciz "Valeur = %+09.15f\n"
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
sBuffer:             .skip TAILLEBUFFER
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                               // entry of program 
    mov fp,sp                       // save addresse pile dans frame
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    ldr x0,[fp]                     // nombre de paramètres ligne de commande
    cmp x0,#1                       // ok ?
    ble erreurCommande              // erreur

    add x0,fp,#16                   // adresse du 2ième paramètre
    ldr x0,[x0]
    bl convStrToFloat
    ldr x0,qAdrszAfficheVal1
    bl printf 
    /* saisie */
1:
    ldr x0,qAdrszMessSaisie
    mov x1,LGMESSSAISIE
    bl affichageMessSP
    mov x0,STDIN                   //console linux
    ldr x1,qAdrsBuffer             // adresse du buffer de lecture
    mov x2,TAILLEBUFFER            // taille buffer
    mov x8,READ                    // call system linux
    svc 0 
    cmp x0,#0                      // erreur ?
    blt 99f
    ldr x0,qAdrsBuffer             // adresse du buffer de lecture
    bl convStrToFloat
    ldr x0,qAdrszAfficheVal1
    bl printf 
    b 1b
    b 100f

erreurCommande:
    ldr x1,qAdrszMessErrComm
    bl   afficheErreur   
    mov x0,#1                     // code erreur
    b 100f
99:                               // erreur détectée
    ldr x1,qAdrszMessErreurGen
    bl   afficheErreur 

100:                              // fin standard du programme
    ldr x0,qAdrszMessFinPgm       // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                      // code retour
    mov x8,EXIT                   // system call "Exit"
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdrszMessErrComm:       .quad szMessErrComm
qAdrsBuffer:             .quad sBuffer
qAdrszAfficheVal1:       .quad szAfficheVal1
qAdrszMessSaisie:        .quad szMessSaisie
qAdrszMessErreurGen:     .quad szMessErreurGen
/******************************************************************/
/*     Conversion string en float                                 */ 
/******************************************************************/
/* x0 contient l'adresse de la chaine à convertir (terminée par 0 ou 0xA)    */
/* d0 retourne la valeur Float   */
convStrToFloat:
    stp fp,lr,[sp,-16]!       // save  registres
    stp x1,x2,[sp,-16]!       // save  registres
    stp x3,x4,[sp,-16]!       // save  registres
    stp d1,d2,[sp,-16]!       // save  float registres
    sub sp,sp,48              // zone temporaire de conversion
    mov fp,sp
    mov x2,0
    mov x3,0
    mov x1,-1                 // chercher la position de la virgule ou du point  
                              // recopier la chaine sans la virgule ou le point
1:
    ldrb w4,[x0,x2]           // charger un octet
    cmp w4,'.'
    beq 2f
    cmp w4,','
    beq 2f
    strb w4,[fp,x3]           // stocker le caractère dans la zone temporaire
    cbz w4,3f                 // fin de chaine ?
    cmp w4,0xA                // fin de chaine saisie ?
    beq 3f
    add x3,x3,1
    add x2,x2,1
    b 1b                      // sinon boucle
2:
    mov x1,x2                 // . ou , trouvés, position dans x1
    add x2,x2,1
    b 1b                      // et boucle 
3:
    mov x0,fp                 // convertir la chaine de la zone temporaire en decimal
    bl conversionAtoD
    fmov d0,x0                // puis le convertir en float
    scvtf d0,d0
    cmp x1,-1
    beq 100f                  // pas de , ou de . trouvé -> d0 contient un entier Float
    sub x1,x2,x1
    sub x1,x1,1
    cbz x1,100f               // devrait pas arriver !!
    mov x2,10
    mov x3,1
4:                            // boucle de calcul puissance de 10
    mul x3,x3,x2
    subs x1,x1,1
    bgt 4b                    // fin ?
    fmov d1,x3                // conversion puissance de 10 en float
    scvtf d1,d1
    fdiv d0,d0,d1             // effectuer la division
100:
    add sp,sp,48
    ldp d1,d2,[sp],16         // restaur des  2 registres
    ldp x3,x4,[sp],16         // restaur des  2 registres
    ldp x1,x2,[sp],16         // restaur des  2 registres
    ldp fp,lr,[sp],16         // restaur des  2 registres
    ret                       // retour adresse lr x30

