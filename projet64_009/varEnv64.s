/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* variables environnement  */
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessDebutPgm:      .asciz "Début du programme. \n"
szMessErreur:        .asciz "Erreur rencontrée.\n"
szMessFinOK:         .asciz "Fin normale du programme. \n"
sMessResult:         .ascii " "
sMessValeur:         .fill 11, 1, ' '            // taille => 11
szRetourligne:       .asciz  "\n"
szVarRech:           .asciz  "USER="
                     .equ LGVARRECH,  . - szVarRech  - 1 // car zero final
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4

sBuffer:    .skip 500 

/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global main                    // 'main' point d'entrée doit être  global 

main:                           // programme principal 
    mov fp,sp                   // recup adresse pile
    ldr x0,qAdrszMessDebutPgm   // x0 ← adresse message debut 
    bl affichageMess            // affichage message dans console 
    ldr x0,[fp]                 // nombre param
    ldr x1,[fp,8]               // param 1 = nom du programme
    ldr x2,[fp,16]              // adresse retour = 0
    ldr x3,[fp,24]              // adresse de la première variable envronnement
    ldr x4,[fp,32]              // adresse 2ieme 
    ldr x5,[fp,-8]              // contient l'adresse de retour de affichageMess précédent
    affregtit contenu_pile 0
    ldr x0,[fp,8]               // affiche le nom du programme
    bl affichageMess
    ldr x0,qAdrszRetourligne
    bl affichageMess
    mov x1,3
1:                              // boucle d'affichage des variables
    ldr x0,[fp,x1,lsl 3]
    cmp x0,0
    beq 2f
    bl affichageMess  
    ldr x0,qAdrszRetourligne
    bl affichageMess 
    add x1,x1,1
    b 1b
2:
    add x2,x1,1                 // autre chose ?
    ldr x3,[fp,x2,lsl 3]
    add x2,x2,1
    ldr x4,[fp,x2,lsl 3]
    add x2,x2,1
    ldr x5,[fp,x2,lsl 3]
    affregtit fin_variables 0
    ldr x4,=.text
    ldr x1,=.data
    ldr x2,=.bss
    ldr x3,=__bss_end__
    affregtit section  0
                                // recherche variable
    ldr x2,[fp]                 // nombre param
    add x2,x2,2
    ldr x1,qAdrszVarRech
    affregtit debut 0
3:
    ldr x0,[fp,x2,lsl 3]
    cbz x0,4f
    mov x4,x0
    bl searchSubString
    cmp x0,-1
    add x5,x2,1
    csel x2,x5,x2,eq
    //addeq x2,#1
    beq 3b
    affregtit rech 0
    add x0,x4,LGVARRECH
    bl affichageMess            // affichage message dans console 
    ldr x0,qAdrszRetourligne
    bl affichageMess 
    
4:
    ldr x0,qAdrszMessFinOK      // x0 ← adresse chaine 
    bl affichageMess            // affichage message dans console 
    mov x0,0                   // code retour OK 
    b 100f
99:                             // affichage erreur 
    ldr x1,qAdrszMessErreur     // x0 <- code erreur, x1 <- adresse chaine 
    bl   afficheErreur          // appel affichage message
    mov x0,1                   // code erreur 
    b 100f
100:                            // fin de programme standard  
    mov x8,EXIT               // appel fonction systeme pour terminer 
    svc 0 
/************************************/
qAdrszMessDebutPgm:     .quad szMessDebutPgm
qAdrszMessErreur:       .quad szMessErreur
qAdrszMessFinOK:        .quad szMessFinOK
qAdrZoneBlanc:          .quad qAdrZoneBlanc
qAdrszRetourligne:      .quad szRetourligne
qAdrszVarRech:          .quad szVarRech
/******************************************************************/
/*   search a substring in the string                            */ 
/******************************************************************/
/* x0 contains the address of the input string */
/* x1 contains the address of substring */
/* x0 returns index of substring in string or -1 if not found */
searchSubString:
    stp x1,lr,[sp,-16]!                  // save  registers
    mov x12,0                             // counter byte input string
    mov x13,0                             // counter byte string 
    mov x16,-1                            // index found
    ldrb w14,[x1,x13]
1:
    ldrb w15,[x0,x12]                       // load byte string 
    cbz x15,99f                           // zero final ?
    cmp x15,x14                             // compare character 
    beq 2f
    mov x16,-1                             // no equals - > raz index 
    mov x13,0                              // and raz counter byte
    add x12,x12,1                          // and increment counter byte
    b 1b                                  // and loop
2:                                        // characters equals
    cmp x16,-1                             // first characters equals ?
    csel x16,x12,x16,eq                      // yes -> index begin in x16
    add x13,x13,1                           // increment counter substring
    ldrb w14,[x1,x13]                       // and load next byte
    cbz x14,3f                             // zero final ?
    add x12,x12,1                           // else increment counter string
    b 1b                                  // and loop
3:
    mov x0,x16
    b 100f
99:
    mov x0,#-1                            // yes returns error
100:
    ldp x1,lr,[sp],16                     // restaur  2 registers
    ret                                   // return to address lr x30
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM64.inc"
