/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* test des instructions 64 bits de manipulation de bits */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"

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
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
qZonesTest:         .skip 8 * 20
szZoneRec1:         .skip 30
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    affichelib and
    mov x1,0b1100
    mov x2,0b1010
    and x0,x1,x2
    affbintit  inst_and
    affichelib orr
    mov x1,0b1100
    mov x2,0b1010
    orr x0,x1,x2
    affbintit  inst_orr
    affichelib orn
    mov x1,0b1100
    mov x2,0b1010
    orn x0,x1,x2
    affbintit  inst_orn
    affichelib eor
    mov x1,0b1100
    mov x2,0b1010
    eor x0,x1,x2
    affbintit  inst_eor
    affichelib eon
    mov x1,0b1100
    mov x2,0b1010
    eon x0,x1,x2
    affbintit  inst_eon
    affichelib bic
    mov x1,0b1100
    mov x2,0b1010
    bic x0,x1,x2
    affbintit  inst_bic
    affichelib bic_bis
    mov x1,0b1111111111111
    //mov x2,0b1010
    bic x0,x1,0b1111
    affbintit  inst_bic_bis

    affichelib lsr          // deplacement droite
    mov x1,0b1100
    lsr x0,x1,2
    affbintit  inst_lsr
    affichelib lsl         // deplacement gauche
    mov x1,0b11
    mov x2,8
    lsl x0,x1,x2
    affbintit  inst_lsl
    affichelib asr         // deplacement droite avec report du signe
    mov x1,-100
    mov x2,2
    asr x0,x1,x2           // donc division de -100 par 4
    affbintit  inst_asr
    ldr x1,qAdrszZoneRec1  // pour affichage du résultat en décimal signé
    bl conversion10S
    mov x1,x0
    ldr x0,qAdrszZoneRec1
    bl affichageMessSP
    ldr x0,qAdrszRetourLigne
    mov x1,1
    bl affichageMessSP
    //mov x0,qAdrszZoneRec1   //TODO a revoir ce cas 
    //affregtit verif 0
   affichelib ror
    mov x1,0b11
    mov x2,8
    ror x0,x1,x2
    affbintit  inst_ror
    affichelib rorsup64
    mov x1,0b11
    mov x2,70
    ror x0,x1,x2
    affbintit  inst_rorsup64
    affichelib clz
    mov x1,0b1010
    clz x0,x1                  // comptage des zeros à gauche
    affregtit compteur_clz 0
    affichelib cls
    mov x1,-2
    cls x0,x1
    affregtit compteur_cls 0   // comptage des 1 à gauche
    affichelib rbit
    mov x1,0b11010
    rbit x0,x1                // inversion des bits 
    affbintit  inst_rbit
    affichelib rev
    mov x1,0b11010
    rev x0,x1                 // inversion octets
    affbintit  inst_rev
    affichelib rev16
    mov x1,0b11010
    rev16 x0,x1              // inversion demi mot
    affbintit  inst_rev16
    affichelib rev32
    mov x1,0b11010
    rev32 x0,x1              // inversion mot
    affbintit  inst_rev32
    affichelib bfi
    mov x1,0b110101011          // insere les 2 bits de droite de x1
    bfi x0,x1,3,2               // à la place 3 et 4 (soit position 4 et 5) de x0
    affbintit  inst_bfi         // car premier bit est le bit 0
    affichelib bfxil            // bits extract et insert
    mov x1,0b110101011          // insere les 2 bits en position 3 et 4 de x1
    bfxil x0,x1,3,2               // à la place 0 et 1 de x0
    affbintit  inst_bfxil         // autres bits inchangés
    affichelib ubfx
    mov x1,0b110101011          // insere les 2 bits en position 3 et 4 de x1
    ubfx x0,x1,3,2               // à la place 0 et 1 de x0
    affbintit  inst_ubfx         // raz autres bits 
    affichelib ubfiz
    mov x0,0b11111111111
    mov x1,0b110101011          // insere les 2 bits en position 0 et 1 de x1
    ubfiz x0,x1,3,2               // à la place 3 et 4 de x0
    affbintit  inst_ubfiz         // raz autres bits  
    affichelib uxtb
    mov x0,0b11111111111
    mov x1,0b110101011           // insere le premier octet de x1
    uxtb x0,w1                   // dans x0 
    affbintit  inst_uxtb         // raz autres bits  
    affichelib sxtw
    mov x0,0b11111111111
    mov w1,-1                    // insere le registre 32 bits
    sxtw x0,w1                   // dans x0 
    affbintit  inst_sxtw         // et complete le signe 
    affichelib extr
    mov x0,0b11111111111
    mov x1,0b110101011           // extrait de la paire de registres x1 x2
    mov x2,0b1111                // 64 bits à partir de la position 2
    extr x0,x1,x2,2              //
    affbintit  inst_extr         //  x1 et x2 sont inchangés
    mov x0,x2
    affbintit  inst_extr_x2   
 
    mov x0,x1
    affbintit  inst_bfxil_x1
    /* calcul d'une valeur absolue */
    affichelib exemplevaleurabsolue
    mov x1,-5              // ou remplacer par 5 
    asr x0,x1,63
    eor x1,x0,x1
    sub x0,x1,x0           // x0 contient maintenant la valeur absolue
    ldr x1,qAdrszZoneRec1  // pour affichage du résultat en décimal signé
    bl conversion10S
    mov x1,x0
    ldr x0,qAdrszZoneRec1
    bl affichageMessSP
    ldr x0,qAdrszRetourLigne
    mov x1,1
    bl affichageMessSP
    /* pour test de la pile non alignée */
   // bl testRoutine          // enlever le commentaire et recompiler
100:                            // fin standard du programme
    ldr x0,qAdrszMessFinPgm     // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdriZonesTest:          .quad qZonesTest
qAdrszZoneRec1:          .quad szZoneRec1
/******************************************************************/
/*     test routine                                               */ 
/******************************************************************/
testRoutine:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    str x3,[sp,-8]!            // DANGER cette instruction entraine erreur du bus
    affichelib routine
    mov x0,0x100
    mov x2,0x200
100:
    ldr x3,[sp],8            // Non car la pile doit toujours etre alignée
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

