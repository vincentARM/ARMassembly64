/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* génération des cles publique et privée avec OPENSSL  64 bits  */

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
szMessDebutPgm:       .asciz "Début programme.\n"
szMessFinPgm:         .asciz "Fin ok du programme.\n"
szRetourLigne:        .asciz "\n"

szTypeSHA256:        .asciz "SHA256"
szPassPhrase:        .asciz "replace_me"
.equ LGPASSPHRASE,   . - szPassPhrase
szNomFicPub:         .asciz "clepub.txt"
szNomFicPrivee:      .asciz "clepriv.txt"
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
//qZonesTest:         .skip 8 * 20
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
    afficherLib "Génération et sauvegarde des clés"

    ldr x0,qAdrqptClePrivee      // génération des clés
    ldr x1,qAdrqptClePublique
    bl genererCles
    ldr x0,qAdrqptClePrivee      // écriture clé privée
    bl ecrireClePrivee
    
    ldr x0,qAdrqptClePublique    // écriture clé publique
    bl ecrireClePublique

100:                             // fin standard du programme
    ldr x0,qAdrszMessFinPgm      // message de fin
    bl afficherMessage
    mov x0,0                     // code retour
    mov x8,EXIT                  // system call "Exit"
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
/*     sauvegarde clé publique                                    */ 
/******************************************************************/
/* x0 contient ladresse du pointeur vers la clé publique */
ecrireClePublique:
    stp fp,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    ldr x19,[x0]
    sub sp,sp,LGZONECLEPUB     // reserve place sur la pile
    mov fp,sp
    mov x0,0
1:                             // boucle raz zone
    str xzr,[fp,x0,lsl 3]
    add x0,x0,1
    cmp x0,LGZONECLEPUB / 8
    blt 1b

    bl EVP_des_ede3_cbc
    mov x20,x0
    bl BIO_s_mem              // init zones bio
    bl BIO_new
    mov x21,x0                // save pointeur bio
    mov x1,x19
    mov x2,x20
    mov x3,0
    mov x4,0
    mov x5,0
    mov x6,0
    bl PEM_write_bio_PUBKEY
    mov x0,x21                 // pointeur bio
    mov x1,fp                  // buffer reception
    mov x2,10000
    bl BIO_read

                                // ecrire le buffer dans le fichier 
    mov x0,AT_FDCWD             // valeur pour indiquer le répertoire courant
    ldr x1,qAdrszNomFicPub      // adresse nom du fichier
    ldr x2,ficmask              // flags
    ldr x3,ficmask1             // permissions
    mov x8,OPEN                 // appel fonction systeme pour creer le fichier
    svc 0 
    cmp x0,#0                   // si erreur retourne un nombre negatif
    ble 99f
    mov x22,x0                  // save du Fd
    mov x2,0
2:                              // boucle de calcul de la longueur 
    ldrb w0,[fp,x2]
    add x1,x2,#1
    cmp w0,0
    csel x2,x1,x2,ne
    bne 2b
    mov x0,x22
    mov x1,fp                   // buffer à écrire et x2 contient la longueur à ecrire
    mov x8, #WRITE
    svc #0
    cmp x0,#0                   // si erreur retourne un nombre negatif
    blt 99f
    mov x0,x22                  // fermeture fichier de sortie Fd  fichier
    mov x8,CLOSE
    svc 0 
    cmp x0,0
    blt 99f
    afficherLib  "Ecriture clé publique OK."
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
szMessErrEcr1:         .asciz "\033[31mErreur ecriture cle publique\033[0m \n"
.align 4   
/******************************************************************/
/*     sauvegarde cle privee                                    */ 
/******************************************************************/
/* x0 contient ladresse du pointeur vers la clé privee */
ecrireClePrivee:
    stp fp,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    ldr x19,[x0]
    sub sp,sp,LGZONECLEPRIV    // reserve place sur la pile
    mov fp,sp
    mov x0,0
