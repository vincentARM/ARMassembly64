/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* gestion des cles OPENSSL  64 bits  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"

.equ LGZONECLEPUB,      2000
.equ LGZONECLEPRIV,      4096 - 16
.equ RSA_F4,  0x10001

.equ OPEN,  56
.equ CLOSE, 57
.equ O_RDONLY, 0               // ouverture lecture seule
.equ O_WRONLY, 0x0001          // ouverture ecriture seule
.equ O_RDWR,   0x0002          // ecriture et lecture
.equ O_CREAT,  0x040           // create if nonexistant
.equ AT_FDCWD,    -100         // code répertoire courant
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*********************************/
/* Initialized data              */
/*********************************/
.data
szMessDebutPgm:          .asciz "Début programme.\n"
szMessFinPgm:            .asciz "Fin ok du programme.\n"
szRetourLigne:            .asciz "\n"

szTypeSHA256:        .asciz "SHA256"
szPassPhrase:        .asciz "replace_me"    // a remplacer pour toute utilisation
.equ LGPASSPHRASE,   . - szPassPhrase

szNomFicPub:         .asciz "clepub.txt"    // fichier clé publique
szNomFicPrivee:      .asciz "clepriv.txt"   // fichier clé privée
.align 8
qlgPassPhrase:        .quad  LGPASSPHRASE
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
qLgBuffer:          .skip 8
qptClePrivee:       .skip 8
qptClePublique:     .skip 8
sBuffer:            .skip 10000
sBuffer1:            .skip 10000
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm
    bl afficherMessage

    ldr x0,qAdrqptClePrivee
    ldr x1,qAdrqptClePublique
    ldr x0,qAdrqptClePrivee
    bl lireClePrivee
    
    ldr x0,qAdrqptClePublique
    bl lireClePublique

100:                            // fin standard du programme
    ldr x0,qAdrszMessFinPgm     // message de fin
    bl afficherMessage
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdrqptClePrivee:        .quad qptClePrivee
qAdrqptClePublique:      .quad qptClePublique
qAdrszPassPhrase:        .quad szPassPhrase
qAdrsBuffer:             .quad sBuffer
qAdrsBuffer1:            .quad sBuffer1
qAdrqLgBuffer:           .quad qLgBuffer
/******************************************************************/
/*     lecture cle publique                                    */ 
/******************************************************************/
/* x0 contient ladresse du pointeur vers la clé publique */
lireClePublique:
    stp fp,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    mov x19,x0
    sub sp,sp,LGZONECLEPUB             // reserve place
    mov fp,sp
    mov x0,0
1:                             // boucle raz zone
    str xzr,[fp,x0,lsl 3]
    add x0,x0,1
    cmp x0,LGZONECLEPUB / 8
    blt 1b

                                // lire le fichier dans le buffer
    mov x0,AT_FDCWD             // valeur pour indiquer le répertoire courant
    ldr x1,qAdrszNomFicPub      // adresse nom du fichier
    mov x2,O_RDWR               // flags
    mov x3,0                    // 
    mov x8,OPEN                 // appel fonction systeme pour ouvrir le fichier
    svc 0 
    cmp x0,#0                    // si erreur retourne un nombre negatif
    ble 99f
    mov x22,x0                   // save du Fd

    mov x1,fp                   // buffer de lecture
    mov x2,LGZONECLEPUB         // et x2 contient la longueur à ecrire
    mov x8, #READ
    svc #0
    cmp x0,#0                   // si erreur retourne un nombre negatif
    blt 99f
    mov x0,x22                  // fermeture fichier de sortie Fd  fichier
    mov x8,CLOSE
    svc 0 
    cmp x0,0
    blt 99f
    
    bl BIO_s_mem                // init du bio
    bl BIO_new
    mov x21,x0
    mov x2,0
