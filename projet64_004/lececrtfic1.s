/* programme assembleur ARM  */
/* lecture d'un fichier et ecriture  */
/* eclatement lignes fichier */
/* recherche et stockage dans tas */
/* commentaire */
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM64.inc"
.equ TAILLEBUF,  1000
.equ TAILLETAS, 1000
.equ TAILLEZONES, 80
.equ OPEN,  56
.equ CLOSE, 57
/*  fichier */
.equ O_RDONLY, 0               // ouverture lecture seule
.equ O_WRONLY, 0x0001          // ouverture ecriture seule
.equ O_RDWR,   0x0002          // ecriture et lecture

.equ O_CREAT,  0x040           // create if nonexistant

.equ AT_FDCWD,    -100         // code répertoire courant
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessErreur: .asciz "Erreur ouverture fichier.\n"
szMessErreur1: .asciz "Erreur fermeture fichier.\n"
szMessErreur2: .asciz "Erreur lecture fichier.\n"
szMessErreur3: .asciz "Nom de fichier non renseigné dans ligne de commande.\n"
szMessErreur4: .asciz "Zone numerique du parametre trop petite.\n"
szMessErreur5: .asciz "Nom du fichier non renseigné dans fichier paramètre.\n"
szMessErreur6: .asciz "Erreur d'écriture dans fichier de sortie.\n"
szRetourligne: .asciz  "\n"


/* Table des mots cles autorisés */
.align 4
tabmotcle:
    .quad cle1   /* poste1 */
    .quad cle2   /* poste2 */
    .quad 0
tabtype:    
     .quad 1    /* alpha */
     .quad 0    /* numerique */
     .quad 0
tabval:    
     .quad 0
     .quad 0   
     .quad 0
cle1: .asciz "fichier"
cle2: .asciz "ligne"  
.align 4 
pttas:    .quad tas
ficmask:  .quad O_CREAT|O_WRONLY
ficmask1: .octa 0644
/*******************************************/
/* DONNEES NON INITIALISEES                */
/*******************************************/ 
.bss
.align 4
motcle:   .skip TAILLEZONES
valeur:   .skip TAILLEZONES
tas:      .skip TAILLETAS
sBuffer:  .skip TAILLEBUF 
sBufConv: .skip 30
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main         /* 'main' point d'entrée doit être  global */
main:                /* programme principal */
    mov fp,sp       // recup adresse pile  registre x29 fp
    ldr x4,[fp]     // recup nombre de paramètres et avance de 8 octets
    cmp x4,1
    ble erreur3      /* ligne de commande vide */ 
    add x5,fp,#16    /* recup adresse du deuxieme parametre */
    mov x0,AT_FDCWD  // valeur pour indiquer le répertoire courant
    ldr x1,[x5]      /* Donc le nom du fichier à ouvrir */
    mov x2,O_RDWR    /*  flags    */
    mov x3,0         /* mode */
    mov x8,OPEN      /* appel fonction systeme pour ouvrir */
    svc #0 
    cmp x0,#0        /* si erreur retourne -1 */
    ble erreur
    mov x28,x0          /* save du Fd */ 
                        /* lecture x0 contient le FD du fichier */
    ldr x1,qAdrsBuffer     /*  adresse du buffer de reception    */
    mov x2,#TAILLEBUF   /* nb de caracteres  */
    mov x8,#READ        /* appel fonction systeme pour lire */
    svc 0 
    cmp x0,#0
    ble erreur2
                        /* fermeture fichier paramètre */
    mov x0,x28          /* Fd  fichier */
    mov x8,CLOSE        /* appel fonction systeme pour fermer */
    svc 0 
    cmp x0,#0
    blt erreur1

    
    bl Balayage_lignes  /* analyse des lignes du fichier parametre */
    //ldr x0,qAdrtabmotcle
    //affmemtit affiche x0 3
                        /* ouverture du fichier de sortie */
    ldr x0,qAdrtabval
    ldr x0,[x0]
    cmp x0,#0
    beq erreur5
    mov x1,x0            /* adresse nom du fichier */
    mov x0,AT_FDCWD     // valeur pour indiquer le répertoire courant
    ldr x2,qAdrficmask  // flags
    ldr x2,[x2]
    ldr x3,qAdrficmask1 // permissions
    ldr x3,[x3]
    mov x8,OPEN      /* appel fonction systeme pour creer le fichier */
    svc 0 
    cmp x0,#0        /* si erreur retourne un nombre negatif */
    ble erreur
    mov x28,x0    /* save du Fd */ 
    /*reutilisation du buffer d'entree comme buffer de sortie */
    ldr x6,qAdrsBuffer
    mov x5,#1
    mov x2,#0   /* compteur de caractères à ecrire */
    ldr x3,qAdrtabval
    add x3,x3,#8    /* car valeur maxi dans Deuxieme poste */
    ldr x3,[x3]
