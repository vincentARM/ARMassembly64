/* Programme assembleur ARM Raspberry ou Android */
/* Assembleur 64 bits ARM Raspberry              */
/* programme blockchain1.s */
/* programme maitre   */
/* attention : cet exemple est simpliste : pas de sauvegarde des portefeuilles, des cles */
/* et de la blockchain */
/* pas de calcul en mode distribué tout est local */
/* compilation :  make PGM=blockchain1  */
/************************************/
/* Constantes                       */ 
/************************************/
.include "./src/constantesARM64.inc"

/****************************************************/
/* fichier des macros                               */
/****************************************************/
.include "./src/ficmacros64.s"

/****************************************************/
/* fichier des structures                               */
/****************************************************/
.include "./src/structures64.inc"

/*********************************/
/* Données initialisées              */
/*********************************/
.data
szMessDebutPgm:      .asciz "Début programme.\n"
szMessFinPgm:        .asciz "Fin normale du programme. \n"
szRetourLigne:       .asciz "\n"
szTypeSHA256:        .asciz "SHA256"

.align 8
szHashPrec1:         .int 0,0,0,0          // hash précédent du bloc 0 (32 octets)
qTransactionID:      .int 0,0,0,1          // ident 1ère transaction 32 octets

/*********************************/
/* Données non initialisées       */
/*********************************/
.bss  
.align 8
qZoneT1:               .skip 16
qZoneT2:               .skip 16
qAdrTXUN:              .skip 8
sZoneCalHash:          .skip 72
HashProcess:           .skip (TAILLEHASH * 2) + 8
dlBlockchain1:         .skip dllist_fin        // BlockChain double liste chainée
stPortefeuilleA:       .skip porteF_fin        // structure portefeuille
stPortefeuilleB:       .skip porteF_fin
stPortefeuilleDepart:  .skip porteF_fin
tbUTXOblockchain:      .skip hash_fin          // hashmap
.global tbUTXOblockchain
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // INFO: main
    ldr x0,qAdrszMessDebutPgm
    bl afficherMessage
    
    afficherLib "Init librairie SSL"
    mov x2, #0                  //initialisation de la librairie crypto
    mov x1, #0
    mov x0, #12
    bl OPENSSL_init_crypto  
    //affregtit retourinit 0
    
    afficherLib "Init sorties UTXO"
    ldr x0,qAdrtbUTXOblockchain
    bl hashInit
    
    afficherLib "création blockchain"
    ldr x0,qAdrdlBlockchain1
    mov x19,x0                          // adresse  blockchain
    bl createDList                      // création blockchain
    
                                        // création des portemonnaies
    afficherLib "création portefeuille 1 "
    ldr x0,qAdrstPortefeuilleA
    bl creerPortefeuille
    
    afficherLib "création portefeuille 2 "
    ldr x0,qAdrstPortefeuilleB
    bl creerPortefeuille
    
    afficherLib "création portefeuille depart "
    ldr x0,qAdrstPortefeuilleDepart
    bl creerPortefeuille
    afficherLib "création transaction départ"   // création transaction
    ldr x0,qAdrstPortefeuilleDepart    // origine
    add x0,x0,porteF_clePub
    ldr x1,qAdrstPortefeuilleA         // destinataire
    add x1,x1,porteF_clePub
    ldr x2,fMontantInitial             // montant
    mov x3,0                           // entrées 
    bl creerTransaction
    mov x24,x0                         // adresse transaction
    ldr x1,qAdrqAdrTXUN
    str x0,[x1]
    //affmemtit "Transaction 0" x0 8
    afficherLib "Calcul signature TX départ"
    ldr x1,qAdrstPortefeuilleDepart    // origine
    add x1,x1,porteF_clePriv
    bl calculSignatureTx
    mov x0,x24
    
    afficherLib "Création tx sortie départ"
    ldr x1,qAdrqTransactionID
    add x0,x24,trans_id
    ldr x2,[x1]
    str x2,[x0]                        // copie des 32 caractères d'identification
    ldr x2,[x1,8]
    str x2,[x0,8]
    ldr x2,[x1,16]
    str x2,[x0,16]
    ldr x2,[x1,24]
    str x2,[x0,24]
    add x0,x24,trans_destinataire
    ldr x0,[x0]
    mov x2,x1                         // Identification parent
    ldr x1,[x24,trans_montant]
    bl creerTransactionSortie
    //affmemtit txSortie x0 5
    afficherLib "Ajout TX dans liste et hashmap"   // ajout à liste chainée sorties
    mov x1,x0                       // tx sorties
    add x0,x24,trans_sorties        // liste des sorties
    //affregtit ajoutTXsorties 0
    bl insertElement
    //affmemtit listeSorties x0 2
    mov x2,x1
    //add x2,x0,llist_value          // ajout dans hashMap
    add x1,x2,sortieTx_id
    //affregtit avanthashinser 0
    ldr x0,qAdrtbUTXOblockchain
    bl hashInsert

    //bl afficherHashMap
    
    mov x23,0
    afficherLib "Création bloc 0"
    ldr x0,qAdrszHashPrec1
    bl creerBloc
    mov x21,x0          // adresse bloc
    // bl afficherBloc   // pour affichage eventuel du bloc
    
    afficherLib "Ajout TX origine au bloc 0"
    mov x1,x24          // adresse TX
    bl ajouterTransaction  // ajouter transaction 
    
    //bl  afficherHashMap
    
    afficherLib "Ajout bloc 0 à la blockchain"
    mov x0,x21
    mov x1,x19                          // adresse  blockchain
    bl ajouterBloc

    //bl  afficherHashMap
    
    afficherLib "creation bloc 1"
    
    add x0,x21,bloc_hash
    bl creerBloc
    mov x22,x0  
    afficherLib "Solde A"
    ldr x0,qAdrstPortefeuilleA
    bl afficherSolde

    afficherLib "Virement 1 "
    ldr x0,qAdrstPortefeuilleA      // portefeuille origine
    ldr x1,qAdrtbUTXOblockchain     // sorties blockchain
    ldr x3,qAdrstPortefeuilleB      // cle publique destinataire
    add x2,x3,porteF_clePub
    ldr d0,fMontantVirement         // montant 
    bl envoyerFonds
     
    //bl  afficherHashMap
     
    afficherLib "Ajout transaction de virement 1 "
    mov x1,x0                       // adresse TX 
    mov x0,x22                      // adresse Bloc
    bl ajouterTransaction
    
    afficherLib "Virement 2 "
    ldr x0,qAdrstPortefeuilleB      // portefeuille origine
    ldr x1,qAdrtbUTXOblockchain     // sorties blockchain
    ldr x3,qAdrstPortefeuilleA      // cle publique destinataire
    add x2,x3,porteF_clePub
    ldr d0,fMontantVirement2         // montant
    bl envoyerFonds
    
    //bl  afficherHashMap
     
    afficherLib "Ajout transaction de virement 2"
    mov x1,x0                       // adresse TX créee par envoyer fonds
    mov x0,x22                      // adresse Bloc
    bl ajouterTransaction
    
    //bl  afficherHashMap
    
    afficherLib "Solde A"
    ldr x0,qAdrstPortefeuilleA
    bl afficherSolde
    
    afficherLib "Solde B"
    ldr x0,qAdrstPortefeuilleB
    bl afficherSolde
    
    
    afficherLib "Ajout bloc 1 à la blockchain"
    mov x0,x22
    mov x1,x19                          // adresse  blockchain
    bl ajouterBloc
    



    afficherLib "creation bloc 2"
    
    add x0,x22,bloc_hash
    bl creerBloc
    mov x23,x0  
    
    afficherLib "Virement 3 "
    ldr x0,qAdrstPortefeuilleA      // portefeuille origine
    ldr x1,qAdrtbUTXOblockchain     // sorties blockchain
    ldr x3,qAdrstPortefeuilleB      // cle publique destinataire
    add x2,x3,porteF_clePub
    ldr d0,fMontantVirement3         // montant
    bl envoyerFonds
    
    //bl  afficherHashMap
     
    afficherLib "Ajout transaction de virement 3"
    mov x1,x0                       // adresse TX créee par envoyer fonds
    mov x0,x23                      // adresse Bloc
    bl ajouterTransaction
    
    afficherLib "Ajout bloc 2" 
    
    mov x0,x23
    mov x1,x19                          // adresse  blockchain
    bl ajouterBloc

    afficherLib "SOLDE A"
    ldr x0,qAdrstPortefeuilleA
    bl afficherSolde

    afficherLib "SOLDE B"
    ldr x0,qAdrstPortefeuilleB
    bl afficherSolde

    
    afficherLib "Verification de la blockchain"
    ldr x0,qAdrdlBlockchain1
    bl verifierBlockchain
    

    
    ldr x0,qAdrszMessFinPgm
    bl afficherMessage
