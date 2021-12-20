/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* exemple de verification de la signature d'un fichier avec  OPENSSL  64 bits  */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"
.equ LGBUFFER,   10000
.equ LGZONECLEPUB,      2000
.equ LGSIGNATURE, 256

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

szNomFicPub:          .asciz "clepub.txt"   // fichier clé publique

szNomFic:             .asciz "test1.txt"    // fichier à vérifier
szNomFicSign:         .asciz "test1Sig.txt" // fichier signature

.align 8

/*********************************/
/* UnInitialized data            */
/*********************************/
.bss  
qptClePublique:     .skip 8
qSignature:         .skip 8
sValSignature:      .skip LGSIGNATURE + 8
qLgSignature:       .skip 8
qAdrSignature:      .skip 8
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
    afficherLib "Vérification Signature Fichier"

    ldr x0,qAdrqptClePublique      // lecture et chargement clé publique
    bl lireClePublique
    ldr x0,qAdrqptClePublique
    
    ldr x0,qAdrszNomFic            // lecture du fichier à verifier
    ldr x1,qAdrsBuffer1
    mov x2,LGBUFFER
    bl lireFichier
    ldr x0,qAdrszNomFicSign        // lecture du fichier signature
    ldr x1,qAdrsValSignature
    mov x2,LGSIGNATURE
    bl lireFichier
    
    ldr x0,qAdrsValSignature       // adresse de la signature
    ldr x1,qAdrqAdrSignature       // adresse de la zone adresse
    str x0,[x1]                    // pour assurer le bon fonctionnement de la fonction suivante
    
    ldr x0,qAdrsBuffer1            // verification du fichier lu 
    ldr x1,qAdrqAdrSignature       // adresse zone contenant l'adresse de la signature
    mov x3,LGSIGNATURE             // longueur standard de la signature
    ldr x2,qAdrqLgSignature        // adresse zone de stockage de la  longueur
    str x3,[x2]
    ldr x3,qAdrqptClePublique      // adresse zone adresse cle privée
    bl verifierSignature

    
100:                               // fin standard du programme
    ldr x0,qAdrszMessFinPgm        // message de fin
    bl afficherMessage
    mov x0,0                       // code retour
    mov x8,EXIT                    // system call "Exit"
    svc #0

qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdrqptClePublique:      .quad qptClePublique
qAdrsBuffer:             .quad sBuffer
qAdrsBuffer1:            .quad sBuffer1
qAdrqSignature:          .quad qSignature
qAdrqLgSignature:        .quad qLgSignature
qAdrsValSignature:       .quad sValSignature
qAdrszNomFic:            .quad szNomFic
qAdrszNomFicSign:        .quad szNomFicSign
qAdrqAdrSignature:       .quad qAdrSignature
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
    strb wzr,[x19,x0]
    
    mov x0,x22                 // fermeture fichier de sortie Fd  fichier
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
    ldp x19,x20,[sp],16        // restaur des  2 registres
    ldp fp,lr,[sp],16          // restaur des  2 registres
    ret
szMessErrLectF:         .asciz "\033[31mErreur lecture fichier données\033[0m \n"
.align 4
/***************************************************/
/*   verifier la signature d'un message        */
/***************************************************/
/* x0 contient l'adresse du message  */
/* x1 contient l'adresse du pointeur de la signature */
/* x2 contient l'adresse de la longueur de la signature */
/* x3 contient l'adresse de la clé publique   */
verifierSignature:                // INFO: verifierSignature
    stp x1,lr,[sp,-16]!           // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    stp x21,x22,[sp,-16]!         // save  registres
    stp x23,x24,[sp,-16]!         // save  registres
    mov x19,x0
    mov x22,x3
    mov x23,x1
    mov x24,x2
    bl EVP_MD_CTX_new
    cbz x0,99f
    mov x20,x0                    // contexte
    ldr x0,qAdrszTypeSHA256
    bl EVP_get_digestbyname
    cbz x0,99f
    mov x21,x0                    // md ???
    mov x0,x20                    // contexte
    mov x1,x21                    // md
    mov x2,0
    bl EVP_DigestInit_ex
    cmp x0,1
    bne 99f
    mov x0,x20                    // contexte
    mov x1,0
    mov x2,x21                    // md
    mov x3,0
    ldr x4,[x22]                  // clé publique
    bl EVP_DigestVerifyInit
    cmp x0,1
    bne 99f
    mov x2,0                      // longueur message
