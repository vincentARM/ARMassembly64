/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* lecture d'un fichier  */
/*******************************************/
/*         Constantes                      */
/*******************************************/
.include "../constantesARM64.inc"
.equ TAILLEBUF,  512  
.equ OPEN,  56
.equ CLOSE, 57
/*  fichier */
.equ O_RDONLY, 0
.equ O_WRONLY, 0x0001    
.equ O_RDWR,   0x0002          // open for reading and writing

.equ O_CREAT,  0x040          // create if nonexistant
.equ O_TRUNC,  0x0400          // truncate to zero length
.equ O_EXCL,   0x0800          // error if already exists 
.equ O_SYNC,   04010000        // valeur en octal à vérifier ????

.equ AT_FDCWD,    -100
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessErreur:  .asciz "Erreur ouverture fichier.\n"
szMessErreur1: .asciz "Erreur fermeture fichier.\n"
szMessErreur2: .asciz "Erreur lecture fichier.\n"
szMessErreur3: .asciz "Erreur changement répertoire.\n"
szRetourligne: .asciz "\n"

szNomRepert: .asciz "../projet64_3"    // pas de ~ ni de $HOME
szParamNom: .asciz "fic3.txt"
ficmask1: .octa 0644
sZoneEcrit:    .ascii "test ecriture données dans fichier"
.equ LGZONEECRIT,      . - sZoneEcrit
/*******************************************/
/* DONNEES NON INITIALISEES                */
/*******************************************/ 
.bss
sBuffer:  .skip TAILLEBUF 

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main                  // 'main' point d'entrée doit être  global

main:                         // programme principal
    ldr x0,qAdrszNomRepert      // repertoire
    mov x8,49              // appel fonction systeme changement de repertoire
    svc 0                     //
    cmp x0,0                 // si erreur
    blt erreur3
    affregtit repertoire 0

                              //  ouverture fichier
    mov x0,AT_FDCWD           // valeur pour indiquer le répertoire courant
    ldr x1,qAdrszParamNom     // nom du fichier
    mov x2,O_CREAT|O_WRONLY            //  flags
    ldr x3,oficmask1          // mode
    mov x8,#OPEN              // appel fonction systeme pour ouvrir
    svc 0                     //
    cmp x0,#0                 // si erreur
    ble erreur
    affregtit ouverture 0
    mov x28,x0                // save du File Descriptor
                              // x0 contient le FD du fichier
    ldr x1,qAdrsZoneEcrit     // adresse zone à écrire
    mov x2,#LGZONEECRIT       // nb de caracteres
    mov x8,WRITE              // appel fonction systeme
    svc 0 
    cmp x0,#0
    ble erreur2
    affregtit ecriture 0
                              // fermeture fichier
    mov x0,x28                // Fd  fichier
    mov x8,CLOSE            // appel fonction systeme pour fermer
    svc 0 
    cmp x0,0
    blt erreur1

    mov x0,#0                 // code retour OK
    b 100f
erreur:    
    ldr x1,qAdrszMessErreur   // x0 <- adresse chaine 
    bl   afficheErreur     
    mov x0,#1                 // erreur
    b 100f
erreur1:    
    ldr x1,qAdrszMessErreur1  // x0 <- adresse chaine 
    bl   afficheErreur 
    mov x0,#1                 // code retour erreur
    b 100f    
erreur2:    
    ldr x1,qAdrszMessErreur2  // x0 <- adresse chaine
    bl   afficheErreur 
    mov x0,#1                 // erreur
    b 100f
erreur3:    
    ldr x1,qAdrszMessErreur3  // erreur repertoire
    bl   afficheErreur 
    mov x0,#1                 // erreur
    b 100f
100:                          // fin de programme standard
    mov x8,EXIT               // appel fonction systeme pour terminer
    svc #0
qAdrszParamNom:            .quad szParamNom
qAdrszNomRepert:           .quad szNomRepert
qAdrszMessErreur:          .quad szMessErreur
qAdrszMessErreur1:         .quad szMessErreur1
qAdrszMessErreur2:         .quad szMessErreur2
qAdrszMessErreur3:         .quad szMessErreur3
qAdrficmask1:              .quad ficmask1
qAdrsZoneEcrit:            .quad sZoneEcrit
oficmask1:                 .quad 0644         // cette zone est en Octal (0 devant)
pourVerifLongueur:         .quad 0x12345678 