100:                            // fin standard du programme
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0
qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdrszHashPrec1:         .quad szHashPrec1
qAdrdlBlockchain1:        .quad dlBlockchain1
qAdrstPortefeuilleA:      .quad stPortefeuilleA
qAdrstPortefeuilleB:      .quad stPortefeuilleB
qAdrstPortefeuilleDepart: .quad stPortefeuilleDepart
fMontantInitial:          .double 100.0
fMontantVirement:         .double 40.0
fMontantVirement2:        .double 10.5
fMontantVirement3:        .double 5.25
qAdrqTransactionID:       .quad qTransactionID
qAdrqAdrTXUN:             .quad qAdrTXUN
qAdrtbUTXOblockchain:     .quad tbUTXOblockchain
/***************************************************/
/*   creation bloc              */
/***************************************************/
/* x0 contient adresse du hash precedent*/
creerBloc:                      // INFO: creerBloc
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x19,[sp,-16]!        // save  registres
    mov x3,x0

    mov x0,bloc_fin             // taille du bloc
    bl reserverPlace            // reserver la place du bloc sur le tas
    cmp x0,-1
    beq 100f
    mov x2,0                  
    add x5,x0,bloc_hash_prec
1:                              // boucle copie du hash precedent
    ldr w4,[x3,x2]
    str w4,[x5,x2]              // copie mot de 4 octets
    add x2,x2,4
    cmp x2,28                   // 
    ble 1b
    mov x19,x0
    ldr x0,qAdrqZoneT1             // création du timestamp par appel systeme linux
    ldr x1,qAdrqZoneT2
    mov x8,GETTIMEOFDAY            // call system linux date du jour
    svc 0 
    cbnz x0,99f                    // erreur ?
    ldr x0,qAdrqZoneT1
    ldr x0,[x0]                    // recopie le timestamp
    str x0,[x19,bloc_timbre]
    
    str xzr,[x19,bloc_nonce]       // initialisation du nonce
    str xzr,[x19,bloc_Transactions]// et des autres zones
    str xzr,[x19,bloc_données]     // contiendra le hash merkleroot
    str xzr,[x19,bloc_données+8]
    str xzr,[x19,bloc_données+16]
    str xzr,[x19,bloc_données+24]

    mov x0,x19                     // retourne l'adresse du bloc
    b 100f