2:                              // boucle de calcul de la longueur du buffer
    ldrb w0,[fp,x2]
    add x1,x2,#1
    cmp w0,0
    csel x2,x1,x2,ne
    bne 2b
    
    mov x0,x21
    mov x1,fp                   // buffer et x2 contient la longueur
    bl BIO_write
    bl EVP_des_ede3_cbc
    mov x20,x0
    mov x0,x21
    mov x1,x19
    mov x2,0
    mov x3,0
    mov x4,0
    mov x5,0
    mov x6,0
    bl PEM_read_bio_PUBKEY
    cmp x0,0
    ble 99f
    afficherLib "Lecture clé publique OK."
    mov x0,0
    b 100f
99:
    adr x0,szMessErrEcr1
    bl afficherMessage
    mov x0,-1
100:
    add sp,sp,LGZONECLEPUB  
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp fp,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszNomFicPub:       .quad szNomFicPub
ficmask:               .quad O_CREAT|O_WRONLY
ficmask1:              .octa 0644
szMessErrEcr1:         .asciz "\033[31mErreur lecture cle publique\033[0m \n"
.align 4   
/******************************************************************/
/*     lecture clé privée                                    */ 
/******************************************************************/
/* x0 contient l'adresse du pointeur vers la clé privee */
lireClePrivee:
    stp fp,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    mov x19,x0
    sub sp,sp,LGZONECLEPRIV    // reserve place sur la pile
    mov fp,sp
    mov x0,0
1:                             // boucle raz zone
    str xzr,[fp,x0,lsl 3]
    add x0,x0,1
    cmp x0,LGZONECLEPRIV / 8
    blt 1b
                                // lire le fichier
    mov x0,AT_FDCWD             // valeur pour indiquer le répertoire courant
    ldr x1,qAdrszNomFicPrivee   // adresse nom du fichier
    mov x2,O_RDWR               // flags
    mov x3,0                    // permissions
    mov x8,OPEN
    svc 0 
    cmp x0,#0                    // si erreur retourne un nombre negatif
    ble 99f
    mov x22,x0                   // save du Fd
    mov x2,0
2:                              // boucle de calcul de la longueur 
    ldrb w0,[fp,x2]
    add x1,x2,#1
    cmp w0,0
    csel x2,x1,x2,ne
    bne 2b
    mov x0,x22
    mov x1,fp                   // buffer 
    mov x2,LGZONECLEPRIV        // et x2 contient la longueur à lire
    mov x8, #READ
    svc #0
    cmp x0,#0                   // si erreur retourne un nombre negatif
    blt 99f
    mov x0,x22                  // fermeture fichier de sortie Fd  fichier
    mov x8,CLOSE
    svc 0 
    cmp x0,0
    blt 99f
    bl BIO_s_mem                // initialisation du bio
    bl BIO_new
    mov x21,x0                  // save pointeur bio
    mov x2,0
2:                              // boucle de calcul de la longueur du buffer
    ldrb w0,[fp,x2]
    add x1,x2,#1
    cmp w0,0
    csel x2,x1,x2,ne
    bne 2b
    
    mov x0,x21
    mov x1,fp                   // buffer et x2 contient la longueur
    bl BIO_write                // ecriture du buffer dans la zone bio
    mov x0,x21
    mov x1,x19
    mov x2,0
    mov x3,0
    bl PEM_read_bio_PrivateKey  // lecture bio dans zone structure clé privée
    cmp x0,0
    ble 98f
    afficherLib "Lecture clé privée OK."
    mov x0,0
    b 100f
98:
    adr x0,szMessErrLect2
    bl afficherMessage
    mov x0,-1
    b 100f
99:
    adr x0,szMessErrLect1
    bl afficherMessage
    mov x0,-1
100:
    add sp,sp,LGZONECLEPRIV
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp fp,lr,[sp],16          // restaur des  2 registres
    ret
qAdrszNomFicPrivee:     .quad szNomFicPrivee
qAdrqlgPassPhrase:      .quad qlgPassPhrase
szMessErrLect1:         .asciz "\033[31mErreur lecture cle privee\033[0m \n"
szMessErrLect2:         .asciz "\033[31mLa phrase mot de passe est incorrecte!!!\033[0m \n"
.align 4         

