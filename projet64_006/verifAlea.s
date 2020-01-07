/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* test générateur nombres aléatoires asm 64 bits  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"
.equ MAXI, 1000
.equ PLAGE, 100
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
szRetourligne:            .asciz  "\n"

szMessMoyenne:  .asciz  "Moyenne : @ \n"
 
/* pour affichage nombre en C   */       
szFormat:   .asciz "Ecart type = %f \n" 
szFormat1:   .asciz "Moyenne = %f \n" 
szFormatKhi: .asciz "Khi = %f \n" 
//szZoneFinal: .fill 100,1,' '
.align 4
//qGraine:  .quad 1234567
qGraine:  .quad 987654321

/*********************************/
/* UnInitialized data            */
/*********************************/
.bss
qNombre:      .skip 8 
qtabTirage:   .skip 8 * PLAGE
sZoneConv:   .skip 50
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main
main:
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    mov x4,0
    mov x5,0
    mov x0,0                    // init x0 
    fmov d3, xzr                // init ecart type
    fmov d8, xzr                // init moyenne

    mov x3,MAXI
    fmov d2,x3                  // préparation du diviseur
    scvtf d2,d2                 // et conversion en float
    mov x0,0                    // raz de la table des tirages
    mov x1,0
    ldr x2,qAdrqtabTirage
1:    
    str x0,[x2,x1,lsl 3]
    add x1,x1,1
    cmp x1,PLAGE
    blt 1b
    ldr x0,qAdrqGraine
    ldr x0,[x0]
    bl gen_init
2:    
    mov x0,#PLAGE               // valeur  maxi
    bl genererAlea              // fonction de génération d'un nombre aléatoire
    ldr x1,[x2,x0,lsl #3]       // on compte le nombre de tirage pour un chiffre
    add x1,x1,#1
    str x1,[x2,x0,lsl #3]
    fmov d1, x0                 // récupération du nombre dans d1
    scvtf d1,d1                 // et conversion en float
    fdiv  d0,d1,d2              // calcul de la moyenne
    fadd d8,d8,d0               // ajout dans la totalisation
    fmul d1,d1,d1               // calcul de l'ecart type
    fdiv d0,d1,d2   
    fadd d3,d3,d0               // ajout dans la totalisation

    ldr x3,qAdrqNombre
    str d3, [x3] 
    add x5,x5,x0    
    add x4,x4,1
    cmp x4,#MAXI
    blt 2b                      // boucle
                                // fin de boucle
    udiv x0,x5,x4
    ldr x1,qAdrsZoneConv
    bl conversion10
    ldr x0,qAdrszMessMoyenne
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    bl affichageMess            // affichage message dans console

    fmul d0,d8,d8               // calcul de l'écart type final
    fsub d1,d3,d0               // après calcul du carre de la moyenne on le soustrait
    fsqrt d3,d1                 // de la somme des ecarts type et on calcule la racine carrée
    
    ldr x0,qAdrszFormat
    fmov d0,d3
    bl printf                   // affichage ecart type
    ldr x0,qAdrszFormat1
    fmov d0,d8
    bl printf                   // affichage moyenne
                                // calcul du KHI
    mov x0,#0
    mov x1,#0
    ldr x2,qAdrqtabTirage
3:
    ldr x3,[x2,x1,lsl #3]
    mov x4,x3
    mul x4,x3,x4                // calcul du carré de chaque volume de tirage
    add x0,x0,x4                // ajout au total précedent
    add x1,x1,#1
    cmp x1,#PLAGE
    blt 3b
                                // calcul final
    fmov d1,x0                  // stockage du total dans s1
    scvtf d1,d1                 // et conversion en float
    mov x1,MAXI          
    fmov d2,x1                  // puis le nombre de tirage dans s2
    scvtf d2,d2                 // et conversion en float
    mov x2,#PLAGE
    fmov d3,x2                  // puis la plage dans d3
    scvtf d3,d3                 // et conversion en float
    fdiv d4,d1,d2               // division du total par le nombre de tirage
    fmul d1,d4,d3               // multiplier par la plage
    fsub d4,d1,d2               // et on enleve le nombre de tirage
    ldr x0,qAdrszFormatKhi      // pour l'impression par la fonction du C
    fmov d0,d4
    bl printf                   // affichage Khi

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
qAdrqtabTirage:          .quad qtabTirage
qAdrqGraine:             .quad qGraine
qAdrqNombre:             .quad qNombre
qAdrsZoneConv:           .quad sZoneConv
qAdrszMessMoyenne:       .quad szMessMoyenne
qAdrszFormat:            .quad szFormat
qAdrszFormat1:           .quad szFormat1
qAdrszFormatKhi:         .quad szFormatKhi