99:                                // erreur création timestamp
    adr x1,szMessErrTime
    bl afficheErreur
100:
    ldp x2,x19,[sp],16             // restaur  registres
    ldp x1,lr,[sp],16              // restaur registres
    ret
qAdrqZoneT1:  .quad qZoneT1
qAdrqZoneT2:  .quad qZoneT2
szMessErrTime:  .asciz "\033[31mErreur appel GETTIMEOFDAY\n \033[0m"
.align 4
/***************************************************/
/*   ajout bloc  à la blockchain                    */
/***************************************************/
/* x0 contient adresse du bloc             */
/* x1 contient l'adresse de la blockchain  */
ajouterBloc:                     // INFO: ajouterBloc
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    mov x2,x1
    mov x3,x0
    mov x1,DIFFICULTE
    bl minerBloc               // minage
    
    mov x0,x2                  // adresse blockchain
    mov x1,x3                  // adresse du bloc 
    bl insertTail              // insertion en fin de blockchain
    
100:
    ldp x2,x3,[sp],16           // restaur  registres
    ldp x1,lr,[sp],16           // restaur registres
    ret
/***************************************************/
/*   calcul du hash d'un bloc  par minage           */
/***************************************************/
/* ATTENTION : on ne cherche les 0 que sur les 4 premiers octets du hash*/
/* donc une difficulté maxi de 8   */
/* x0 contient adresse du bloc             */
/* x1 contient la difficulté */
minerBloc:                     // INFO: minerBloc
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    mov x4,x0                  // adresse du bloc
    mov x2,x1                  // difficulté
    add x0,x4,bloc_Transactions
    //affregtit minerbloc1 0
    ldr x0,[x0]
    add x1,x4,bloc_données      // calcul du merkleroot
    bl calculerMerkleRoot
    //affregtit retourMerkle 0
    add x1,x4,bloc_hash         // adresse zone hash du bloc
    mov x3,0                    // nonce
1:                              // boucle minage
    mov x0,x4
    add x3,x3,1                 // incremente le nonce
    str x3,[x0,bloc_nonce]      // et le stocke dans le bloc
    bl calculHash
    cmp x0,-1                   // erreur ?
    beq 100f
    mov x5,3                    // début par le 4ième octet du hash en mémoire 
    mov x8,0                    // compteur des zéros
2:                              // comptage des zéros du hash
    ldrb w6,[x1,x5]
    and w7,w6,0xF0              // extraction des 4 bits de poids fort de l'octet
    cmp w7,0                    // zéro ?
    bne 1b                      // non -> boucle
    add  x8,x8,1                // incremente le compteur de zéros
    cmp x8,x2                   // noveau difficulté atteint ?
    bge 3f                      // fin minage
    and w7,w6,0xF               // extraction des 4 bits de poids faible de l'octet
    cmp w7,0                    // zéro ?
    bne 1b                      // non -> boucle
    add  x8,x8,1
    cmp x8,x2
    bge 3f
    sub x5,x5,1                 // octet précédent du hash
    b 2b