1:                       /* debut de boucle de génération des lignes à ecrire */
    mov x0,x5           /* conversion N° vers ascii */
    ldr x1,qAdrsBufConv
    bl conversion10S
2:                    // boucle de recopie dans buffer de sortie
    ldrb w0,[x1],1
    cbz w0,3f
    strb w0,[x6],1
    add x2,x2,1
    b 2b
3:
    mov x4,#0xA      /* remplacer le 0 final par 0Ah  */
    str x4,[x6]      /* x6 contient l'adresse du caractère suivant le dernier caractère */
    add x6,x6,1      /* pour avancer à la position suivante */
    add x2,x2,1      // increment nombre de caractères à écrire
    add x5,x5,1
    cmp x5,x3        // compteur ?
    ble 1b           // non -> boucle
    mov x4,#0        // ecriture zero final
    str x4,[x6]
    /* ecriture buffer dans fichier de sortie */
    ldr x0,qAdrsBuffer
    affmemtit ecriture x0 4
    mov x0,x28                  /* Fd du fichier de sortie  */
    ldr x1,qAdrsBuffer          /* et x2 contient la longueur à ecrire */
    mov x8, #WRITE              /* select system call 'write' */
    svc #0                      /* perform the system call */
    cmp x0,#0                   /* si erreur retourne un nombre negatif */
    blt erreur6
    mov x0,x28                  /* fermeture fichier de sortie Fd  fichier */
    mov x8,CLOSE                /* appel fonction systeme pour fermer */
    svc 0 
    cmp x0,0
    blt erreur1

    mov x0,0                   /* code retour OK */
    b 100f
erreur:    
    ldr x1,qAdrszMessErreur   /* x0 <- code erreur x1 <- adresse chaine */
    bl   afficheErreur        /*appel procedure  */        
    mov x0,#1                 /* erreur */
    b 100f
erreur1:    
    ldr x1,qAdrszMessErreur1   /* x1 <- adresse chaine */
    bl   afficheErreur         /*appel procedure  */        
    mov x0,#1                  /* erreur */
    b 100f    
erreur2:    
    ldr x1,qAdrszMessErreur2   /* x1 <- adresse chaine */
    bl   afficheErreur         /*appel procedure  */        
    mov x0,#1                  /* erreur */
    b 100f    
erreur3:    
    ldr x1,qAdrszMessErreur3   /* x1 <- adresse chaine */
    bl   afficheErreur         /*appel procedure  */    
    mov x0,#1                  /* erreur */
    b 100f        
erreur5:    
    ldr x1,qAdrszMessErreur5   /* x1 <- adresse chaine */
    bl   afficheErreur         /*appel procedure  */        
    mov x0,#1                  /* erreur */
    b 100f        
erreur6:    
    ldr x1,qAdrszMessErreur6   /* x1 <- adresse chaine */
    bl   afficheErreur         /*appel procedure  */    
    mov x0,#1                  /* erreur */
    b 100f            

100:                           /* fin de programme standard  */
    mov x8, #EXIT              /* appel fonction systeme pour terminer */
    svc 0 
qAdrszMessErreur:         .quad szMessErreur
qAdrszMessErreur1:        .quad szMessErreur1
qAdrszMessErreur2:        .quad szMessErreur2
qAdrszMessErreur3:        .quad szMessErreur3
qAdrszMessErreur4:        .quad szMessErreur4
qAdrszMessErreur5:        .quad szMessErreur5
qAdrszMessErreur6:        .quad szMessErreur6
qAdrsBuffer:              .quad sBuffer
qAdrtabval:               .quad tabval
qAdrficmask:              .quad ficmask
qAdrficmask1:             .quad ficmask1
qAdrsBufConv:             .quad sBufConv
/*************************************/
/* Balayage des lignes lues          */
/*************************************/
Balayage_lignes:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    stp x4,x5,[sp,-16]!        // save  registres
    stp x0,x6,[sp,-16]!        // save  registres
    ldr x6,qAdrsBuffer  /* zone à analyser */
    ldr x5,qAdrmotcle  /* zone de reception des caractères extraits */
    mov x2,#0        /* indicateur de ligne complete cad mot cle + valeur */
1:
    /* caractere 00 trouvé  ==> fin */
    ldrb w0,[x6]
    cmp w0,#0
    beq Finboucle
    cmp w0,#0x0A        /* fin de ligne */
    bne 2f
    cmp x2,#0      /* ligne blanche ou incomplete */
    beq Finboucle
    mov x1,#0      /* ligne complete */  
    strb w1,[x5] /* pour fin de chaine dans zone valeur */
    bl TraitMotCle  /* traitement du mot clé trouvé */ 
    mov x2,#0   /* raz pour ligne suivante */
    ldr x5,qAdrmotcle
    b 4f
2:    
    /* caracteres inferieur à blanc à eliminer */
    cmp x0,#0x20
    ble 4f  
    cmp x0,#0x3D  /* caractère = trouvé */ 
    bne 3f
    mov x1,#0
    strb w1,[x5] /* pour fin de chaine */
    add x2,x2,#1
    ldr x5,qAdrvaleur
    b 4f
