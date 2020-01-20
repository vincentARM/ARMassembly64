/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* Recherche IP d'un site web acces et extraction données */

/************************************/
/* Constantes                       */
/************************************/
.equ DUP2,   0x3F                // Linux syscall
.equ WAIT4,  0x72                // Linux syscall
.equ SIGCHLD,  17
.equ WUNTRACED,   2
.equ TAILLEBUFFER,  500

.equ INVALID_SOCKET,   -1
.equ AF_INET,           2        // Internet IP Protocol

.equ SOCK_STREAM,       1        // stream (connection) socket
.equ SOCK_DGRAM,        2        // datagram (conn.less) socket
.equ SOCK_RAW,          3        // raw socket
.equ SOCK_RDM,          4        // reliably-delivered message
.equ SOCK_SEQPACKET,    5        // sequential packet socket
.equ SOCK_PACKET,       10       // linux specific way of

.equ LGBUFFERPAGE,      64000
/*******************************************/
/* Structures                             */
/********************************************/
/* définition structure de type sockaddr_in */
    .struct  0
sin_family:              // famille : AF_INET
    .struct  sin_family + 2 
sin_port:                // le numéro de port
   .struct  sin_port + 2 
sin_addr:                // l'adresse internet
    .struct  sin_addr + 4 
sin_zero:                // un champ de 8 zéros
    .struct  sin_zero + 8
sin_fin:
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*********************************/
/* DONNEES INITIALISEES          */
/*********************************/
.data
szMessDebutPgm:       .asciz "Début du programme. \n"
szRetourLigne:        .asciz "\n"
szMessFinOK:          .asciz "Fin normale du programme. \n"
szMessErreur:         .asciz "Erreur  !!!"
//szCommand:            .ascii "ping "     // commande linux host
szCommande:           .asciz "/bin/sh"
szCommandeCpl:         .asciz "-c"
szCommandeArg:        .ascii "ping "
szNomSite :           .ascii "www.meteofrance.com "  // nom du site à rechercher
                      .asciz " -c 1 "
szlibAdrIP:           .asciz " ("
szlibDebMeteo:        .asciz "</span> </div> </div> </li> </ul> <p>"
.equ LGSZLIBDEBMETEO,   . - szlibDebMeteo
szlibFinMeteo:        .asciz "</p> </div> </article>"
szlibBR:              .asciz "<br/>"
szRequete1:           .asciz "GET /previsions-meteo-france/bulletin-france HTTP/1.1 \r\nHost: www.meteofrance.com\r\n\r\n"
.align 4
stArg1:               .quad szCommande            // adresse de la commande
                      .quad szCommandeCpl
                      .quad szCommandeArg             // adresse de l'argument
                      .quad 0,0                   // zeros

/*********************************/
/* DONNEES NON INITIALISEES      */
/*********************************/
.bss  
sIP:                  .skip 20
.align 4
qStatusThread:        .skip 8
pipefd:               .skip 16
stSocket1:            .skip sin_fin
sBuffer:              .skip TAILLEBUFFER
stRusage:             .skip TAILLEBUFFER
sBufferPage:          .skip LGBUFFERPAGE
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                                           // programme principal 
    ldr x0,qAdrszMessDebutPgm                   // x0 <- adresse message debut 
    bl affichageMess                            // affichage message dans console  
    /* création pipe  */
    ldr x0,qAdrpipefd                           //  adresse FDs
    mov x8,59                                   // creation pipe
    svc 0                                       // call system Linux
    cmp x0,#0                                   // erreur  ?
    blt 99f
    affregtit deb 0
    //ldr x0,qAdrpipefd                           //  adresse FDs
    //affmemtit adrpipe x0 2

    /* création thread fils */
    ldr x0,qFlags
    mov x1,0
    mov x2,0
    mov x3,0
    mov x4,0
    mov x5,0
    mov x8,220                                  // call system clone (fork ?)
    svc #0 
    cmp x0,#0                                   // erreur ?
    blt 99f
    bne parent                                  // if <> zero x0 contient le pid du parent
                                                // sinon c'est le fils