3:
    mov x0,0                    // minage OK
    
100:
    ldp x2,x3,[sp],16           // restaur  registres
    ldp x1,lr,[sp],16           // restaur registres
    ret
/***************************************************/
/*   calcul du hash d'un bloc                      */
/***************************************************/
/* x0 contient adresse du bloc             */
/* x1 contient l'adresse de la zone de reception */
calculHash:                     // INFO: calculHash
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x4,fp,[sp,-16]!         // save  registres
    stp x5,x6,[sp,-16]!         // save  registres
    mov x4,x0                   // adresse bloc
    mov x2,x1                   // adresse zone reception
   // affregtit calculHash 0
    sub sp,sp,(TAILLEHASH * 6)+(TAILLETIMBRE * 2)+(TAILLELONGUEUR * 2) + 16
    mov fp,sp                   // save adresse début reservation sur la pile 
    add x0,x4,bloc_hash_prec
    mov x1,fp
    bl conversionSHA256
    add x1,x1,(TAILLEHASH * 2)
    add x0,x4,bloc_timbre
    ldr x0,[x0]
    //affreghexa  Timbre
    bl prepRegistre16
    add x1,x1,(TAILLETIMBRE * 2)
    add x0,x4,bloc_nonce
    ldr x0,[x0]
    bl prepRegistre16
    add x1,x1,(TAILLELONGUEUR * 2)
    
    add x0,x4,bloc_données
    bl conversionSHA256
    add x1,x1,(TAILLEHASH * 2)
    strb wzr,[x1]                // 0 final 

    mov x0,fp
    //affmemtit avanthash x0 20
    mov x1,x2                // zone retour hash
    bl computeSHA256            // calcul du hash complet
    //affmemtit apreshash x0 4

    mov x0,0

100:
    add sp,sp,(TAILLEHASH * 6)+(TAILLETIMBRE * 2)+(TAILLELONGUEUR * 2) + 16
    ldp x5,x6,[sp],16           // restaur  registres
    ldp x4,fp,[sp],16           // restaur  registres
    ldp x2,x3,[sp],16           // restaur  registres
    ldp x1,lr,[sp],16           // restaur registres
    ret
/******************************************************************/
/*     affichage d'un bloc                         */ 
/******************************************************************/
/* x0 contains the address of the block */
afficherBloc:                   // INFO: afficherBloc
    stp x0,lr,[sp,-16]!         // save  registres
    stp x1,x4,[sp,-16]!         // save  registres
    mov x4,x0
    afficherLib "Debut bloc hash="
    add x0,x4,bloc_hash
    bl displaySHA256
    afficherLib "Debut bloc hash précédent="
    add x0,x4,bloc_hash_prec
    bl displaySHA256
    add x0,x4,bloc_données
    affmemtit merkleroot x0 3
    ldr x0,[x4,bloc_timbre]
    affregtit "timestamp dans x0" 0
    
    ldp x1,x4,[sp],16           // restaur registres
    ldp x0,lr,[sp],16           // restaur registres
    ret
/***************************************************/
/*   ajout d'une transaction dans un bloc          */
/***************************************************/
/* x0 contient l'adresse du bloc */
/* x1 contient l'adresse de la transaction */
ajouterTransaction:                    // INFO: ajouterTransaction
    stp fp,lr,[sp,-16]!         // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    mov x19,x0
    mov x20,x1
    cmp x1,0
    beq 99f
    //afficherLib ajouterTransaction
    add x0,x19,bloc_hash_prec
    ldr x1,qAdrszHashPrec1        // hash du bloc 0
    bl comparerHash
    cmp x0,0
    beq 1f                       // raf si bloc 0
    
    mov x0,x20   
    bl traiterTransaction
    
1:                               // insertion dans la liste des transactions
    mov x1,x20
    add x0,x19,bloc_Transactions
    bl insertElement
 
    mov x0,0
    b 100f
99:
    mov x0,-1                    // erreur
100:
    ldp x19,x20,[sp],16           // restaur  registres
    ldp fp,lr,[sp],16            // restaur registres
    ret
/******************************************************************/
/*     affichage d'un bloc                         */ 
/******************************************************************/
/* x0 addresse de la blockchain */
verifierBlockchain:             // INFO: verifierBlockchain
    stp fp,lr,[sp,-16]!         // save  registres
    sub sp,sp,hash_fin + 8
    mov fp,sp                   // Reservation place pour une hashmap temporaire
    ldr x8,qAdrdlBlockchain1
    ldr x5,[x8,dllist_head]
    ldr x4,[x5,NDlist_value]    // adresse bloc 0
    ldr x6,qAdrsZoneCalHash
    ldr x0,qAdrszHashPrec1      // verification si hash précédent est bien
    add x1,x4,bloc_hash_prec    // celui initial
    bl comparerHash
    cbnz x0,99f                 // erreur 
                                // stockage transaction origine
    mov fp,sp                   // dans la hashmap temporaire
    mov x0,fp
    bl hashInit
    mov x0,fp
    ldr x2,qAdrqAdrTXUN
    ldr x2,[x2]                  // adresse tx initiale
    add x3,x2,trans_sorties      // adresse liste des sorties
    ldr x1,[x3]
    add x2,x1,llist_value
    ldr x2,[x2]
    add x1,x2,trans_id
    bl hashInsert
    