3:    
    strb w0,[x5] /* copie caractère dans zone receptrice */
    add x5,x5,#1
4:
    add x6,x6,#1
    b 1b         /* retour boucle */        
Finboucle:
    /* traitement ligne a faire si fin de fichier rencontre avant fin de ligne*/
    cmp x2,#0      /* ligne blanche ou incomplete ou deja traite */
    beq 100f
    mov x1,#0      /* ligne complete */  
    strb w1,[x5]    /* pour fin de chaine dans zone valeur */
    bl TraitMotCle  /* traitement du mot clé trouvé */ 
100:
    ldp x0,x6,[sp],16          // restaur des  2 registres
    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrmotcle:            .quad motcle
qAdrvaleur:            .quad valeur
/************************************/      
/* traitement du mot cle            */
/************************************/     
TraitMotCle :
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    stp x4,x5,[sp,-16]!        // save  registres
/* recherche mot cle dans la table */
    ldr x2,qAdrtabmotcle
    mov x5,#0  /* indice de recherche */
1:       /* debut de boucle */
   ldr x1,[x2, x5, LSL #3 ]  /* x1 <- x2 + (x5*4)  car table de pointeurs */
   cmp x1,#0      /* fin de table ? */
   beq 100f    /* mot cle inconnu   fin */
   ldr x0,qAdrmotcle   
   bl Comparaison  /* comparaison des 2 chaines dont les adresses sont dans x0 et x1 */
   cmp x0,#0   /* la comparaison retourne egal ? */
   beq 2f
   add x5,x5,#1  /* non donc on poursuit la recherche */
   b 1b
2:      /* mot cle trouvé avec l'indice x5 */
   ldr x1,qAdrtabtype  /* si trouvé recherche du type */
   add x1,x1,x5, LSL #3
   ldr x1,[x1]
   cmp x1,#1   /* type alphanumerique ? */
   beq 3f
   /* Type numerique : il faut effectuer la conversion chaine vers nombre */
   ldr x0,qAdrvaleur
   bl conversionAtoD
   ldr x2,qAdrtabval
   str x0,[x2,x5,LSL #3]  /* stockage resultat dans la table des valeurs */
   b  100f
   /* Type alphanumerique */
3: /* stockage de la chaine dans le tas */

   ldr x1,qAdrpttas
   ldr x1,[x1]   /* récupération du pointeur de début du tas */
   ldr x2,qAdrtabval
   str x1,[x2,x5,LSL #3] /* qui servira de début de pointeur de la chaine */
   bl stocktas    /* stockage de la chaine dans le tas */

 100:     /* fin de la procedure */
    ldr x0,qAdrtabval

    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrtabmotcle:            .quad tabmotcle
qAdrtabtype:              .quad tabtype
/************************************/      
/* comparaison de chaines           */
/************************************/     
/* x0 et x1 contiennent les adresses des chaines */
/* retour 0 dans x0 si egalite */
Comparaison :
    stp x1,lr,[sp,-16]!   // save  registres
    stp x2,x3,[sp,-16]!   // save  registres
1:    
    ldrb w3,[x0],1        /* octet chaine 1 */
    ldrb w2,[x1],1        /* octet chaine 2 */
    cmp w3,w2
    bne 2f                /* pas egaux */
    cbz w3,3f             /* 0 final c'est la fin */
    b 1b                  /* et boucle */
2:
    mov x0,#-1            /* inegalite */     
    b 100f
3:
    mov x0,#0             /* egalite */         
100:
    ldp x2,x3,[sp],16     // restaur des  2 registres
    ldp x1,lr,[sp],16     // restaur des  2 registres
    ret                   // retour adresse lr x30
/************************************/       
/* stockage de chaines dans le tas  */
/************************************/      
stocktas :
    stp x1,lr,[sp,-16]!   // save  registres
    stp x2,x3,[sp,-16]!   // save  registres
    ldr x1,qAdrpttas
    ldr x1,[x1]        /* recup du pointeur de fin du tas */
    ldr x3,qAdrvaleur  /* adresse de la chaine à stocker */  
    mov x2,#0          /* compteur de caractères */
1:                     /* debut de boucle de copie sur le tas */
    ldrb w0,[x3,x2]    /* lecture d'un octet */
    strb w0,[x1,x2]    /* stockage dans le tas */
    cmp w0,#0          /* fin de chaine */
    beq 2f
     add x2,x2,#1      /* comptage caractères stockés*/
    b 1b
2:
    add x1,x1,x2       /* ajout nombre de caracteres au debut du tas */
    ldr x2,qAdrpttas
    str x1,[x2]    /* maj du pointeur tas avec la prochaine adresse libre */    

100:
    ldp x2,x3,[sp],16     // restaur des  2 registres
    ldp x1,lr,[sp],16     // restaur des  2 registres
    ret
qAdrpttas:          .quad pttas

