/* routines portefeuille */
/* attention utilise les routines de la lib openssl */
/**********************************************/
/* CONSTANTES                              */
/**********************************************/
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
szTypeSHA256:        .asciz "SHA256"
szMessSolde:         .asciz "Solde du portefeuille = @ totos\n"
/*********************************/
/* Données non initialisées       /
/*********************************/
.bss
sZoneConv:          .skip 24
/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text
.global creerPortefeuille,genererCles,envoyerFonds,calculerSolde,afficherSolde

/***************************************************/
/*   création portefeuille       */
/***************************************************/
/* x0 contient l'adresse de la structure portefeuille */
creerPortefeuille:                // INFO: creerPortefeuille 
    stp x1,lr,[sp,-16]!           // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    mov x19,x0
    add x0,x19,porteF_clePriv
    add x1,x19,porteF_clePub
    bl genererCles
    cbnz x0,100f
                                 // création hashMap transaction sorties
    mov x0,hash_fin
    bl reserverPlace
    cmp x0,-1
    beq 100f
    str x0,[x19,porteF_UTXO]
    bl hashInit
    mov x0,x19                   // adresse du portefeuille
    //affmemtit portefeuille x0 5
100:
    ldp x19,x20,[sp],16           // restaur  registres
    ldp x1,lr,[sp],16             // restaur registres
    ret
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
    //afficherLib genererCles
    
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
    ldr x0,[fp]           // rsa
    bl RSAPublicKey_dup
    mov x2,x0
    mov x1,6
    ldr x0,[x20]
    bl EVP_PKEY_assign
    cmp x0,1
    bne 99f
    
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
/***************************************************/
/*   creation portefeuille       */
/***************************************************/
/* x0 contient l'adresse de la structure portefeuille de l'emetteur */
/* x1 contient l'adresse du hashMap des sorties de la blockchain */
/* x2 contient le destinataire */
/* d0 contient le montant à transferer */
envoyerFonds:                     // INFO: envoyerFonds
    stp x1,lr,[sp,-16]!           // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    stp x21,x22,[sp,-16]!         // save  registres
    //afficherLib envoyerFonds
    mov x19,x0
    mov x20,x2
    bl calculerSolde
    fcmp d0,d1
    bgt 99f
    afficherLib "Le solde est OK"
    sub sp,sp,16                 // creation liste provisoire
    mov fp,sp
    str xzr,[fp]                 // init liste
    mov x0,0                     // init total à 0
    fmov d1,x0
    scvtf d1,d1                  // et conversion en float
    ldr x21,[x19,porteF_UTXO]
    mov x2,0
1:
    lsl x4,x2,3                  // 8 octets par poste
    add x4,x4,x21
    ldr x3,[x4,hash_data]        // charge une transaction sortie
    cmp x3,0                     // poste vide ?
    beq 2f

    ldr d2,[x3,sortieTx_montant]
    fadd d1,d1,d2                // ajout du montant
    add x0,x3,sortieTx_id        // id transaction
    bl creerTransactionEntree
    cmp x0,-1
    beq 100f
    mov x1,x0                    // adresse Tx entree crée
    mov x0,fp 
    bl insertElement             // insertion dans liste
    fcmp d1,d0
    bgt 3f
2:
    add x2,x2,1
    cmp x2,MAXI
    blt 1b
3:
    //afficherLib avantcreationTX
    add x0,x19,porteF_clePub     // cle publique origine
    mov x1,x20                   // destinataire
    fmov x2,d0                         // montant
    ldr x3,[fp]                        // entrées 
    bl creerTransaction
    mov x22,x0                         // adresse transaction
    //affmemtit "Transaction envoi" x0 5
    add x1,x19,porteF_clePriv          // cle privee origine
    bl calculSignatureTx
    //afficherLib "Signature TX Envoi"
    
    // suppression des sorties selectionnées
    ldr x2,[fp]