1:                              // boucle de traitement des blocs
    mov x0,x4
    mov x1,x6
    bl calculHash               // verification du hash
    mov x0,x6
    add x1,x4,bloc_hash
    bl comparerHash
    cmp x0,0
    bne 97f
    mov x0,x4
    bl verifierMinage           // verification minage
    cmp x0,0
    bne 99f
    
    mov x7,x4                   // x7 = bloc precedent
    ldr x5,[x5,NDlist_next]
    cmp x5,0                    // fin  de liste ?
    beq 98f
    ldr x4,[x5,NDlist_value]    // adresse bloc
    mov x0,x6                   // comparaison hashs précédents
    add x1,x4,bloc_hash_prec
    bl comparerHash
    cbnz x0,99f
    
    mov x0,x4                     // adresse du bloc 
    mov x1,fp                     // txo temporaire
    bl verifierTransactionsBlock  // verification des transactions
    cmp x0,-1
    beq 99f
    b 1b                          // et boucle
    
97:
    afficherLib "Hash différent"
    adr x0,szMessVerifNonOk
    bl afficherMessage
    mov x0,-1
    b 100f
98:
    adr x0,szMessVerifOk
    bl afficherMessage
    mov x0,0
    b 100f
99:
    adr x0,szMessVerifNonOk
    bl afficherMessage
    mov x0,-1
100:
    add sp,sp,hash_fin + 8
    ldp fp,lr,[sp],16           // restaur registres
    ret
szMessVerifOk:       .asciz "\033[32mLa blockchain est valide.\033[0m\n"
szMessVerifNonOk:    .asciz "\033[31mLa blockchain n'est pas valide.\033[0m\n"
.align 4
qAdrsZoneCalHash:    .quad sZoneCalHash
/******************************************************************/
/*     verification des transactions du bloc                        */ 
/******************************************************************/
/* x0 adresse du bloc */
/* x1 adresse utxo temporaire */
verifierTransactionsBlock:                 // INFO: verifierTransactionsBlock
    stp fp,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x4,x5,[sp,-16]!         // save  registres
    stp x6,x7,[sp,-16]!         // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    mov x19,x0
    mov fp,x1                   // adresse UTXO temporaire

    mov x0,x19
    add x1,x0,bloc_Transactions
    cbz x1,5f                   // liste TX vide ?
    ldr x2,[x1]                 // adresse 1er poste de la liste
1:
    cbz x2,5f                   // fin de liste ?
    ldr x20,[x2,llist_value]    // recup adresse transaction dans liste
    mov x0,x20
   // affmemtit verif1TXBlockChain x0 5
    bl verifierSignatureTx      // signature OK ?
    cmp x0,-1
    bne 2f
    adr x0,szMessVerifTXNonOk
    bl afficherMessage
    mov x0,-1
    b 100f
2:
    add x0,x19,bloc_hash_prec    // si 1er bloc pas de verification
    cmp x0,0                     // car il n'ya pas de TX d'entrée
    beq 4f 
    mov x0,0
    fmov d0,x0                   // raz total
    scvtf d0,d0                  // et conversion en float
    fmov d2,d0
    ldr x0,[x20,trans_entrees]
    //affregtit entrees 0
    cmp x0,0
    beq 21f
    bl calculTotalEntrees
    fmov d2,d0
    //fmov x0,d0
    //affregtit montantentrees 0
21:
    add x0,x20,trans_sorties
    //affregtit sorties 0
    cmp x0,0
    beq 22f
    ldr x0,[x0]           // adresse de la 1ère sortie
    bl calculTotalSorties
22:    
    fcmp d0,d2           // comparaison des totaux entrées et sorties
    beq 3f
    adr x0,szMessVerifTotaux
    bl afficherMessage
    mov x0,-1
    b 100f

3:                       // vérification des entrées et sorties
    ldr x0,[x20,trans_entrees]
    //affregtit entrees 0
    cmp x0,0
    beq 4f
    mov x1,fp
    bl verifierEntrees
    cmp x0,-1
    beq 100f
    mov x0,x20
    mov x1,fp
    bl verifierSorties
    cmp x0,-1
    beq 100f
