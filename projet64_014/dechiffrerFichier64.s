/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* exemple de déchiffrement d'un fichier avec  OPENSSL  64 bits  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"
.equ LGBUFFER,   10000
.equ LGZONECLEPRIV,   4096 - 16
.equ LGCLEPROV, 256

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

szTypeSHA256:         .asciz "SHA256"

szNomFicPrivee:        .asciz "clepriv.txt"      // fichier clé privée

szNomFic:             .asciz "test1dech.txt"     // fichier résultat
szNomFicChiffre:      .asciz "test1Chif.txt"     // fichier chiffré
szNomFicCle:          .asciz "test1cle.txt"      // contient la longueur et la clé
                                                 // et la longueur et la valeur de IV
.align 8

/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
qptClePrivee:       .skip 8
sCleProvisoire:     .skip LGCLEPROV + 8
qLgCleProvisoire:   .skip 8
qLgBuffer:          .skip 8
qLgIV:              .skip 8
sBuffer:            .skip LGBUFFER
sBuffer1:           .skip LGBUFFER
stIV:               .skip LGBUFFER         // TODO: à ajuster
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main: 
    ldr x0,qAdrszMessDebutPgm
    bl afficherMessage
    afficherLib "Déchiffrement Fichier"

    ldr x0,qAdrqptClePrivee      // lecture et chargement clé privee
    bl lireClePrivee
    cmp x0,-1
    beq 100f
    
    ldr x0,qAdrszNomFicChiffre   // lecture du fichier à déchiffrer
    ldr x1,qAdrsBuffer
    mov x2,LGBUFFER              // taille du buffer
    bl lireFichier
    cmp x0,-1
    beq 100f
    mov x20,x0                    // longueur texte lu
    
    ldr x0,qAdrszNomFicCle        // lecture du fichier de la clé 
    ldr x1,qAdrsCleProvisoire     // clé provisoire
    ldr x2,qAdrqLgCleProvisoire
    bl lireFichierCle
    cmp x0,-1
    beq 100f
    
    ldr x0,qAdrsBuffer           // verification du fichier lu 
    ldr x1,qAdrqptClePrivee      // adresse zone adresse cle privée
    ldr x2,qAdrsBuffer1          // buffer texte en clair
    ldr x3,qAdrqLgBuffer         // longueur texte clair
    mov x4,x20                   // longueur texte lu
    bl dechiffrerChaine
    mov x19,x0                   // longueur du texte dechiffré
    ldr x0,qAdrsBuffer1 
    affmemtit bufferchiffre  x0 5
    
    ldr x0,qAdrszNomFic          // écriture du résultat
    ldr x1,qAdrsBuffer1 
    mov x2,x19                  // longueur
    bl ecrireFichier
    
    
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
qAdrsBuffer:             .quad sBuffer
qAdrsBuffer1:            .quad sBuffer1
qAdrszNomFic:            .quad szNomFic
qAdrszNomFicChiffre:     .quad szNomFicChiffre
qAdrqLgBuffer:           .quad qLgBuffer
qAdrszNomFicCle:         .quad szNomFicCle
/******************************************************************/
/*     lecture de fichier                                     */ 
/******************************************************************/
/* x0 contient l'adresse du nom du fichier */
/* x1 contient l'adresse du buffer de lecture */
/* x2 contient la longueur du buffer */
lireFichier:                   // INFO: lireFichier
    stp fp,lr,[sp,-16]!        // save  registres
    stp x19,x20,[sp,-16]!      // save  registres
    mov x19,x1
    mov x20,x2
    mov x1,x0                  // adresse nom du fichier
                               // lire le fichier dans le buffer
    mov x0,AT_FDCWD            // valeur pour indiquer le répertoire courant
    mov x2,O_RDWR              // flags
    mov x3,0
    mov x8,OPEN                // appel fonction systeme pour ouvrir le fichier
    svc 0 
    cmp x0,#0                  // si erreur retourne un nombre negatif
    ble 99f
    mov x22,x0                 // save du Fd

    mov x1,x19                 // buffer
    mov x2,x20                 // x2 contient la longueur à lire
    mov x8, #READ
    svc #0
    cmp x0,#0                  // si erreur retourne un nombre negatif
    blt 99f
    mov x20,x0                 // récup de la longueur lue
    
    mov x0,x22                 // fermeture fichier de sortie Fd  fichier
    mov x8,CLOSE
    svc 0 
    cmp x0,0
    blt 99f
    mov x0,x20                 // retourne longueur
    bl 100f
