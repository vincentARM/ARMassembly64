/* Routines pour assembleur arm 64 bits raspberry */
/*******************************************/
/* CONSTANTES                              */
/*******************************************/
.include "./src/constantesARM64.inc"
.equ LGZONEADR,   47
.equ NBCARLIBEL,  47
.equ CHARPOS,   '@'
/*********************************/
/* Initialized data              */
/*********************************/
.data
/* données pour affichage registre base 2 */
sMessAffBin:     .ascii "Affichage x0 base 2 : "
sLibBin:         .fill LGZONEADR, 1, ' '
                 .ascii "\n"
sZoneBin:        .space 76,' '
                 .asciz "\n"
.equ LGZONEAFFBIN,   . - sMessAffBin
szMess1:         .asciz "OK\n"

szVidregistreReg: .ascii "Vidage registres : "
adresseLib:       .fill LGZONEADR, 1, ' '
suiteReg:         .ascii "\nx0 : "
reg0:             .fill 17, 1, ' '
s1:               .ascii " x1 : "
reg1:             .fill 17, 1, ' '
s2:               .ascii " x2 : "
reg2:             .fill 17, 1, ' '
s3:               .ascii "\nx3 : "
reg3:             .fill 17, 1, ' '
s4:               .ascii " x4 : "
reg4:             .fill 17, 1, ' '
s5:               .ascii " x5 : "
reg5:             .fill 17, 1, ' '
                  .asciz "\n"
.equ LGZONEAFFREG,   . - szVidregistreReg
/* pour affichage du registre d'état   */
szLigneEtat:     .ascii "Etats "
adresseLibEtat:  .fill LGZONEADR, 1, ' '
szValeursEtat:   .asciz  "\nZ=   N=   C=   V=       \n"
.equ LGZONEAFFETAT,   . - szLigneEtat
/*  donnees pour vidage mémoire */
szVidregistreMem: .ascii "Aff mémoire "
sadr1: .ascii ": "
sAdresseMem : .fill 17,1,' '
sSuiteMem: .fill NBCARLIBEL,1,' '
            .asciz "\n"
.equ LGZONEAFFMEM1,   . - szVidregistreMem
sDebmem: .fill 13, 1, ' '
s1mem: .ascii " "
sZone1: .fill 47, 1, ' '
s2mem: .ascii " "
sZone2: .fill 16, 1, ' '
s3mem: .asciz "\n"
.equ LGZONEAFFMEM2,    . - sDebmem
/*************************************************/
szMessErr: .ascii	"Code erreur hexa : "
sHexa: .space 17,' '
         .ascii "  décimal :  "
sDeci: .space 21,' '
         .asciz "\n"
.equ LGMESSERR, . -  szMessErr /* calcul de la longueur de la zone precedente */
/* a supprimer apres Test */
sMessAffHexa:    .ascii "Affichage x0 en hexa : "
sZoneHexa:       .space 20,' '
                 .asciz "\n"
.equ LGZONEAFFHEXA,   . - sMessAffHexa
/* zones pour affichage temps chrono */
szMessTemps: .ascii "Durée calculée : "
sSecondes: .fill 10,1,' '
             .ascii " s "
sMicroS:   .fill 10,1,' '
             .asciz " nanos\n"
.equ LGMESSTEMPS,           . - szMessTemps
/* zone pour la création nombres aléatoires */
.align 8
qGraine:  .quad 1234567
/* zones pour le tas */
ptZoneTas:          .quad heap_begin
ptZoneDebutTas:     .quad heap_begin
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
szZoneConv:          .skip 20
szZoneConvDS:        .skip 21
sBuffer:             .skip 100
.align 8
qwDebut:    .skip 16
qwFin:      .skip 16

/*********************************/
/*  code section                 */
/*********************************/
.text
.global afficherMessage,afficherMessageSP,affichageReg2,affRegistres16,prepRegistre16,affichetat,affReg16,affmemoireTit
.global conversion10,conversion10S,afficheErreur,genererAlea,gen_init
.global startChrono, stopChrono,allocPlace,conversionAtoD,saisieChaine
.global strInsertAtChar,reserverPlace,libererPlace,comparerChaines
/******************************************************************/
/*     Affichage d une chaine avec calcul de sa longueur          */ 
/******************************************************************/
/* x0 contient l'adresse du texte (chaine terminée par zero) */
afficherMessage:                 // fonction
    stp x0,lr,[sp,-32]!        // save  registres
    stp x1,x2,[sp,16]          // save  registres
    mov x2,#0                  // compteur taille
1:                             // boucle calcul longueur chaine
    ldrb w1,[x0,x2]            // lecture un octet
    cbz w1,2f                  // fin de chaine si zéro
    add x2,x2,#1
    b 1b
2:                             // ici x2 contient la longueue de la chaine
    mov x1,x2                  // longueur du texte
    bl afficherMessageSP
    ldp x1,x2,[sp,16]          // restaur des  2 registres
    ldp x0,lr,[sp],32          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     Affichage d une chaine                                     */ 
/******************************************************************/
/* x0 contient l'adresse du texte               */
/* x1 contient la longueur à afficher           */
afficherMessageSP:
    stp x2,lr,[sp,-32]!        // save  registres
    stp x1,x8,[sp,16]          // save  registres
    mov x2,x1                  // longueur du texte
    mov x1,x0                  // adresse du texte
    mov x0,#STDOUT             // sortie Linux standard
    mov x8, #WRITE             // code call system "write" */
    svc #0                     // call systeme Linux
    ldp x1,x8,[sp,16]          // restaur des  2 registres
    ldp x2,lr,[sp],32          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     affichage d'un registre 64 bits en binaire                 */ 