4:
    cmp x2,0
    beq 5f
    ldr x1,[x2,llist_value]
    add x1,x1,entreeTx_id_S
    mov x0,x21
    //affregtit removekey 0
    //affmemtit id_S x1 3
    bl removeKey
    cmp x0,-1
    beq 98f
   // affregtit removekeySuite 0
    ldr x2,[x2,llist_next]
    b 4b
5:
    mov x0,x22         // retourne adresse transaction
    //affmemtit "tx Envoi" x0 4
    
    b 100f
98:
    afficherLib "\033[31mEnvoyerFonds : Erreur suppression clé \033[0m\n"
    mov x0,-1
    b 100f
99:
    adr x0,szMessSoldePetit
    bl afficherMessage
    mov x0,-1
100:
    add sp,sp,16
    ldp x21,x22,[sp],16           // restaur  registres
    ldp x19,x20,[sp],16           // restaur  registres
    ldp x1,lr,[sp],16             // restaur registres
    ret
szMessSoldePetit:  .asciz "\033[31mPas assez de fonds pour ce transfert \033[0m\n"
.align 4
/***************************************************/
/*   calculer le Solde d'un portefeuille      */
/***************************************************/
/* x0 contient l'adresse de la structure portefeuille */
/* x1 contient l'adresse du hashMap des sorties de la blockchain */
/* d1 retourne le solde */
calculerSolde:                    // INFO: calculerSolde
    stp x1,lr,[sp,-16]!           // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    //affregtit calculerSolde 0
    mov x19,x0
    mov x20,x1
    mov x0,0                     // init total à 0
    fmov d1,x0
    scvtf d1,d1                  // et conversion en float
    mov x5,0
1:
    lsl x4,x5,3                  // 8 octets par poste
    add x4,x4,x20
    ldr x3,[x4,hash_data]        // charge une transaction sortie
    cbz x3,2f                    // poste vide ?
    add x0,x3,sortieTx_destinataire    // charge adresse cle publique de la tx 
    ldr x0,[x0]                  // charge adresse cle publique du portefeuille
    ldr x0,[x0]                  // charge l'adresse  de la cle publique genérée
    add x1,x19,porteF_clePub     // charge l'adresse de la cle publique du portefeuille
    ldr x1,[x1]
    cmp x0,x1                    // compare les 2 adresses (il faudrait comparer les 2 clés !)
    bne 2f
    ldr d2,[x3,sortieTx_montant]
    fadd d1,d1,d2                // ajout du montant
    ldr x0,[x19,porteF_UTXO]     // adresse hashMap sorties portefeuille
    add x1,x3,sortieTx_id        // id transaction
    mov x2,x3                    // transaction
    bl hashInsert                // insertion
    ldr x0,[x19,porteF_UTXO]     // adresse hashMap sorties portefeuille
2:
    add x5,x5,1                  // autre sortie 
    cmp x5,MAXI
    blt 1b                       // et boucle
    
100:
    ldp x19,x20,[sp],16           // restaur  registres
    ldp x1,lr,[sp],16             // restaur registres
    ret
/***************************************************/
/*   afficher le Solde d'un portefeuille           */
/***************************************************/
/* x0 contient l'adresse de la structure portefeille */
afficherSolde:                    // INFO: afficherSolde
    stp x1,lr,[sp,-16]!           // save  registres
    ldr x1,qAdrtbUTXOblockchain
    bl calculerSolde
    fmov d0,d1
    ldr x0,qAdrsZoneConv
    bl convertirFloat
    ldr x1,qAdrsZoneConv
    ldr x0,qAdrszMessSolde
    bl strInsertAtChar
    bl afficherMessage 
    
100:
    ldp x1,lr,[sp],16             // restaur registres
    ret
qAdrtbUTXOblockchain:     .quad tbUTXOblockchain
qAdrszMessSolde:          .quad szMessSolde
qAdrsZoneConv:            .quad sZoneConv