99:
    adr x0,szMessErrLectF
    bl afficherMessage
    mov x0,-1
100:
    ldp x19,x20,[sp],16        // restaur des  2 registres
    ldp fp,lr,[sp],16          // restaur des  2 registres
    ret
szMessErrLectF:         .asciz "\033[31mErreur lecture fichier données\033[0m \n"
.align 4
/******************************************************************/
/*     lecture du fichier contenant la longueur et la valeur de la clé  */ 
/******************************************************************/
/* x0 contient l'adresse du nom du fichier */
/* x1 contient l'adresse de la clé */
/* x2 contient l'adresse de la longueur de la clé */
lireFichierCle:                   // INFO: lireFichier
    stp fp,lr,[sp,-16]!        // save  registres
    stp x19,x20,[sp,-16]!      // save  registres
    mov x19,x1
    mov x20,x2
    mov x1,x0                  // adresse nom du fichier
                               // lire le fichier dans le buffer
    mov x0,AT_FDCWD            // valeur pour indiquer le répertoire courant
    mov x2,O_RDWR              // flags
    mov x3,0
    mov x8,OPEN                // appel fonction systeme pour ouvrir le fichier
    svc 0 
    cmp x0,#0                  // si erreur retourne un nombre negatif
    ble 99f
    mov x22,x0                 // save du Fd

    mov x1,x20                 // adresse de la longueur
    mov x2,8                   // x2 contient la longueur à lire
    mov x8, #READ
    svc #0
    cmp x0,#0                  // si erreur retourne un nombre negatif
    blt 99f
    
    mov x0,x22                 // FD
    mov x1,x19                 // adresse de la clé
    ldr x2,[x20]               // récup de la longueur lue lors du premier read
    mov x8, #READ
    svc #0
    cmp x0,#0                  // si erreur retourne un nombre negatif
    blt 99f
    
    mov x0,x22                 // FD
    ldr x1,qAdrqLgIV           // adresse de la longueur de IV
    mov x2,8                   // x2 contient la longueur à lire
    mov x8, #READ
    svc #0
    cmp x0,#0                  // si erreur retourne un nombre negatif
    blt 99f
    
    mov x0,x22                 // FD
    ldr x1,qAdrstIV            // adresse de la structure IV
    ldr x2,qAdrqLgIV           // adresse de la longueur de IV
    ldr x2,[x2]               // récup de la longueur lue lors du 3ième read
    mov x8, #READ
    svc #0
    cmp x0,#0                  // si erreur retourne un nombre negatif
    blt 99f
    
    mov x0,x22                 // fermeture fichier de sortie Fd  fichier
    mov x8,CLOSE
    svc 0 
    cmp x0,0
    blt 99f
    mov x0,0
    bl 100f
99:
    adr x0,szMessErrLectF1
    bl afficherMessage
    mov x0,-1
100:
    ldp x19,x20,[sp],16        // restaur des  2 registres
    ldp fp,lr,[sp],16          // restaur des  2 registres
    ret
qAdrqLgIV:         .quad qLgIV
szMessErrLectF1:   .asciz "\033[31mErreur lecture fichier de la clé\033[0m \n"
.align 4
/***************************************************/
/*   dechiffrer une chaine chiffrée        */
/***************************************************/
/* x0 contient l'adresse du buffer  */
/* x1 contient l'adresse de la cle privée */
/* x2 contient l'adresse du buffer de reception */
/* x3 contient l'adresse zone reception de la longueur du texte déchiffré */
/* x4 contient la longueur du texte chiffré */
dechiffrerChaine:                 // INFO: dechiffrerChaine
    stp x25,lr,[sp,-16]!          // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    stp x21,x22,[sp,-16]!         // save  registres
    stp x23,x24,[sp,-16]!         // save  registres
    mov x19,x0
    mov x22,x1
    mov x23,x2
    mov x24,x3
    mov x25,x4                    // longueur du texte lu
    bl EVP_CIPHER_CTX_new         // création du contexte
    cbz x0,99f
    mov x20,x0                    // contexte
    bl EVP_aes_256_cbc
    mov x21,x0
    mov x0,x20                    // contexte
    mov x1,x21                    // resultat fct précédente
    ldr x2,qAdrsCleProvisoire     // clé provisoire lue dans le fichier de clé
    ldr x3,qAdrqLgCleProvisoire   // adresse longueur clé 
    ldr x3,[x3]                   // récup valeur
    ldr x4,qAdrstIV               // adresse IV lue dans le fichier de clé
    ldr x5,[x22]                  // clé privée
    bl EVP_OpenInit
    cmp x0,1
    bne 99f

    mov x0,x20                    // contexte
    mov x1,x23                    // zone reception
    mov x2,x24                    // zone reception longueur
    mov x3,x19                    // adresse chaine et x4 contient la longueur
    mov x4,x25 
    bl EVP_DecryptUpdate
    cmp x0,1
    bne 99f
    
    ldr x25,[x24]                 // recup longueur
    
    mov x0,x20                    // contexte
    add x1,x23,x25                // fin du texte crypté
    mov x2,x24                    
    bl EVP_OpenFinal
    cmp x0,1
    bne 99f
    afficherLib "Déchiffrage OK"
    ldr x21,[x24]         // recup longueur
    add x21,x21,x25
    mov x0,x20                    // contexte
    bl EVP_CIPHER_CTX_free
    mov x0,x21                    // retourne la longueur finale
    b 100f
    