/******************************************************************/
/* x0 est le registre à afficher */
/* x1 contient le libellé       */
affichageReg2:
    stp x0,lr,[sp,-80]!        // save  registres
    stp x7,x8,[sp,64]          // save  registres
    stp x5,x6,[sp,48]          // save  registres
    stp x1,x2,[sp,32]          // save  registres
    stp x3,x4,[sp,16]          // save  registres
    mov x2,x0                  // save x0
    mov x0,x1                  // copie du libelle
    ldr x1,qAdrsLibBin         // adresse de stockage du resultat
    bl copieLibelle
    mov x0,x2                  // restau x0
2:
    ldr x1,qAdrsZoneBin        // zone reception
    mov x2,63                  // position bit de départ
    mov x3,0                   // position écriture caractère
    mov x5,1                   // valeur pour tester ubn bit
    mov x4,x0
    mov x7,48
    mov x8,49

3:                             // debut boucle
    lslv x6,x5,x2              // déplacement valeur de test à la position à tester
    tst x4,x6                  // test du bit à cette position
    csel  x6,x7,x8,eq          // si =, x6 prend la valeur x7 sinon la valeur x8
    strb w6,[x1,x3]            // caractère ascii ->  zone d'affichage
    sub x2,x2,#1               // decrement pour bit suivant
    add x3,x3,#1               // + 1 position affichage caractère
    and x6,x2,#7               // extraction 3 derniers bits du compteur
    cmp x6,#7                  // egaux à 111 ?
    bne 4f
    add x3,x3,#1               // oui on ajoute un blanc 
4:
    cmp x2,#0                  // 64 bits analysés ?
    bge 3b                     // non -> boucle
    ldr x0,qAdrsZoneMessBin    // adresse du message résultat
    mov x1,LGZONEAFFBIN
    bl afficherMessageSP           // affichage message
100:                           // fin standard de la fonction
    ldp x3,x4,[sp,16]          // restaur des  2 registres
    ldp x1,x2,[sp,32]          // restaur des  2 registres
    ldp x5,x6,[sp,48]          // restaur des  2 registres
    ldp x7,x8,[sp,64]          // restaur des  2 registres
    ldp x0,lr,[sp],80          // restaur des  2 registres
    ret    