/****************************************/
/*  Thread  du fils                     */
/****************************************/
    /* redirection sysout -> pipe */ 
    ldr x0,qAdrpipefd
    ldr x0,[x0,#4]                               // recup FD du pipe
    mov x8,24                                    // call system linux dup3
    mov x1, #STDOUT                              // FD console SYSOUT
    svc #0
    cmp x0,#0                                    // erreur ?
    blt 99f

    /* run commande linux       */
    ldr x0,qAdrszCommande                        // adresse /bin/sh 
    ldr x1,qAdrstArg1                            // adresse commande à executer
    mov x2,xzr                                   // env = null
    mov x8,221                                   // call system linux (execve)
    svc #0                                       // si ok -> fin du thread sans retour !!!
    b 100f                                       // cette instruction n'est jamais execut�e
/****************************************/
/*  Thread parent                       */
/****************************************/
parent:
    mov x19,x0                                    // save pid du fils
1:                                                // boucle attente signal du fils
    mov x0,x19
    ldr x1,qAdriStatusThread                      // status du thread
    mov x2,#WUNTRACED                             // flags 
    ldr x3,qAdrstRusage                           // structure retour du thread
    mov x8,260                                    // Call System wait4
    svc #0 
    cmp x0,#0                                     // erreur 
    blt 99f
                                                  // recup status 
    ldr x0,qAdriStatusThread                      // analyse status
    ldrb w0,[x0]                                  // premier byte
    cmp x0,#0                                     // fin normale du thread ?
    bne 1b                                        // non alors boucle
                                                  // fermeture pipe
    ldr x0,qAdrpipefd                             // FD pipe
    mov x8,57                                     // call system CLOSE
    svc #0 

    /* lecture des données pipe */ 
    ldr x0,qAdrpipefd                             // FD pipe
    ldr x0,[x0]
    ldr x1,qAdrsBuffer                            // adresse du buffer
    mov x2,#TAILLEBUFFER                          // taille du buffer 
    mov x8, READ                                  // call system
    svc #0 
    ldr x0,qAdrsBuffer 
    affmemtit buffer x0 4
    /* extraction de l'IP    */
    ldr x0,qAdrsBuffer                            // adresse du buffer
    ldr x1,qAdrszlibAdrIP                         // adresse debut libellé IP
    mov x2,#1                                     // 1ere occurence du mot clè 
    mov x3,#1                                     // deplacement du mot 
    ldr x4,qAdrsIP                                // adresse de stockage IP
    bl extChaine
    cmp x0,#-1
    beq 99f
   /* conversion IP  */
    ldr x0,qAdrsIP
    ldr x1,qAdrstSocket1
    bl convIP
    //ldr x0,qAdrstSocket1
    //affmemtit convIP x0 2
    /* connexion site Port 80 et lancement requete */ 
    bl envoiRequeteP80
    cmp x0,#-1
    beq 99f
    bl analyseReponse                             // analyse de la réponse

    ldr x0,qAdrszMessFinOK                        // affichage message Ok
    bl affichageMess
    mov x0, #0                                    // code retour OK
    b 100f
99:
    ldr x1,qAdrszMessErreur                       // erreur
    bl afficheErreur 
    mov x0, #1                                    // code retour erreur
    b 100f
100: 
    mov x8, #EXIT                                 // fin du programme
    svc #0                                        // system call
qFlags:                      .quad SIGCHLD
qAdrszMessDebutPgm:          .quad szMessDebutPgm
qAdrszMessFinOK:             .quad szMessFinOK
qAdrszMessErreur:            .quad szMessErreur
qAdrsBuffer:                 .quad sBuffer
qAdrpipefd:                  .quad pipefd
qAdrszCommande:              .quad szCommande
qAdrstArg1:                  .quad stArg1
qAdriStatusThread:           .quad qStatusThread
qAdrstRusage:                .quad stRusage
qAdrszlibAdrIP:              .quad szlibAdrIP
qAdrsIP:                     .quad sIP
qAdrstSocket1:               .quad stSocket1
//qCommande :                  .quad 0x0068732F6E69622F
/*********************************************************/
/*   connexion au site port 80 et envoi de la requete            */
/*********************************************************/
envoiRequeteP80:                // fonction
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    stp x4,x5,[sp,-16]!        // save  registres
    ldr x5,qAdrstSocket1            // preparation de la structure
    mov x0,#0x5000                  // port 80 stocké 0050
    strh w0,[x5,#sin_port]          // TODO a voir
    mov x0,#AF_INET                 // Internet IP Protocol
    strh w0,[x5,#sin_family]
    mov x0,x5
                                    //création socket
    mov x0,#AF_INET                 // Internet IP Protocol
    mov x1,#SOCK_STREAM
    mov x2,#0                       // null
    mov x8,#198                     // linux call system (socket 198)
    svc #0
    cmp x0,#INVALID_SOCKET
    beq erreur1
    affregtit socketok 0
                                    // connection 
    mov x20, x0                      // save host_sockid in x20
    mov x1,x5                       // adresse structure socket
    mov x2,#16                      // longueur de la structure
    mov x8,#203                     // linux call system 203 (connect)
    svc #0
    cmp x0,#INVALID_SOCKET
    ble erreur1
    affregtit connexion 0
    mov x2,#0
    ldr x1,qAdrszRequete1           // adresse requete 
1:                                  // calcul de la longueur de la requéte
    ldrb w0,[x1,x2]
    cmp x0,#0
    cinc x2,x2,ne
    //addne x2,#1
    bne 1b
                                    // envoi requéte
    mov x0,x20                       // socket
                                    // ici x1 contient l'adresse de la requéte et x2 sa longueur
    mov x3,#0
    mov x4,0
    mov x8,#206                     // linux call system (send  206)
    //affregtit avantsend 0
    svc #0
    cmp x0,#0
    blt erreur1
    //affregtit send 0
    ldr x6,qAdrsBufferPage
2:                                  //début de boucle de lecture des résultats
    mov x0,x20
    mov x1,x6
    mov x2,#LGBUFFERPAGE - 1
    mov x3,#0
    mov x8,#207                     // linux call system (recv 207)
    //add x8,#11
    svc #0
    cmp x0,#0
    ble 4f
    //affregtit recv 0
    add x6,x6,x0
    add x2,x0,x1
    ldrb w5,[x2,#-1]                // attention réutilisation de x5
    mov x1,#0xFFFFFF                // boucle d'attente pour la prochaine lecture
21:
    subs x1,x1,#1
    bgt 21b
    cmp x5,#0xA                     // fin des données ?
    bne 2b                          // non boucle

4:                                  // fin résultats

    //ldr x0,qAdrsBufferPage           // pour afficher le contenu de la page
    //bl affichageMess
    mov x0,x20                       // socket
    mov x8, #6                      // code pour la fonction systeme CLOSE
    svc 0
    mov x0,#0                       // requete OK
    b 100f
erreur1:                            // affichage erreur 
    ldr x1,qAdrszMessErreur	        // x0 <- code erreur, x1 <- adresse chaine
    bl   afficheErreur              // appel affichage message
    mov x0,#-1                      // code erreur
    b 100f
100:
    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

qAdrsBufferPage:            .quad sBufferPage
qAdrszRequete1:             .quad szRequete1
/*********************************************************/
/*   analyse de la réponse du site                       */
/*********************************************************/
analyseReponse:                // fonction
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    ldr x0,qAdrsBufferPage
    ldr x1,qAdrszlibDebMeteo            // recherche du début du message météo
    bl rechercheSousChaine
    cmp x0,#-1
    beq 99f
    //affregtit reponse 0
    ldr x1,qAdrsBufferPage
    add x2,x0,x1                        // calcul adresse début
    sub x2,x2,#1
    add x2,x2,#LGSZLIBDEBMETEO          // longueur mot clé
    mov x0,x2                           // save adresse début
    ldr x1,qAdrszlibFinMeteo
    bl rechercheSousChaine              // recherche la fin du message météo
    cmp x0,#-1
    beq 99f
    mov x1,#0
    strb w1,[x2,x0]                     // forçage zero final 
    // et il faut remplacer tous les <br/> par une fin de ligne
    mov x0,x2
    bl remplace
    mov x0,x2                           // affichage du résultat
    //affmemtit message x0 4
    bl affichageMess
    b 100f
99:
    affichelib erreur_analyseReponse
    ldr x0,qAdrszMessErreur             // erreur
    bl affichageMess
    mov x0, #-1                         // code retour erreur
    b 100f
100:                                    // fin standard de la fonction
    ldp x2,x3,[sp],16                   // restaur des  2 registres
    ldp x1,lr,[sp],16                   // restaur des  2 registres
    ret                                 // retour adresse lr x30

qAdrszlibDebMeteo:           .quad szlibDebMeteo
qAdrszlibFinMeteo:           .quad szlibFinMeteo

/*********************************************************/
/*   Correction du texte extrait                         */
/*********************************************************/
/* x0 contient l'adresse de l'extrait     */
remplace:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    mov x2,x0
1:
    mov x0,x2
    ldr x1,qAdrszlibBR             // recherche libellé <br/> à partir adresse x2
    bl rechercheSousChaine
    cmp x0,#-1                     // si non trouvé -> fin
    beq 100f
    add x2,x2,x0                      // ajout index trouvé
    mov x1,#' '
    strb w1,[x2]                   // stockage d'un blanc
    add x2,x2,#1
    ldr w1,iLib                    // stockage de 2 blancs et des retours lignes 
    str w1,[x2]
    add x2,x2,#4                      // pour recherche suivante
    b 1b                           // et boucle
100:                               // fin standard de la fonction
    mov x0,0
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszlibBR:            .quad szlibBR
iLib:                   .int 0x20200D0A

/*********************************************************/
/*   Extraction d 'un mot d'un texte suivant un mot cle  */
/*********************************************************/
/* x0  adresse du texte   */
/* x1  adresse mot clé a rechercher */
/* x2  nombre occurence mot cle */
/* x3  déplacement mot */
/* x4  adresse de stockage du mot */
extChaine:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    stp x4,x5,[sp,-16]!        // save  registres
    stp x6,x9,[sp,-16]!        // save  registres
    mov x5,x0            // save addresse texte
    mov x6,x1            // save mot clé
                         // il faut calculer la longueur du texte
    mov x8,#0
1:                       // calcul longueur texte
    ldrb w0,[x5,x8]      // pour des textes longs, et nombreuses recherches 
    cmp x0,#0            // il serait préférable de passer la longueur du texte en parametre
    cinc x8,x8,ne
    //addne x8,#1          // pour éviter cette boucle
    bne 1b
    add x8,x8,x5         // calcul adresse fin du texte
                         // il faut aussi la longueur du mot clé
    mov x9,#0
2:                       // calcul longueur mot clé
    ldrb w0,[x6,x9]
    cmp x0,#0
    cinc x9,x9,ne
    bne 2b
    //affregtit debrech 5
3:                       // boucle de recherche du nième(x2)  mot clé 
    mov x0,x5
    mov x1,x6
    bl rechercheSousChaine
    cmp x0,#0
    blt 100f
    //affregtit finrech 0
    subs x2,x2,#1
    ble 4f
    add x5,x5,x0
    add x5,x5,x9
    b 3b
4:
    add x0,x0,x5            // ajout adresse texte précédent à l'index trouvé
    add x3,x3,x0            // ajout du déplacement à x0
    sub x3,x3,#1
    add x3,x3,x9            // et il faut ajouter la longueur du mot cle 
    cmp x3,x8              // verification si pas superieur à la fin du texte
    bge 99f
    mov x0,#0
5:                       // boucle de copie des caractères 
    ldrb w2,[x3,x0]
    strb w2,[x4,x0]
    cmp x2,#0            // fin du texte ?
    beq 98f
    cmp x2,#' '          // fin du mot ?
    beq 6f               // alors fin
    cmp x2,#')'          // fin du mot ?
    beq 6f               // alors fin
    cmp x2,#'<'          // fin du mot ?
    beq 6f               // alors fin
    cmp x2,#10           // fin de ligne = fin du mot ?
    beq 6f               // alors fin
                         // ici il faut ajouter d'autres fin de mot comme > : . etc 
    add x0,x0,#1
    b 5b                 // boucle
6:
    mov x2,#0            // forçage 0 final
    strb w2,[x4,x0]
    add x0,x0,#1
    add x0,x0,x3         // x0 retourne la position suivant la fin du mot
                         // peut servir à continuer une recherche 
    b 100f
98:
    mov x0,#0            // dans ce cas x0 retourne 0
    b 100f
99:
    mov x0,#-1           // sinon erreur
100:                     // fin standard de la fonction
    ldp x6,x9,[sp],16    // restaur des  2 registres
    ldp x4,x5,[sp],16    // restaur des  2 registres
    ldp x2,x3,[sp],16    // restaur des  2 registres
    ldp x1,lr,[sp],16    // restaur des  2 registres
    ret

/******************************************************************/
/*   recherche d'une sous chaine dans une chaine                  */ 
/******************************************************************/
/* x0 contient l'adresse de la chaine */
/* x1 contient l'adresse de la sous-chaine */
/* x0 retourne l'index du début de la sous chaine dans la chaine ou -1 si non trouv�e */
rechercheSousChaine:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    stp x4,x5,[sp,-16]!        // save  registres
    stp x6,x7,[sp,-16]!        // save  registres
    mov x2,#0                  // index position chaine
    mov x3,#0                  // index position sous chaine
    mov x6,#-1                 // index recherche
    ldrb w4,[x1,x3]            // chargement premier octet sous chaine
    cmp x4,#0                  // zero final ?
    beq 99f
1:
    ldrb w5,[x0,x2]            // chargement octet chaine
    cmp x5,#0                  // zero final ?
    beq 99f
    cmp x5,x4                  // compare caractère des 2 chaines 
    beq 2f
    mov x6,#-1                 // différent - > raz index 
    mov x3,#0                  // et raz compteur byte
    ldrb w4,[x1,x3]            // et chargement octet
    add x2,x2,#1               // et increment compteur byte
    b 1b                       // et boucle
2:                             // caracteres egaux
    cmp x6,#-1                 // est-ce le premier caractère egal ?
    csel x6,x2,x6,eq           // oui -> index de debut est mis dans x6
    //moveq x6,x2              // oui -> index de debut est mis dans x6
    add x3,x3,#1               // increment compteur souschaine
    ldrb w4,[x1,x3]            // et chargement octet suivant
    cmp x4,#0                  // zero final ?
    beq 3f                     // oui -> fin de la recherche 
    add x2,x2,#1               // sinon increment index de la chaine
    b 1b                       // et boucle
3:
    mov x0,x6
    b 100f
99:
    mov x0,#-1                 // oui non trouvée
100:
    ldp x6,x7,[sp],16          // restaur des  2 registres
    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret
/*********************************************************/
/*   Conversion chaine adresse IP  en octet structure sockaddr_in */
/*********************************************************/
/* x0  adresse de la chaine   */
/* x1  adresse de la structure de type sockaddr_in */
convIP:
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    stp x4,x5,[sp,-16]!        // save  registres
    stp x6,x7,[sp,-16]!        // save  registres
    mov x5,x0                  // save addresse texte
    mov x2,#0
    mov x4,#sin_addr
    mov x6,x0                    // debut zone
                                 // recherche . ou fin de chaine
1:
    ldrb w3,[x5,x2]
    cmp x3,#0
    beq 4f                       // fin de chaine
    cmp x3,#'.'
    cinc x2,x2,ne
    //addne x2,#1
    bne 1b
    mov x3,#0                    // remplacement du point par le zero final
    strb w3,[x5,x2]
    mov x0,x6                    // conversion ascii registre
    bl conversionAtoD
    strb w0,[x1,x4]
    add x4,x4,#1
    add x2,x2,#1
    add x6,x5,x2
    b 1b
4:
    mov x0,x6                    // conversion finale
    bl conversionAtoD
    strb w0,[x1,x4]
100:                             // fin standard de la fonction
    ldp x6,x7,[sp],16          // restaur des  2 registres
    ldp x4,x5,[sp],16          // restaur des  2 registres
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM64.inc"