99:
    bl ERR_get_error
    affregtit erreur 0
    afficherLib "\033[31mErreur rencontrée dans dechiffrerChaine\033[0m"
    mov x0,-1
100:
    ldp x23,x24,[sp],16           // restaur  registres
    ldp x21,x22,[sp],16           // restaur  registres
    ldp x19,x20,[sp],16           // restaur  registres
    ldp x25,lr,[sp],16             // restaur registres
    ret 
//qAdrszTypeSHA256:       .quad szTypeSHA256
qAdrsCleProvisoire:     .quad sCleProvisoire
qAdrsCleProvisoire1:    .quad qAdrsCleProvisoire
qAdrqLgCleProvisoire:   .quad qLgCleProvisoire
qAdrstIV:               .quad stIV
/******************************************************************/
/*     lecture cle privee                                    */ 
/******************************************************************/
/* x0 contient ladresse du pointeur vers la clé privee */
lireClePrivee:
    stp fp,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    mov x19,x0
    sub sp,sp,LGZONECLEPRIV    // reserve place
    mov fp,sp
    mov x0,0
1:                             // boucle raz zone
    str xzr,[fp,x0,lsl 3]
    add x0,x0,1
    cmp x0,LGZONECLEPRIV / 8
    blt 1b
                                // ecrire le buffer dans le fichier 
    mov x0,AT_FDCWD             // valeur pour indiquer le répertoire courant
    ldr x1,qAdrszNomFicPrivee   // adresse nom du fichier
    mov x2,O_RDWR               // flags
    mov x3,0                    // permissions
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
    mov x1,fp                   // et x2 contient la longueur à ecrire
    mov x2,LGZONECLEPRIV
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
    
    mov x0,0                   // récup ok
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
szMessErrLect1:         .asciz "\033[31mErreur lecture cle privee\033[0m \n"
szMessErrLect2:         .asciz "\033[31mLa phrase mot de passe est incorrecte!!!\033[0m \n"
.align 4     

/******************************************************************/
/*     ecriture fichier                                           */ 
/******************************************************************/
/* x0 contient l'adresse du nom du fichier */
/* x1 contient l'adresse du buffer */
/* x2 contient la longueur à écrire */
ecrireFichier:               // INFO: ecrireFichier
    stp x21,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    stp x19,x20,[sp,-16]!       // save  registres
    mov x19,x1
    mov x20,x2
    mov x1,x0
                                // ecrire le buffer dans le fichier 
    mov x0,AT_FDCWD             // valeur pour indiquer le répertoire courant
    ldr x2,ficmask              // flags
    ldr x3,ficmask1             // permissions
    mov x8,OPEN                 // appel fonction systeme pour creer le fichier
    svc 0 
    cmp x0,#0                    // si erreur retourne un nombre negatif
    ble 99f
    mov x21,x0                   // save du Fd

    mov x1,x19                   // adresse du buffer
    mov x2,x20                   // x2 contient la longueur à ecrire
    mov x8, #WRITE
    svc #0
    cmp x0,#0                    // si erreur retourne un nombre negatif
    blt 99f
    mov x0,x21                   // fermeture fichier de sortie Fd  fichier
    mov x8,CLOSE
    svc 0 
    cmp x0,0
    blt 99f
    mov x0,0
    b 100f
99:
    adr x0,szMessErrEcr1
    bl afficherMessage
    mov x0,-1
100:
    ldp x19,x20,[sp],16          // restaur des  2 registres
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x21,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
ficmask:               .quad O_CREAT|O_WRONLY
ficmask1:              .octa 0644
szMessErrEcr1:         .asciz "\033[31mErreur écriture fichier chiffré!!\033[0m \n"
.align 4 