4:
    ldr x2,[x2,llist_next] 
    b 1b                       // transaction suivante
    
5:
    mov x0,0                    // verif OK
100:
    ldp x19,x20,[sp],16         // restaur registres
    ldp x6,x7,[sp],16           // restaur registres
    ldp x4,x5,[sp],16           // restaur registres
    ldp x2,x3,[sp],16           // restaur registres
    ldp fp,lr,[sp],16           // restaur registres
    ret
szMessVerifTXNonOk:    .asciz "\033[31mSignature d'un transaction non OK !!.\033[0m\n"
szMessVerifTotaux:    .asciz "\033[31mTotal des entrées différent total sorties!!.\033[0m\n"
.align 4
/******************************************************************/
/*     verification des entrées                                  */ 
/******************************************************************/
/* 
/* x0 adresse première entrée */
verifierEntrees:                 // INFO: verifierEntrees
    stp fp,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x4,x5,[sp,-16]!         // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    //afficherLib verifierEntrees
    mov x19,x0
    mov fp,x1                  // adresse UTXO provisoire
    mov x3,x19
1:                             // boucle liste chainee des entrées
    cbz x3,100f                // fin de liste ?
    ldr x2,[x3,llist_value]    // recup adresse d'une entrée
    //affregtit listentree 0
    mov x0,fp
    add x1,x2,entreeTx_id_S    // recup ident sortie
    mov x20,x1
    //affmemtit identifiant x1 5
    bl searchKey               // recherche si connu dans UTXO provisoire
    cmp x0,-1
    bne 11f
    adr x0,szMessErrIDsortie    // erreur  n'est pas connu !!
    bl afficherMessage
    mov x0,-1
    b 100f
11:
    //affmemtit MontantSorties x0 5
    ldr d0,[x0,sortieTx_montant]
    fmov x0,d0                   // recup du montant de la sortie
    //affregtit montant 0
    ldr x1,[x2,entreeTx_UTXO]    // recup du montant de la sortie UTXO liée à l'entrée
    ldr d1,[x1,sortieTx_montant]
    fcmp d0,d1
    beq 2f
    adr x0,szMessErrMntSorties    // montants differents !!
    bl afficherMessage
    mov x0,-1
    b 100f
2:                               // suppression dans la UTXO temporaire
    mov x0,fp
    mov x1,x20
    bl removeKey

    ldr x3,[x3,llist_next]
    b 1b
3:
    

    
100:
    ldp x19,x20,[sp],16           // restaur registres
    ldp x4,x5,[sp],16           // restaur registres
    ldp x2,x3,[sp],16           // restaur registres
    ldp fp,lr,[sp],16           // restaur registres
    ret
szMessErrIDsortie:    .asciz "\033[31mIdentifiant sortie non reférencé !\033[0m\n"
szMessErrMntSorties:  .asciz "\033[31mLes montants sont differents !\033[0m\n"
.align 4
/******************************************************************/
/*     verification des sorties                                  */ 
/******************************************************************/
/* x0 adresse transaction */
/* x1 adresse hashmap temporaire */
verifierSorties:                 // INFO: verifierSorties
    stp fp,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x4,x5,[sp,-16]!         // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    //afficherLib verifierSorties
    mov x19,x0
    mov fp,x1                  // adresse UTXO provisoire
    ldr x0,[x19,trans_sorties]
    //affregtit sorties 0
    cbz x0,6f                  // aucune sortie
    mov x3,x0
    mov x20,x0
1:                            // boucle liste chainée des sorties
    cbz x3,3f                // fin de liste ?
    ldr x2,[x3,llist_value]
    mov x0,x2
    //affmemtit insertionsorties x0 8
    mov x0,fp
    add x1,x2,sortieTx_id    // recup ident sortie
    bl hashInsert             // et insertion dans la UTXO temporaire
    ldr x3,[x3,llist_next]
    b 1b
3:
    ldr x1,[x19,trans_destinataire]
    ldr x1,[x1]                    // clé publique destinataire transaction
    ldr x2,[x20,llist_value]
    ldr x0,[x2,sortieTx_destinataire]
    ldr x0,[x0]                    // clé publique destinataire sorties
    //affregtit verifsortiedestinataire 0
    cmp x0,x1                      // égale ?
    beq 4f
    adr x0,szMessErrDest           // non erreur 
    bl afficherMessage
    mov x0,-1
    b 100f
4:
    ldr x1,[x19,trans_origine]
    ldr x1,[x1]                    // clé publique origine transaction
    ldr x20,[x20,llist_next]
    cmp x20,0
    bne 5f
    mov x0,-1
    b 100f