qAdrsZoneBin:          .quad sZoneBin       
qAdrsZoneMessBin:      .quad sMessAffBin
qAdrsLibBin:           .quad sLibBin
/******************************************************************/
/*     Affichage de 6 registres                      */ 
/******************************************************************/
/* N° premier registre et adresse libelle sont sur la pile  */
affRegistres16:
    str fp,[sp,-16]!           // save fp
    mov fp,sp
    stp x0,lr,[sp,-64]!        // save  registres
    stp x1,x2,[sp,48]          // save  registres
    stp x3,x4,[sp,32]          // save  registres
    stp x5,x6,[sp,16]          // save  registres
    mov x5,x0
    //il faut recuperer sur la pile le premier registre et le libelle
    ldr x0,[fp,#24]
    ldr x1,qAdradresseLib
    bl copieLibelle
    ldr x6,qAdrsuiteReg
 
    ldr x2,[fp,#16]            // recup N0 du premier registre
    cmp x2,25                  // si > à 25
    ble 2f
    mov x2,25                  // on force 25
2:
    mov x3,#0
3:                            // debut boucle
    cbz x2,50f               // car x5 contient deja le registre x0
4:
    cmp x2,#1
    bne 5f
    ldr x5,[fp,-16]       // registre x1
    b 50f
5:
    cmp x2,#2
    bne 6f
    ldr x5,[fp,-8]       // registre x2
    b 50f
6:
    cmp x2,#3
    bne 7f
    ldr x5,[fp,-32]       // registre x3
    b 50f
7:
    cmp x2,#4
    bne 8f
    ldr x5,[fp,-24]       // registre x4
    b 50f
8:
    cmp x2,#5
    bne 9f
    ldr x5,[fp,-48]       // registre x5
    b 50f
9:
    cmp x2,#6
    bne 10f
    ldr x5,[fp,-40]       // registre x6
    b 50f
10:
    cmp x2,#7
    bne 11f
    mov x5,x7             // registre x7
    b 50f
11:
    cmp x2,#8
    bne 12f
    mov x5,x8             // registre x8
    b 50f
12:
    cmp x2,#9
    bne 13f
    mov x5,x9             // registre x9
    b 50f
13:
    cmp x2,#10
    bne 14f
    mov x5,x10             // registre x10
    b 50f
14:
    cmp x2,#11
    bne 15f
    mov x5,x11             // registre x11
    b 20f
15:
    cmp x2,#12
    bne 16f
    mov x5,x12             // registre x12
    b 50f
16:
    cmp x2,#13
    bne 17f
    mov x5,x13             // registre x13
    b 50f
17:
    cmp x2,#14
    bne 18f
    mov x5,x14             // registre x14
    b 50f
18:
    cmp x2,#15
    bne 19f
    mov x5,x15             // registre x15
    b 50f
19:
    cmp x2,#16
    bne 20f
    mov x5,x16             // registre x16
    b 50f
20:
    cmp x2,#17
    bne 21f
    mov x5,x17             // registre x17
    b 50f
21:
    cmp x2,#18
    bne 22f
    mov x5,x18             // registre x18
    b 50f
22:
    cmp x2,#19
    bne 23f
    mov x5,x19             // registre x19
    b 50f
23:
    cmp x2,#20
    bne 24f
    mov x5,x20             // registre x20
    b 50f
24:
    cmp x2,#21
    bne 25f
    mov x5,x21             // registre x21
    b 50f
25:
    cmp x2,#22
    bne 26f
    mov x5,x22             // registre x22
    b 50f
26:
    cmp x2,#23
    bne 27f
    mov x5,x23             // registre x23
    b 50f
27:
    cmp x2,#24
    bne 28f
    mov x5,x24             // registre x24
    b 50f
28:
    cmp x2,#25
    bne 29f
    mov x5,x25             // registre x25
    b 50f
29:
    cmp x2,#26
    bne 30f
    mov x5,x26             // registre x26
    b 50f
30:
    cmp x2,#27
    bne 31f
    mov x5,x27             // registre x27
    b 50f
31:
    cmp x2,#28
    bne 32f
    mov x5,x28             // registre x28
    b 50f
32:
    cmp x2,#29
    bne 33f
    ldr x5,[fp]             // registre x29 fp (sur la pile)
    b 50f
33:
    cmp x2,#30
    bne 34f
    mov x5,x30             // registre x30
    b 50f
34:
50:
    mov x0,x2
    mov x1,x3
    bl prepNumRegistre
    mov x0,x5             // contenu du registre
    mov x5,#23            // calcul de la position du contenu
    mul x1,x3,x5
    add x1,x1,6
    add x1,x1,x6         // position 
    bl prepRegistre16
    add x2,x2,1          // registre suivant
    add x3,x3,1          // N° position suivant
    cmp x3,6             // 6 registres ?
    blt 3b               // non -> boucle

    ldr x0,qAdrszVidregistreReg    // adresse du message résultat
    mov x1,LGZONEAFFREG
    bl afficherMessageSP           // affichage message
100:                           // fin standard de la fonction
    ldp x5,x6,[sp,16]          // restaur des  2 registres
    ldp x3,x4,[sp,32]          // restaur des  2 registres
    ldp x1,x2,[sp,48]          // restaur des  2 registres
    ldp x0,lr,[sp],64          // restaur des  2 registres
    ldr fp,[sp],16             // restaur fp
    add sp,sp,16               // pour les 2 paramètres passés sur la pile
    ret    
qAdrszVidregistreReg:      .quad szVidregistreReg
qAdradresseLib:            .quad adresseLib

/******************************************************************/
/*     conversion d'un registre en hexadecimal                     */ 
/******************************************************************/
/* x0 contient N° registre and x1 adresse zone receptrice   */
prepRegistre16:
    stp x0,lr,[sp,-48]!        // save  registres
    stp x1,x2,[sp,32]          // save  registres
    stp x3,x4,[sp,16]          // save  registres
    mov x2,#60                 // start bit position
    mov x4,#0xF000000000000000         // masque
    mov x3,x0                  // save entry value
1:                             // start loop
    and x0,x3,x4               // valeur du registre and du masque
    lsr x0,x0,x2               // deplacement droite
    cmp x0,#10                 // >= 10 ?
    bge 2f                     // oui
    add x0,x0,#48              // non c'est un chiffre
    b 3f
2:
    add x0,x0,#55              // sinon c'est une lettre A-F
3:
    strb w0,[x1],#1            // stocke le chiffre  et + 1 dans la pointeur
    lsr x4,x4,#4               // deplace le masque de  4 positions
    subs x2,x2,#4              // decrement compteur de 4 bits <= zero  ?
    bge 1b                     // non -> boucle

100:                           // fin standard de la fonction
    ldp x3,x4,[sp,16]          // restaur des  2 registres
    ldp x1,x2,[sp,32]          // restaur des  2 registres
    ldp x0,lr,[sp],48          // restaur des  2 registres
    ret    
/******************************************************************/
/*     Préparation affichage N° registre                      */ 
/******************************************************************/
/* x0 contient N° registre and x1 N° zone receptrice   */
prepNumRegistre:
    stp x0,lr,[sp,-64]!        // save  registres
    stp x1,x2,[sp,48]          // save  registres
    stp x3,x4,[sp,32]          // save  registres
    stp x5,x6,[sp,16]          // save  registres
    ldr x2,qAdrsuiteReg
    mov x5,23                  // decalage position affichage 
    mul x1,x1,x5               // * N° zone
    add x1,x1,#2               // ajout décalage début
    mov x5,10
    udiv x3,x0,x5              // conversion n° de registre en ascii
    cmp x3,#0                  // registre de x0 à x9
    beq 1f
    add x4,x3,#48              // registre de 10 à 30
    strb w4,[x2,x1]
    add x1,x1,1                // position suivante
    b 2f
1:
    add x6,x1,1               // effacement de la 2ième position
    mov x4,' '
    strb w4,[x2,x6]
2:
    msub x4,x3,x5,x0           //calcul reste
    add x4,x4,#48
    strb w4,[x2,x1]
100:                           // fin standard de la fonction
    ldp x5,x6,[sp,16]          // restaur des  2 registres
    ldp x3,x4,[sp,32]          // restaur des  2 registres
    ldp x1,x2,[sp,48]          // restaur des  2 registres
    ldp x0,lr,[sp],64          // restaur des  2 registres
    ret
qAdrsuiteReg:           .quad suiteReg  
/******************************************************************/
/*     Affichage d'un registre en hexadecimal                     */ 
/******************************************************************/
/* x0 contient la valeur    */
affReg16:
    stp x0,lr,[sp,-48]!        // save  registres
    stp x1,x2,[sp,32]          // save  registres
    stp x3,x4,[sp,16]          // save  registres
    ldr x1,qAdrsZoneHexa       // zone reception
    mov x2,#60                 // start bit position
    mov x4,#0xF000000000000000         // masque
    mov x3,x0                  // save valeur de l'entrée
1:                             // start loop
    and x0,x3,x4               // valeur du registre and du masque
    lsr x0,x0,x2                  // deplacement droite
    cmp x0,#10                 // >= 10 ?
    bge 2f                     // oui
    add x0,x0,#48              // non c'est un chiffre
    b 3f
2:
    add x0,x0,#55                 // sinon c'est une lettre A-F
3:
    strb w0,[x1],#1            // stocke le chiffre  et + 1 dans la pointeur
    lsr x4,x4,#4                  // deplace le masque de  4 positions
    subs x2,x2,#4                 // decrement compteur de 4 bits <= zero  ?
    bge 1b                     // non -> boucle
    ldr x0,qAdrsMessAffHexa    // adresse du message résultat
    mov x1,LGZONEAFFHEXA
    bl afficherMessage           // affichage message
100:                           // fin standard de la fonction
    ldp x3,x4,[sp,16]          // restaur des  2 registres
    ldp x1,x2,[sp,32]          // restaur des  2 registres
    ldp x0,lr,[sp],48          // restaur des  2 registres
    ret    
qAdrsMessAffHexa:      .quad sMessAffHexa
qAdrsZoneHexa:         .quad sZoneHexa
/***************************************************/
/*   affichage des drapeaux du registre d'état     */
/***************************************************/
/* x0 contient l'adresse du libelle */
affichetat:
    stp x0,lr,[sp,-64]!        // save  registres
    stp x1,x2,[sp,48]          // save  registres
    stp x3,x4,[sp,32]          // save  registres
    stp x5,x6,[sp,16]          // save  registres
    mrs x5,nzcv             // save du registre d'état
    ldr x3,qAdradresseLibEtat         // adresse de stockage du resultat
    mov x2,#0
1:                             // boucle copie
    ldrb w4,[x0,x2]            // charge un octet
    cmp w4,#0                  // zéro ?
    beq 2f                     // oui -> fin boucle
    strb w4,[x3,x2]            // stocke dans zone affichage
    add x2,x2,#1               // increment indice
    cmp x2,#LGZONEADR          // longueur maxi ?
    ble 1b                     // non -> boucle
2:

    ldr x1,qAdrszValeursEtat
    msr nzcv,x5    /*restaur registre d'état */
    beq 1f               // flag zero à 1
    mov x0,#48
    strb w0,[x1,#3]
    b 2f
1:    
    mov x0,#49       // Zero à 1
    strb w0,[x1,#3]
2:    
    bmi 3f          // Flag negatif a 1
    mov x0,#48
    strb w0,[x1,#8]
    b 4f
3:    
    mov x0,#49
    strb w0,[x1,#8]
4:        
    bvs 5f         // flag overflow à 1 ?
    mov x0,#48
    strb w0,[x1,#18]
    b 6f
5:                  // overflow = 1
    mov x0,#49
    strb w0,[x1,#18]
6:        
    bcs 7f         // flag carry à 1 ?
    mov x0,#48
    strb w0,[x1,#13]
    b 8f
7:                  // carry = 1
    mov x0,#49
    strb w0,[x1,#13]
8:        
    ldr x0,qAdrszLigneEtat  // affiche le résultat
    mov x1,LGZONEAFFETAT
    bl afficherMessageSP 
 
100:   
   /* fin standard de la fonction  */
    msr nzcv,x5                // restaur registre d'état
    ldp x5,x6,[sp,16]          // restaur des  2 registres
    ldp x3,x4,[sp,32]          // restaur des  2 registres
    ldp x1,x2,[sp,48]          // restaur des  2 registres
    ldp x0,lr,[sp],64          // restaur des  2 registres
    ret    
qAdrszLigneEtat:       .quad szLigneEtat
qAdradresseLibEtat:    .quad adresseLibEtat
qAdrszValeursEtat:     .quad szValeursEtat
/*******************************************/    
/* affichage zone memoire                  */
/*******************************************/    
/* x0  adresse memoire  x1 nombre de bloc x2 titre */
affmemoireTit:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x5,x6,[sp,-16]!        // save  registres
    stp x7,x8,[sp,-16]!        // save  registres
    mov x4,x0                  // save adresse mémoire
    mov x6,x1                  // save nombre de bloc
    ldr x1,qAdrsAdresseMem     //adresse de stockage du resultat
    bl prepRegistre16          // conversion en base 16

    mov x0,x2                  // recup libelle dans x2
    ldr x1,qAdrsAdresse_suiteMem // adresse de stockage du resultat
    bl copieLibelle
    ldr x0,qAdrsAdresse_chaineMem    // affichage entete
    mov x1,LGZONEAFFMEM1
    bl afficherMessageSP
    mov x2,x4                        //récuperation debut memoire a afficher
                                     //calcul du debut du bloc de 16 octets
    mov x1, x2, ASR #4               // x1 ← (x2/16)
    mov x1, x1, LSL #4               // x1 ← (x2*16)
    /* mettre une étoile à la position de l'adresse demandée*/
    mov x8,#3                       // 3 caractères pour chaque octet affichée 
    sub x0,x2,x1                    // calcul du deplacement dans le bloc de 16 octets
    mul x5,x0,x8                    // deplacement * par le nombre de caractères
    ldr x0,qAdrsAdresse_zone1       // adresse de stockage
    add x7,x0,x5                    // calcul de la position
    sub x7,x7,#1                    // on enleve 1 pour se mettre avant le caractère
    mov w0,#'*'           
    strb w0,[x7]                    // stockage de l'étoile
1:                                  // debut boucle affichage des blocs
    mov x5,x1                      // afficher le debut  soit x1
    mov x0,x1
    ldr x1,qAdrszZoneConv           // conversion adresse du bloc en hexa
    bl prepRegistre16               // conversion en base 16
                                    // recopie de 12 caractères de l'adresse
    mov x8,#3                       // pour supprimer les 4 premiers zeros
    mov x0,#0
    ldr x1,qAdrszZoneConv
    ldr x2,qAdrsAdresse_debmem     // et mettre le résultat dans la zone d'affichage
2:
    ldrb w4,[x1,x8]
    strb w4,[x2,x0]
    add x0,x0,#1
    add x8,x8,#1
    cmp x8,#15                     // arrêt au 15ième caractère
    ble 2b
                                   // balayer 16 octets de la memoire
    mov x8,#3
    mov x2,#0
    mov x1,x5
3:                                 // debut de boucle de vidage par bloc de 16 octets
    ldrb w4,[x1,x2]                // recuperation du byte à l'adresse début + le compteur
                                   // conversion byte pour affichage
    ldr x0,qAdrsAdresse_zone1      // adresse de stockage du resultat
    mul x5,x2,x8                   // calcul position x5 <- x2 * 3 
    add x0,x0,x5
    mov x3, x4, ASR #4             // x3 ← (x4/16)
    cmp x3,#9                      // inferieur a 10 ?
    bgt 4f
    add x5,x3,#48                  // oui
    b 5f
4:
    add x5,x3,#55                  // c'est une lettre en hexa
5:
    strb w5,[x0]                  // on le stocke au premier caractères de la position 
    add x0,x0,#1                  // 2ième caractere
    mov x5,x3,LSL #4              // x5 <- (x4*16)
    sub x3,x4,x5                  // pour calculer le reste de la division par 16
    cmp x3,#9                     // inferieur a 10 ?
    bgt 6f
    add x5,x3,#48
    b 61f
6:
    add x5,x3,#55
61:
    strb w5,[x0]                  // stockage du deuxieme caractere
    add x2,x2,#1                  // +1 dans le compteur
    cmp x2,#16                    // fin du bloc de 16 caractères ?
    blt 3b
    /* affichage en caractères */
    mov x2,#0                     // compteur
7:                                // debut de boucle
    ldrb w4,[x1,x2]               // recuperation du byte à l'adresse début + le compteur
    cmp w4,#31                    // compris dans la zone des caractères imprimables ?
    ble 8f                        // non
    cmp w4,#125
    bgt 8f
    b 9f
8:
    mov w4,#46                    // on force le caractere .
9:
    ldr x0,qAdrsAdresse_zone2     // adresse de stockage du resultat
    add x0,x0,x2
    strb w4,[x0]
    add x2,x2,#1
    cmp x2,#16                    // fin de bloc ?
    blt 7b    

    /* affichage resultats */
    ldr x0,qAdrsAdresse_debmem
    mov x5,x1                    // save x1
    mov x1,LGZONEAFFMEM2
    bl afficherMessageSP
    mov x1,x5                    // restaur x1
    mov w0,#' '
    strb w0,[x7]                 // on enleve l'étoile pour les autres lignes
    add x1,x1,#16                // adresse du bloc suivant de 16 caractères
    subs x6,x6,#1                // moins 1 au compteur de blocs
    bgt 1b                       // boucle si reste des bloc à afficher
100:                           // fin de la fonction
    ldp x7,x8,[sp],16          // restaur des  2 registres
    ldp x5,x6,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

qAdrsAdresse_chaineMem:       .quad szVidregistreMem
qAdrsAdresse_debmem:           .quad sDebmem
qAdrsAdresse_suiteMem:         .quad sSuiteMem
qAdrsAdresse_zone1:            .quad sZone1
qAdrsAdresse_zone2:            .quad sZone2
qAdrsAdresseMem:               .quad sAdresseMem
qAdrszZoneConv:                .quad szZoneConv
/*******************************************/    
/* copie du libellé dans zone affichage        */
/*******************************************/    
/* x0  adresse libelle  x1 adresse de reception */
copieLibelle:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    mov x2,0
1:                               // boucle copie
    ldrb w3,[x0,x2]
    cbz w3,2f
    strb w3,[x1,x2]
    add x2,x2,1
    b 1b
2:
    mov w3,' '                 // on met des blancs en fin de libellé 
3:                              // pour effacer libellé précédent si plus grand
    cmp x2,#NBCARLIBEL
    bge 4f
    strb w3,[x1,x2]
    add x2,x2,1
    b 3b                         // et boucle
4:
    ldp x2,x3,[sp],16          // restaur des  2 registres
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
    //affmemtit routine x1 2
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
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x5,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     conversion décimale signée                             */ 
/******************************************************************/
/* x0 contient la valeur à convertir  */
/* x1 contient la zone receptrice  longueur >= 21 */
/* la zone recptrice contiendra la chaine ascii cadrée à gauche */
/* et avec un zero final */
/* x0 retourne la longueur de la chaine sans le zero */
.equ LGZONECONV,   21
conversion10S:
    stp x5,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    cmp x0,0
    bge 11f
    mov x3,'-'
    mvn x0,x0
    add x0,x0,1
    b 12f
11:
    mov x3,'+'
12:
    strb w3,[x1]
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
    //affmemtit routine x1 2
    mov x2,LGZONECONV          // calcul longueur de la chaine (21 - dernière position)
    sub x0,x2,x4               // car pas d'instruction rsb en 64 bits
                               // mais il faut déplacer la zone au début
    cmp x4,1
    beq 3f                     // si pas complète
    mov x2,1                   // position début  
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
    add x0,x0,1                // longueur chaine doit tenir compte du signe
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x5,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/***************************************************/
/*   affichage message d'erreur              */
/***************************************************/
/* x0 contient le code erreur  x1, l'adresse du message */
afficheErreur:
    stp x2,lr,[sp,-16]!       // save  registres
    mov x2,x0                 // save du code erreur
    mov x0,x1
    bl afficherMessage
    mov x0,x2                 // conversion hexa du code erreur
    ldr x1,qAdrsHexa          // adresse de stockage du resultat
    bl prepRegistre16
                              // conversion decimale

    ldr x1,qAdrszZoneConvDS  // adresse de stockage du resultat
    bl conversion10S
    ldr x3,qAdrsDeci         // recopie résultat dans zone d'affichage
1:
    ldrb w4,[x1],1           // charge un octet
    cbz w4,2f                // zero final ?
    strb w4,[x3],1           // non, stockage dans zone reception
    b 1b
2:
    ldr x0,qAdrszMessErr       // affichage du message
    mov x1,LGMESSERR
    bl afficherMessageSP
  
   	mov x0,x2                 // retour du code erreur

100:                          // fin standard de la fonction
    ldp x2,lr,[sp],16         // restaur des  2 registres
    ret                       // retour adresse lr x30
qAdrsHexa:             .quad sHexa
qAdrsDeci:             .quad sDeci
qAdrszMessErr:         .quad szMessErr
qAdrszZoneConvDS:      .quad szZoneConvDS
/***************************************************/
/*   Initialisation de la graine                   */
/***************************************************/
/* x0 contient une valeur initiale */
gen_init:         // fonction
    stp x1,lr,[sp,-16]!        // save  registres
    ldr x1,qAdriGraine
    str x0,[x1]
100:                           // fin standard de la fonction
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdriGraine:      .quad qGraine
/***************************************************/
/*   génération d'un nombre aléatoire              */
/***************************************************/
/* x0 contient la borne superieure */
genererAlea:         // fonction
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    mov x3,x0           // valeur maxi
    ldr x0,qAdriGraine  // graine
    ldr x2,qVal1 
    ldr x1,[x0]         // charger la graine
    mul x1,x2,x1
    ldr x2,qVal2
    add x1,x1,x2
    str x1,[x0]      // sauver graine
    udiv x2,x1,x3       // 
    msub x0,x2,x3,x1    // calcul resultat modulo plage

100:                    // fin standard de la fonction
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

qVal1:         .quad 0x0019660d   //0x343FD
qVal2:         .quad 0x3c6ef35f //0x269EC3
/********************************************************/
/* Lancement du chrono                                  */
/********************************************************/
startChrono:                 // fonction
    stp x0,lr,[sp,-16]!      // save  registres
    stp x1,x8,[sp,-16]!      // save  registres
    ldr x1,qAdrqwDebut       // zone de reception du temps début
    mov x0,0
    mov x8,GETTIME           // appel systeme gettimeofday
    svc 0 
    cmp x0,#0                // verification si l'appel est OK
    bge 100f
                             // affichage erreur
    adr x1,szMessErreurCH    // x0 <- code erreur, x1 <- adresse chaine */
    bl   afficheErreur       // appel affichage message
100:                         // fin standard  de la fonction  */
    ldp x1,x8,[sp],16        // restaur des  2 registres
    ldp x0,lr,[sp],16        // restaur des  2 registres
    ret                      // retour adresse lr x30
szMessErreurCH: .asciz "Erreur debut Chrono rencontrée.\n"
.align 4
qAdrqwDebut:         .quad qwDebut
/********************************************************/
/* Affichage du temps                                   */
/********************************************************/
/* pas de parametres */
stopChrono:                    // fonction
    stp x8,lr,[sp,-16]!        // save  registres
    stp x0,x5,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    ldr x1,qAdrqwFin           // zone de reception du temps fin
    mov x0,0
    mov x8,GETTIME             // appel systeme gettimeofday
    svc 0 
    cmp x0,#0
    blt 99f                    // verification si l'appel est OK
                               // calcul du temps
    ldr x0,qAdrqwDebut         // temps départ
    ldr x2,[x0]                // secondes
    ldr x3,[x0,#8]             // micro secondes
    ldr x0,qAdrqwFin           // temps arrivée
    ldr x4,[x0]                // secondes
    ldr x5,[x0,#8]             // micro secondes
    sub x2,x4,x2               // nombre de secondes ecoulées
    subs x3,x5,x3              // nombre de microsecondes écoulées
    bpl 1f
    sub x2,x2,#1               // si negatif on enleve 1 seconde aux secondes
    ldr x4,iSecMicro
    add x3,x3,x4               // et on ajoute 1 000 000 000 pour avoir un nb de nanosecondes exact
1:
    //affregtit avantconv 0
    mov x0,x2                  // conversion des secondes en base 10 pour l'affichage
    ldr x1,qAdrsBuffer
    bl conversion10
    ldr x4,qAdrsSecondes      // recopie des secondes dans zone affichage
2:
    ldrb w0,[x1],1
    cbz w0,3f
    strb w0,[x4],1
    b 2b
3:
    mov x0,x3                 // conversion des microsecondes en base 10 pour l'affichage
    ldr x1,qAdrsBuffer
    bl conversion10
    ldr x4,qAdrsMicroS        // recopie des micro secondes dans zone affichage
4:
    ldrb w0,[x1],1
    cbz w0,5f
    strb w0,[x4],1
    b 4b
5:
    ldr x0,qAdrszMessTemps   // r0 ← adresse du message 
    bl afficherMessage         // affichage message dans console
    b 100f
99:                          // erreur rencontrée
    adr x1,szMessErreurCHS   // r0 <- code erreur, r1 <- adresse chaine
    bl   afficheErreur       // appel affichage message
100:                         // fin standard  de la fonction
    ldp x1,x2,[sp],16        // restaur des  2 registres
    ldp x3,x4,[sp],16        // restaur des  2 registres
    ldp x0,x5,[sp],16        // restaur des  2 registres
    ldp x8,lr,[sp],16        // restaur des  2 registres
    ret                      // retour adresse lr x30   
/* variables */
qAdrqwFin:               .quad qwFin
qAdrsBuffer:             .quad sBuffer
qAdrszMessTemps:         .quad szMessTemps
qAdrsSecondes:           .quad sSecondes
qAdrsMicroS:             .quad sMicroS
iSecMicro:               .quad 1000000000    
szMessErreurCHS: .asciz "Erreur stop Chrono rencontrée.\n"
.align 4
/******************************************************************/
/*     conversion chaine ascii en nombre                          */ 
/******************************************************************/
/* x0 contient l'adresse de la chaine terminée par 0x0 ou 0xA */
/* x0 retourne le nombre */ 
conversionAtoD:
    stp x5,lr,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    mov x1,#0
    mov x2,#10             // facteur
    mov x4,x0              // save de l'adresse dans x4
    mov x3,#0              // signe positif par defaut
    mov x0,#0              // initialisation à 0
    mov x5,#0
1:                         // boucle d'élimination des blancs du debut
    ldrb w5,[x4],1         // chargement dans w5 de l'octet situé au debut + la position
    cbz w5,100f            // fin de chaine -> fin routine
    cmp w5,#0x0A           // fin de chaine -> fin routine
    beq 100f
    cmp w5,#' '            // blanc au début
    beq 1b                 // non on continue
2:
    cmp x5,#'-'            // premier caractere est -
    bne 3f
    mov x3,#1              // signale un nombre négatif
    b 4f                   // puis on avance à la position suivante
3:                         // debut de boucle de traitement des chiffres
    cmp x5,#'0'            // caractere n'est pas un chiffre
    blt 4f
    cmp x5,#'9'            // caractere n'est pas un chiffre
    bgt 4f
                           // caractère est un chiffre
    sub w5,w5,#48

    mul x0,x2,x0           // multiplier par facteur
    smulh x1,x2,x0         // partie haute
    cbnz x1,99f            // depassement de capacité
    add x0,x0,x5           // sinon ajout à x0
4:
    ldrb w5,[x4],1         // chargement de l'octet et avancement
    cbz w5,5f              // fin de chaine -> fin routine
    cmp w5,#0xA            // fin de chaine ?
    bne 3b                 // non alors boucler
5:
    cmp x3,#1              // test du registre x3 pour le signe
    cneg x0,x0,eq          // si egal inversion de la valeur
    cmn x0,0               // carry à zero pas d'erreur
    b 100f
99:                        // erreur de dépassement
    adr x1,szMessErrDep
    bl  afficheErreur 
    cmp x0,0               // carry à un car erreur
    mov x0,#0              // en cas d'erreur on retourne toujours zero
100:
    ldp x1,x2,[sp],16      // restaur des  2 registres
    ldp x3,x4,[sp],16      // restaur des  2 registres
    ldp x5,lr,[sp],16      // restaur des  2 registres
    ret                    // retour adresse lr x30
szMessErrDep:      .asciz "Nombre trop grand : dépassement de capacite de 64 bits. :\n"
.align 4                   // instruction pour réaligner les routines suivantes
/******************************************************************/
/*     Allocation place sur le tas                                */ 
/******************************************************************/
/* x0 contient la taille demandée en octet */
/* x0 retourne l'adresse de début de la zone allouée */
/*  ou -1 si l'allocation n'a pu être faite */
allocPlace:
    stp x8,lr,[sp,-16]!       // save  registres
    stp x1,x2,[sp,-16]!       // save  registres
    bic x2,x0,0b111           // pour raz des 3 derniers bits
    add x2,x2,8               // pour respecter alignement
    mov x0,0                  // recuperation de l'adresse du tas
    mov x8,BRK                // code de l'appel systeme 'brk'
    svc 0                     // appel systeme
    cmp x0,#-1                // erreur allocation
    beq 100f
    mov x1,x0                 // save du début
    add x0,x0,x2              // reservation place demandé
    mov x8,BRK                // code de l'appel systeme 'brk'
    svc 0                     // appel systeme
    cmp x0,-1                 // erreur allocation
    beq 100f
    mov x0,x1                 //retour adresse début 

100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x8,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*     routine de saisie d'une chaine de caractères               */ 
/******************************************************************/
/* x0 contient la taille demandée en octet */
/* x0 retourne l'adresse de la chaine saisie ou negatif si erreur*/
/* x1 la longueur de la chaine */
.equ TAILLEBUFFERSAIS,     100 
saisieChaine:
    stp x8,lr,[sp,-16]!       // save  registres
    stp x2,x3,[sp,-16]!       // save  registres

    /* allocation de la place pour le buffer de saisie */
    mov x0,TAILLEBUFFERSAIS
    bl allocPlace               // allocation place sur le tas
    cmp x0,-1                   // erreur allocation
    beq 100f
    mov x1 ,x0                  // save début buffer
    /* Saisie d'une chaine */
    mov x0,0                    //STDIN
                                // adresse du buffer de lecture dans x1
    mov x2,TAILLEBUFFERSAIS     // taille buffer
    mov x8,READ                 // call system linux
    svc 0 
    cmp x0,#0                   // erreur ?
    blt 100f
    mov x2,x1
    mov x1,x0
    mov x0,x2

100:
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x8,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
/******************************************************************/
/*   search characters in string  */ 
/******************************************************************/
/* x0 contains the address of string 1 */
/* x1 contains the address of insertion string   */
/* x0 return the address of new string  on the heap */
/* or -1 if error   */
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
    mov x0,#0                                // allocation place heap
    mov x8,BRK                               // call system 'brk' 
    svc #0
    mov x5,x0                                // save address heap for output string
    add x0,x0,x3                             // reservation place x3 length
    mov x8,BRK                               // call system 'brk'
    svc #0
    cmp x0,#-1                               // allocation error
    beq 99f
    
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
    //affregtit etiq5  1
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
/*   reserver place sur le tas                     */
/***************************************************/
// x0 contient la place à réserver 
// x0 retourne l'adresse de début de la place réservée
reserverPlace:            // INFO: reserverPlace
    stp x1,lr,[sp,-16]!   // save  registres
    stp x2,x3,[sp,-16]!   // save  registres
    mov x1,x0
    tst x1,#0b111          // la place est un multiple de 8
    beq 1f                // oui
    and x1,x1,#0xFFFFFFFFFFFFFFF8    // sinon ajustement à un multiple de 8 superieur
    add x1,x1,#8
1:
    ldr x2,qAdrptZoneTas
    ldr x0,[x2]
    add x1,x1,x0          // vérification de dépassement
    ldr x3,qAdrFinTas
    cmp x1,x3
    blt 2f
    adr x0,szMessErrTas
    bl afficherMessage
    mov x0,#-1
    b 100f
2:
    str x1,[x2]
    //mov x0,0
   // vidregtit tas
100:                      // fin standard de la fonction
    ldp x2,x3,[sp],16     // restaur des  2 registres
    ldp x1,lr,[sp],16     // restaur des  2 registres
    ret     
qAdrptZoneTas:       .quad ptZoneTas
qAdrFinTas:          .quad heap_end
szMessErrTas:        .asciz "Erreur : tas trop petit !!!\n"
.align 4
/***************************************************/
/*   liberer place sur le tas                     */
/***************************************************/
// x0 contient l'adresse de début de la place réservée
libererPlace:               // INFO: libererPlace
    stp x1,lr,[sp,-16]!     // save  registres
    ldr x1,qAdrDebutTas
    cmp x0,x1
    blt 99f
    ldr x1,qAdrFinTas
    cmp x0,x1
    bge 99f
    ldr x1,qAdrptZoneTas
    str x0,[x1]
    b 100f
99:
    adr x0,szMessErrTas1
    bl afficherMessage
    mov x0,#-1
100:
    ldp x1,lr,[sp],16     // restaur des  2 registres
    ret     
qAdrDebutTas:     .quad heap_begin
szMessErrTas1:    .asciz "Erreur : adresse plus petite ou plus grande que le tas !!!\n"
.align 4
/************************************/       
/* comparaison de chaines           */
/************************************/      
/* x0 et x1 contiennent les adresses des chaines */
/* retour 0 dans x0 si egalite */
/* retour -1 si chaine x0 < chaine x1 */
/* retour 1  si chaine x0> chaine x1 */
comparerChaines:              // INFO: comparaison
    stp x2,lr,[sp,-16]!   // save registres
    stp x3,x4,[sp,-16]!   // save registres
    mov x2,#0             // indice
1:    
    ldrb w3,[x0,x2]       // octet chaine 1
    ldrb w4,[x1,x2]       // octet chaine 2
    cmp w3,w4
    blt 3f                // plus petite
    bgt 4f                // plus grande
    cbz w3,2f             // si egalite test si fin de chaine
    add x2,x2,#1          // sinon plus 1 dans indice
    b 1b                  // et boucle
2:
    mov x0,#0             // egalite
    b 100f
3:
    mov x0,#-1            // plus petite
    b 100f
4:
    mov x0,#1             // plus grande
100:
    ldp x3,x4,[sp],16     // restaur registres
    ldp x2,lr,[sp],16     // restaur registres
    ret
  