1:                             // boucle raz zone
    str xzr,[fp,x0,lsl 3]
    add x0,x0,1
    cmp x0,LGZONECLEPRIV / 8
    blt 1b

    bl EVP_des_ede3_cbc
    mov x20,x0
    bl BIO_s_mem
    bl BIO_new
    mov x21,x0
    mov x1,x19
    mov x2,x20
    ldr x3,qAdrszPassPhrase
    mov x4,LGPASSPHRASE
    mov x5,0
    mov x6,0
    bl PEM_write_bio_PrivateKey
    mov x0,x21
    mov x1,fp
    mov x2,LGZONECLEPRIV
    bl BIO_read
                                // ecrire le buffer dans le fichier 
    mov x0,AT_FDCWD             // valeur pour indiquer le répertoire courant
    ldr x1,qAdrszNomFicPrivee   // adresse nom du fichier
    ldr x2,ficmask              // flags
    ldr x3,ficmask1             // permissions
    mov x8,OPEN                 // appel fonction systeme pour creer le fichier
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
    mov x1,fp          /* et x2 contient la longueur à ecrire */
    mov x8, #WRITE              /* select system call 'write' */
    svc #0                      /* perform the system call */
    cmp x0,#0                   /* si erreur retourne un nombre negatif */
    blt 99f
    mov x0,x22                  /* fermeture fichier de sortie Fd  fichier */
    mov x8,CLOSE                /* appel fonction systeme pour fermer */
    svc 0 
    cmp x0,0
    blt 99f
    afficherLib  "Ecriture clé privée OK."
    mov x0,0
    b 100f
99:
    adr x0,szMessErrEcr2
    bl afficherMessage
    mov x0,-1
100:
    add sp,sp,LGZONECLEPRIV
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp fp,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszNomFicPrivee:    .quad szNomFicPrivee
szMessErrEcr2:         .asciz "\033[31mErreur ecriture cle privee\033[0m \n"
.align 4         
/***************************************************/
/*   génération des cles privées et publiques       */
/***************************************************/
/* x0 contient l'adresse du pointeur de la clé privée */
/* x1 contient l'adresse du pointeur de la clé publique */
genererCles:                     // INFO: genererCles
    stp fp,lr,[sp,-16]!          // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    sub sp,sp,16                  // place pour pointeur rsa
    mov fp,sp
    
    mov x19,x0       // initialisation clé privée
    ldr x0,[x19]
    cbz x0,1f
    bl EVP_PKEY_free
1:
    mov x20,x1       // initialisation clé publique
    ldr x0,[x20]
    cbz x0,2f
    bl EVP_PKEY_free
2:
    str xzr,[fp]        // init pointeur RSA
    
    bl  EVP_PKEY_new
    str x0,[x19]
    bl  EVP_PKEY_new
    str x0,[x20]
    mov x0,2048
    ldr x1,qRSA_F4
    mov x2,0
    mov x3,0
    bl  RSA_generate_key
    cbz x0,99f
    str x0,[fp]
    bl RSAPrivateKey_dup
    mov x2,x0
    mov x1,6
    ldr x0,[x19]
    bl EVP_PKEY_assign
    cmp x0,1
    bne 99f
                           // clé publique
    ldr x0,[fp]            // rsa
    bl RSAPublicKey_dup
    mov x2,x0
    mov x1,6
    ldr x0,[x20]
    bl EVP_PKEY_assign
    cmp x0,1
    bne 99f
    afficherLib "Génération des clés OK."
    ldr x0,[fp]           // raz rsa
    bl RSA_free
    mov x0,0
    b 100f
99:
    bl ERR_get_error
    affregtit erreur 0
    afficherLib "\033[31mErreur rencontrée dans genererCles\033[0m"
    mov x0,-1
100:
    add sp,sp,16
    ldp x19,x20,[sp],16         // restaur  registres
    ldp fp,lr,[sp],16           // restaur registres
    ret
qAdrszTypeSHA256:        .quad szTypeSHA256
qRSA_F4:                 .quad RSA_F4