5:
    ldr x2,[x20,llist_value]
    ldr x0,[x2,sortieTx_destinataire]
    ldr x0,[x0]                    // clé publique destinataire sorties
    //affregtit verifsortiedestinataire1 0
    cmp x0,x1
    beq 6f
    adr x0,szMessErrOrigine           // non erreur 
    bl afficherMessage
    mov x0,-1
    b 100f
    
6:   // aucune sortie ou OK !!
    mov x0,0

100:
    ldp x19,x20,[sp],16           // restaur registres
    ldp x4,x5,[sp],16           // restaur registres
    ldp x2,x3,[sp],16           // restaur registres
    ldp fp,lr,[sp],16           // restaur registres
    ret
szMessErrDest:    .asciz "\033[31mLes destinataires des sorties sont differents !\033[0m\n"
szMessErrOrigine:    .asciz "\033[31mLes émetteurs des sorties sont differents !\033[0m\n"
.align 4
/******************************************************************/
/*     verification si le bloc a été miné                         */ 
/******************************************************************/
/* ATTENTION : ne verifie la présence des zéros que sur les 4 premiers octets soit 8 zéros  */
/* x0 adresse du bloc */
verifierMinage:                 // INFO: verifierMinage
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x4,x5,[sp,-16]!         // save  registres
    add x1,x0,bloc_hash
    mov x2,3
    mov x3,0
1:                           // boucle de comptage des zéros 
    ldrb w4,[x1,x2]
    and w0,w4,0xF0
    cmp w0,0
    bne 99f                 // manque un 0
    add  x3,x3,1            // nombre de zéros atteint ?
    cmp x3,DIFFICULTE
    bge 98f
    and w0,w4,0xF
    cmp w0,0
    bne 99f
    add  x3,x3,1
    cmp x3,DIFFICULTE
    bge 98f
    subs x2,x2,1
    bge 1b
    b 99f                    // erreur 
98:
    mov x0,0
    b 100f
99:
    adr x0,szMessErrMinage
    bl afficherMessage
    mov x0,-1
100:
    ldp x4,x5,[sp],16           // restaur registres
    ldp x2,x3,[sp],16           // restaur registres
    ldp x1,lr,[sp],16           // restaur registres
    ret
szMessErrMinage:    .asciz "\033[31mUn bloc n'est pas correctement miné !\033[0m\n"
.align 4

/******************************************************************/
/*     calcul du hash au sommet arbre de Merkle                   */ 
/******************************************************************/
// x0 adresse de la chaine des TX
// x1 contient l'adresse zone retour
// 
calculerMerkleRoot:            // INFO: calculerMerkleRoot
    stp fp,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    stp x5,x6,[sp,-16]!        // save  registres
    stp x19,x20,[sp,-16]!      // save  registres
    mov x19,x1
    //affregtit calculerMerkleRoot 0
    mov x20,sp                // save adresse pile départ 
    sub sp,sp,16+48           // reservation place
    mov fp,sp                 // adresse liste chainée locale
    str xzr,[fp]              // init liste
    str xzr,[fp,8]
    cbz x0,99f                // liste des TX vide ?
    mov x2,0                  // compteur
    mov x3,x0                 // debut de liste des TX
    cbz x3,99f                // aucune transaction 
1:
    add x1,x3,llist_value     // adresse d'une transaction
    ldr x1,[x1,trans_id]      // identifiant TX
    mov x0,fp                 // adresse liste interne
    bl insererHash
    add x2,x2,1               // comptage TX
    ldr x3,[x3,llist_next]    // element suivant
    cmp x3,0
    bne 1b                    // et boucle
    
    ldr x0,[fp]
    //affmemtit  stockage x0   10
    
2:
    cmp x2,1                   // une seule transaction ?
    ble 10f
    str xzr,[fp,8]             // init liste treelayer
    mov x2,0
    ldr x4,[fp]                // premier element
3:
    ldr x5,[x4,llist_next]     // element suivant
    cbnz x5,35f                // fin de liste ?
    add x0,fp,8                // nombre impair de hash
    add x1,x5,hlist_hash       // donc il faut recopier le dernier
    bl insererHash             // dans la liste
    add x2,x2,1                // et le compter
    b 8f
35:                            // nous avons 2 hash 
    ldr x1,qAdrHashProcess
    add x8,x4,hlist_hash
    add x6,x5,hlist_hash
    mov x0,0
4:                           // boucle copie hash transaction N - 1 
    ldr w3,[x8,x0]
    rev w3,w3                // inversion octets
    str w3,[x1,x0]
    add x0,x0,4
    cmp x0,TAILLEHASH
    blt 4b
    add x1,x1,TAILLEHASH     // adresse suite copie 
    mov x0,0