2:                                // calcul longueur du message 
    ldrb w3,[x19,x2]
    cbz  w3,3f
    add x2,x2,1
    b 2b
3:
    mov x0,x20                    // contexte
    mov x1,x19                    // adresse message
    bl EVP_DigestUpdate
    cmp x0,1
    bne 99f
    bl ERR_clear_error            // nettoyage erreur
    mov x0,x20                    // contexte
    ldr x1,[x23]                  // pointeur signature
    ldr x2,[x24]                  // longueur signature
    bl EVP_DigestVerifyFinal
    //affregtit final 0
    cmp x0,1
    bne 99f
    afficherLib "Vérification OK"
    mov x0,x20                    // contexte
    cbz x0,100f
    bl EVP_MD_CTX_free
    mov x0,0
    b 100f
    
99:
    bl ERR_get_error
    affregtit erreur 0
    afficherLib "\033[31mErreur rencontrée dans verifierSignature\033[0m"
    mov x0,-1
100:
    ldp x23,x24,[sp],16           // restaur  registres
    ldp x21,x22,[sp],16           // restaur  registres
    ldp x19,x20,[sp],16           // restaur  registres
    ldp x1,lr,[sp],16             // restaur registres
    ret 
qAdrszTypeSHA256:       .quad szTypeSHA256

/******************************************************************/
/*     lecture cle publique                                    */ 
/******************************************************************/
/* x0 contient ladresse du pointeur vers la clé publique */
lireClePublique:               // INFO: lireClePublique
    stp fp,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    mov x19,x0
    sub sp,sp,LGZONECLEPUB     // reserve place sur la pile
    mov fp,sp
    mov x0,0
1:                             // boucle raz zone
    str xzr,[fp,x0,lsl 3]
    add x0,x0,1
    cmp x0,LGZONECLEPUB / 8
    blt 1b
                               // lire le fichier dans le buffer
    mov x0,AT_FDCWD            // valeur pour indiquer le répertoire courant
    ldr x1,qAdrszNomFicPub     // adresse nom du fichier
    mov x2,O_RDWR              // flags
    mov x3,0
    mov x8,OPEN                // appel fonction systeme pour ouvrir le fichier
    svc 0 
    cmp x0,#0                  // si erreur retourne un nombre negatif
    ble 99f
    mov x22,x0                 // save du Fd

    mov x1,fp                  // buffer sur la pile
    mov x2,LGZONECLEPUB        // x2 contient la longueur à ecrire
    mov x8, #READ
    svc #0
    cmp x0,#0                  // si erreur retourne un nombre negatif
    blt 99f
    mov x0,x22                 // fermeture fichier de sortie Fd  fichier
    mov x8,CLOSE
    svc 0 
    cmp x0,0
    blt 99f
    
    bl BIO_s_mem               // création structure BIO
    bl BIO_new
    mov x21,x0
    mov x2,0
2:                             // boucle de calcul de la longueur du buffer
    ldrb w0,[fp,x2]
    add x1,x2,#1
    cmp w0,0
    csel x2,x1,x2,ne
    bne 2b
    
    mov x0,x21                  // adresse structure bio
    mov x1,fp                   // buffer et x2 contient la longueur
    bl BIO_write                // ecriture du buffer dans la structure BIO
    mov x0,x21                  // adresse bio
    mov x1,x19                  // zone adresse de la clé publique
    mov x2,0
    mov x3,0
    mov x4,0
    mov x5,0
    mov x6,0
    bl PEM_read_bio_PUBKEY      // transfert zone bio dans zone clé openssl
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
szMessErrEcr1:         .asciz "\033[31mErreur lecture cle publique\033[0m \n"
.align 4   
