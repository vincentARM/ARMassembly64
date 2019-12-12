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

.equ O_CREAT,  0x0200          // create if nonexistant
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
szRetourligne: .asciz "\n"

//szParamNom: .asciz "~/asm64/projet64_4/fic1.txt"
szParamNom: .asciz "./fic1.txt"
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
                              //  ouverture fichier
    mov x0,AT_FDCWD           // valeur pour indiquer le répertoire courant
    ldr x1,qAdrszParamNom     // nom du fichier
    mov x2,#O_RDWR            // flags
    mov x3,#0                 // mode
    mov x8,#OPEN              // appel fonction systeme pour ouvrir
    svc 0                     //
    cmp x0,#0                 // si erreur
    ble erreur
    affregtit ouverture 0
    mov x28,x0                // save du File Descriptor
                              // lecture, x0 contient le FD du fichier
    ldr x1,=sBuffer           // adresse du buffer de reception
    mov x2,#TAILLEBUF         // nb de caracteres
    mov x8,#READ              // appel fonction systeme pour lire
    svc 0 
    cmp x0,#0
    ble erreur2
    ldr x0,=sBuffer           // affichage caractères lus
    affmemtit lecture x0 2
                              // fermeture fichier
    mov x0,x28                // Fd  fichier
    mov x8, #CLOSE            // appel fonction systeme pour fermer
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
100:                          // fin de programme standard
    mov x8,EXIT               // appel fonction systeme pour terminer
    svc #0
qAdrszParamNom:            .quad szParamNom
qAdrszMessErreur:          .quad szMessErreur
qAdrszMessErreur1:         .quad szMessErreur1
qAdrszMessErreur2:         .quad szMessErreur2
