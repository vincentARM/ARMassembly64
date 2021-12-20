/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* exemple de signature d'un fichier avec  OPENSSL  64 bits  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"
.equ LGBUFFER,        10000
.equ LGZONECLEPRIV,   4096 - 16
.equ LGSIGNATURE,     256

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

szNomFicPrivee:       .asciz "clepriv.txt"      // fichier clé privée

szNomFic:             .asciz "test1.txt"        // fichier à signer
szNomFicSign:         .asciz "test1Sig.txt"     // fichier signature

.align 8

/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
qptClePrivee:       .skip 8
qSignature:         .skip 8
qLgSignature:       .skip 8
sBuffer:            .skip LGBUFFER
sBuffer1:           .skip LGBUFFER
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:
    ldr x0,qAdrszMessDebutPgm
    bl afficherMessage
    afficherLib "Signature Fichier"

    ldr x0,qAdrqptClePrivee      // lecture et chargement clé privée
    bl lireClePrivee
    
    ldr x0,qAdrszNomFic          // lecture du fichier à signer
    ldr x1,qAdrsBuffer1
    bl lireFichier
    
    ldr x0,qAdrsBuffer1          // signature du fichier
    affmemtit buffer x0 4
    ldr x1,qAdrqSignature        // adresse zone de reception de l'adresse de la signature
    ldr x2,qAdrqLgSignature      // adresse zone reception longueur
    ldr x3,qAdrqptClePrivee      // adresse zone adresse cle privée
    bl signerMessage
    
    ldr x0,qAdrszNomFicSign      // écriture de la signature
    ldr x1,qAdrqSignature
    ldr x1,[x1]
    ldr x2,qAdrqLgSignature
    bl ecrireSignature
    
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
qAdrqSignature:          .quad qSignature
qAdrqLgSignature:        .quad qLgSignature
qAdrszNomFic:            .quad szNomFic
qAdrszNomFicSign:        .quad szNomFicSign
/******************************************************************/
/*     lecture du fichier à signer                                    */ 
/******************************************************************/
/* x0 contient ladresse du nom du fichier */
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
    mov x3,0                   // 
    mov x8,OPEN                // appel fonction systeme pour ouvrir le fichier
    svc 0 
    cmp x0,#0                  // si erreur retourne un nombre negatif
    ble 99f
    mov x22,x0                 // save du Fd

    mov x1,x19                 // adresse buffer de lecture
    mov x2,x20                 // x2 contient la longueur à lire
    mov x8, #READ
    svc #0
    cmp x0,#0                  // si erreur retourne un nombre negatif
    blt 99f
    strb wzr,[x19,x0]
    
    mov x0,x22                  // fermeture fichier de sortie Fd  fichier
    mov x8,CLOSE
    svc 0 
    cmp x0,0
    blt 99f
    mov x0,0
    bl 100f
99:
    adr x0,szMessErrLectF
    bl afficherMessage
    mov x0,-1
100:
    ldp x19,x20,[sp],16          // restaur des  2 registres
    ldp fp,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
szMessErrLectF:         .asciz "\033[31mErreur lecture fichier données\033[0m \n"
.align 4
/******************************************************************/
/*     ecriture du fichier contenant la signature                 */ 
/******************************************************************/
/* x0 contient ladresse du nom du fichier */
/* x1 contient l'adresse du buffer à écrire */
/* x2 contient la longueur du buffer */
ecrireSignature:               // INFO: lireFichier
    stp fp,lr,[sp,-16]!        // save  registres
    stp x19,x20,[sp,-16]!      // save  registres
    mov x19,x1
    mov x20,x2
    mov x1,x0                  // adresse nom du fichier
    
                               // ecrire le buffer dans le fichier 
    mov x0,AT_FDCWD            // valeur pour indiquer le répertoire courant
    ldr x2,ficmask             // flags
    ldr x3,ficmask1            // permissions
    mov x8,OPEN                // appel fonction systeme pour creer le fichier
    svc 0 
    cmp x0,#0                  // si erreur retourne un nombre negatif
    ble 99f
    mov x22,x0
    mov x1,x19                 // adresse buffer à écrire
    mov x2,x20                 // et x2 contient la longueur à ecrire
    mov x8, #WRITE
    svc #0
    cmp x0,#0                   // si erreur retourne un nombre negatif
    blt 99f
    mov x0,x22                  // fermeture fichier de sortie Fd  fichier
    mov x8,CLOSE
    svc 0 
    cmp x0,0
    blt 99f
    mov x0,0
    b 100f
99:
    adr x0,szMessErrEcrS
    bl afficherMessage
    mov x0,-1  
    