5:                           // Boucle copie hash transaction N
    ldr w3,[x6,x0]
    rev w3,w3                // inversion octets
    str w3,[x1,x0]
    add x0,x0,4
    cmp x0,TAILLEHASH
    blt 5b
    add x1,x1,TAILLEHASH
    strb wzr,[x1]                // 0 final 
    
    add x1,fp,16                 // adresse début zone reception
    ldr x0,qAdrHashProcess       // pour calculer le nouveau hash
    //affmemtit avanthash x0 8
    mov x3,x2                     // save compteur
    mov x2,TAILLEHASH * 2         // longueur de la zone
    bl computeSHA256LG            // calcul du hash complet
    mov x2,x3                     // restaur compteur
    add x0,fp,8                   // adresse liste treelayer
    add x1,fp,16                  // adresse du hash calculé
    bl insererHash                // pour insertion dans liste treelayer
    add x2,x2,1                   // increment compteur

    ldr x4,[x5,llist_next]        // hash suivant
    cbnz x4,3b
8:
    ldr x1,[fp]                   // inversion des 2 listes 
    ldr x0,[fp,8]                 // 
    str x0,[fp]                   // 
    str x1,[fp,8]
    b 2b                          // et boucle 
10:
    cbz x2,99f
                                  // recopie poste 1 dans zone retour
    mov x2,fp
    ldr x1,[x2]
    add x1,x1,hlist_hash
    //affmemtit final x1 4
    mov x2,0
11:
    ldr w3,[x1,x2]
    str w3,[x19,x2]
    add x2,x2,4
    cmp x2,TAILLEHASH
    blt 11b
    
    mov x0,x19
    //affmemtit merkleRoot x0 3

    b 100f
99:                          // raz complet du hash 
   str xzr,[x19]             // normalement le pgm java met une chaine vide
   str xzr,[x19,8]           // si une seule TX pourquoi ne pas mettre son hash
   str xzr,[x19,16]
   str xzr,[x19,24]
100:
    mov sp,x20
    ldp x19,x20,[sp],16      // restaur des  2 registres
    ldp x5,x6,[sp],16        // restaur des  2 registres
    ldp x3,x4,[sp],16        // restaur des  2 registres
    ldp x1,x2,[sp],16        // restaur des  2 registres
    ldp fp,lr,[sp],16        // restaur des  2 registres
    ret
qAdrHashProcess:     .quad HashProcess
/******************************************************************/
/*     affichage de la hashmap blockchain  pour vérificatio       */
/******************************************************************/
/* x0 adresse de la liste */
/* x1 adresse du hash à insérer */
insererHash:                    // INFO: insererHash
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x4,x5,[sp,-16]!         // save  registres
    mov x5,x0
    mov x0,hlist_fin
    bl reserverPlace
    cmp x0,0
    ble 99f                  // erreur allocation ?
    str xzr,[x0,hlist_next]  // raz pointeur next
    add x2,x0,hlist_hash     // adresse hash
    mov x3,#0
1:                           // copie du hash dans zone reservée
    ldr w4,[x1,x3]
    str w4,[x2,x3]
    add x3,x3,#4
    cmp x3,#TAILLEHASH
    blt 1b
                             // insertion dans la liste
    cbnz x5,2f               // liste vide ?
    str x0,[x5]              // premier element de la liste 
    b 100f
2:
    mov x1,x5
    ldr x5,[x1,hlist_next]
    cbnz x5,2b
    str x0,[x1,hlist_next]
    b 100f
99:
    mov x0,#-1                   // error ?
    
100:
    ldp x4,x5,[sp],16           // restaur des  2 registres
    ldp x2,x3,[sp],16           // restaur des  2 registres
    ldp x1,lr,[sp],16           // restaur des  2 registres
    ret
/******************************************************************/
/*     affichage de la hashmap blockchain  pour vérificatio       */
/******************************************************************/
/* x0 adresse du bloc */
afficherHashMap:                 // INFO: afficherHashMap
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x4,x5,[sp,-16]!         // save  registres
    stp x0,x6,[sp,-16]!         // save  registres
    afficherLib "Affichage UTXO blockchain"
    ldr x4,qAdrtbUTXOblockchain
    ldr x0,[x4,hash_count]
    affregtit taille 0
    mov x5,0
1:
    lsl x3,x5,3
    add x6,x3,hash_key
    ldr x0,[x4,x6]
    cbz x0,2f
    //affmemtit "Clé hash" x0 3   // cle = début datas hash
    add x6,x3,hash_data
    ldr x1,[x4,x6]
    affregtit poste 0
    affmemtit "datas hash" x1 8
2:
    add x5,x5,1
    cmp x5,MAXI
    blt 1b
    
100:
    ldp x0,x6,[sp],16           // restaur registres
    ldp x4,x5,[sp],16           // restaur registres
    ldp x2,x3,[sp],16           // restaur registres
    ldp x1,lr,[sp],16           // restaur registres
    ret
    