100:
    ldp x19,x20,[sp],16          // restaur des  2 registres
    ldp fp,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
ficmask:               .quad O_CREAT|O_WRONLY
ficmask1:              .octa 0644
szMessErrEcrS:         .asciz "\033[31mErreur ecriture fichier signature\033[0m \n"
.align 4
/***************************************************/
/*   signature d'un message       */
/***************************************************/
/* x0 contient l'adresse du message  */
/* x1 contient l'adresse du pointeur de la signature */
/* x2 contient l'adresse de la taille de la signature */
/* x3 contient l'adresse de la clé privée   */
signerMessage:               // INFO: signerMessage
    stp fp,lr,[sp,-16]!      // save  registres
    stp x19,x20,[sp,-16]!    // save  registres
    stp x21,x22,[sp,-16]!    // save  registres
    stp x22,x24,[sp,-16]!    // save  registres
    sub sp,sp,16             // reserve place sur la pile
    mov fp,sp
    mov x19,x0               // adresse message
    mov x23,x1               // pointeur signature
    mov x24,x2               // adresse longueur signature 
    mov x22,x3               // adresse clé privée 
    ldr x0,[x1]
    cbz x0,1f
    mov x1,4
    mov x2,113
    bl  CRYPTO_free
1:
    bl EVP_MD_CTX_new
    cbz x0,99f
    mov x20,x0               // contexte
    
    ldr x0,qAdrszTypeSHA256
    bl EVP_get_digestbyname
    cbz x0,99f
    mov x21,x0               //md ???
    mov x0,x20               // contexte
    mov x1,x21               // md
    mov x2,0
    bl EVP_DigestInit_ex
    cmp x0,1
    bne 99f
    mov x0,x20               // contexte
    mov x1,0
    mov x2,x21               // md
    mov x3,0
    ldr x22,[x22]
    mov x4,x22               // clé privée
    bl EVP_DigestSignInit
    cmp x0,1
    bne 99f
    mov x2,0                 // longueur message
2:                           // calcul longueur du message 
    ldrb w3,[x19,x2]
    cbz  w3,3f
    add x2,x2,1
    b 2b
3:
    mov x0,x20               // contexte
    mov x1,x19               // adresse message
    bl EVP_DigestUpdate
    cmp x0,1
    bne 99f
    mov x0,x20               // contexte
    mov x1,0
    str xzr,[x24]            // raz taille
    mov x2,x24               // et adresse passée à la fonction
    bl EVP_DigestSignFinal
    cmp x0,1
    bne 99f
    ldr x0,[x24]               
    cbnz x0,4f
    afficherLib "\033[31mSignature NON OK !!!"
    mov x0,-1
    b 100f
4:
    //affregtit etiq4 0
    str x0,[fp]               // stocke la taille de la signature sur la pile
    mov x2,171
    mov x1,10                 // TODO: à revoir
    bl CRYPTO_malloc
    cbz x0,99f
    //affregtit final 0
    str x0,[x23]              // stocke adresse de la signature dans zone retour
    mov x1,x0                 // signature
    mov x0,x20                // contexte
    mov x2,fp                 // longueur
    bl EVP_DigestSignFinal
    cmp x0,1
    bne 99f
    
    ldr x0,[fp]
    ldr x1,[x24]
    cmp x0,x1
    beq 5f
    affregtit "\033[31mErreur longueur différente\033[0m " 0
    mov x0,-1
    b 100f
5:
    afficherLib "signature OK" 0
    mov x0,x20            // contexte
    cbz x0,100f
    bl EVP_MD_CTX_free
    
    mov x0,0
    b 100f
99:
    bl ERR_get_error
    affregtit erreur 0
    afficherLib "\033[31mErreur rencontrée dans signerMessage\033[0m"
    mov x0,-1
100:
    add sp,sp,16
    ldp x22,x24,[sp],16           // restaur  registres
    ldp x21,x22,[sp],16           // restaur  registres
    ldp x19,x20,[sp],16           // restaur  registres
    ldp fp,lr,[sp],16             // restaur registres
    ret
qAdrszTypeSHA256:       .quad szTypeSHA256

/******************************************************************/
/*     lecture cle privee                                    */ 
/******************************************************************/
/* x0 contient ladresse du pointeur vers la clé privee */
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
    mov x1,fp                   // zone reception
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
szMessErrLect1:         .asciz "\033[31mErreur lecture cle privee\033[0m \n"
szMessErrLect2:         .asciz "\033[31mLa phrase mot de passe est incorrecte!!!\033[0m \n"
.align 4         
