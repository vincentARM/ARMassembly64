/* routines des transactions */

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
/* donnees initialisées */
.data
qNumSeqTX:        .quad  0

/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text
.global creerTransaction,creerTransactionEntree,creerTransactionSortie,traiterTransaction
.global calculTotalEntrees,calculTotalSorties,calculHashTx,calculSignatureTx,verifierSignatureTx
/***************************************************/
/*   creation transaction       */
/***************************************************/
/* x0 contient l'adresse cle origine */
/* x1 contient l'adresse cle destinataire */
/* x2 contient le montant (float) */
/* x3 contient la liste des entrees */
creerTransaction:                // INFO: creerTransaction
    stp x1,lr,[sp,-16]!           // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    mov x4,x0
    mov x0,trans_fin
    bl reserverPlace
    cmp x0,-1
    beq 99f
    mov x19,x0   
    str x4,[x19,trans_origine]
    str x1,[x19,trans_destinataire]
    str x2,[x19,trans_montant]
    str x3,[x19,trans_entrees]
    str xzr,[x19,trans_sequence]
    str xzr,[x19,trans_sorties]
    mov  x3,64
    str x3,[x19,trans_lgsignature]
    str xzr,[x19,trans_signature]

    mov x0,x19
    b 100f
99:
    adr x1,szMessErrTas1
    bl afficheErreur
    mov x0,-1
100:
    ldp x19,x20,[sp],16           // restaur  registres
    ldp x1,lr,[sp],16             // restaur registres
    ret
szMessErrTas1:  .asciz "\033[31mErreur place tas création transaction \033[0m\n"
.align 4
/***************************************************/
/*   creation transaction       */
/***************************************************/
/* x0 contient l'identification de la transaction */
creerTransactionEntree:                // INFO: creerTransactionEntree
    stp fp,lr,[sp,-16]!           // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    mov x19,x0
    mov x0,entreeTx_fin
    bl reserverPlace
    cmp x0,-1
    beq 99f
    add x1,x0,entreeTx_id_S
    ldr x2,[x19]
    str x2,[x1]
    ldr x2,[x19,8]
    str x2,[x1,8]
    ldr x2,[x19,16]
    str x2,[x1,16]
    ldr x2,[x19,24]
    str x2,[x1,24]
    b 100f
99:
    adr x1,szMessErrTas2
    bl afficheErreur
    mov x0,-1
100:
    ldp x19,x20,[sp],16           // restaur  registres
    ldp fp,lr,[sp],16             // restaur registres
    ret
szMessErrTas2:  .asciz "\033[31mErreur place tas création transaction entrée \033[0m\n"
.align 4
/***************************************************/
/*   creation transaction       */
/***************************************************/
/* x0 contient l'adresse cle publique destinataire */
/* x1 contient le montant (float) */
/* x2 contient  l'adresse de l'identification du  parent */
creerTransactionSortie:           // INFO: creerTransactionSortie
    stp fp,lr,[sp,-16]!           // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    mov x4,x0
    mov x0,sortieTx_fin
    bl reserverPlace
    cmp x0,-1
    beq 99f
    mov x19,x0
    str x4,[x19,sortieTx_destinataire]
    str x1,[x19,sortieTx_montant]
    add x4,x19,sortieTx_Parent_id
    ldr x1,[x2]                  // recopie l'ID du parent (sur 32 octets)
    str x1,[x4]                  // dans la zone parent
    ldr x1,[x2,8]
    str x1,[x4,8]
    ldr x1,[x2,16]
    str x1,[x4,16]
    ldr x1,[x2,24]
    str x1,[x4,24]
                                 // calcul du hash
    sub sp,sp,(16 * 3) + 64      // reserve la place sur la pile
    mov fp,sp
    ldr x0,[x19,sortieTx_destinataire]
    mov x1,fp
    bl prepRegistre16
    ldr x0,[x19,sortieTx_montant]
    add x1,fp,16
    bl prepRegistre16
    add x0,x19,sortieTx_Parent_id
    add x1,fp,32
    bl conversionSHA256
    strb wzr,[fp,80]            // 0 final
    mov x0,fp
   // bl afficherMessage
    add x1,x19,sortieTx_id      //  zone ID de la TX 
    bl computeSHA256            // calcul du hash complet
    add x0,x19,sortieTx_id      //  zone ID de la TX 

    mov x0,x19                  // retourne l'adresse de la TX 
    b 100f
99:
    ldr x1,szMessErrTasSortie
    bl afficheErreur
    mov x0,-1
100:
    add sp,sp,(16 * 3) + 64
    ldp x19,x20,[sp],16          // restaur  registres
    ldp fp,lr,[sp],16            // restaur registres
    ret
szMessErrTasSortie:  .asciz "\033[31mErreur place tas création transaction Sorties\033[0m\n"
.align 4

/***************************************************/
/*   traitement d'une transaction       */
/***************************************************/
/* x0 contient l'adresse de la transaction */ 
traiterTransaction:               // INFO: traiterTransaction
    stp fp,lr,[sp,-16]!           // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    mov x19,x0
    //affmemtit traiterTransaction  x0 6
    bl verifierSignatureTx
    cbz x0,1f
    adr x0,szMessTXSignNonOk
    bl afficherMessage
    b 100f
1:
    add x3,x19,trans_entrees
    cmp x3,0                      // aucune TX en entrée
    beq 3f 
    ldr x2,[x3]                   // charge la première entrée de la liste
2:
    ldr x4,[x2,llist_value]       // charge la transaction entrée
    mov x0,x4
    //affmemtit entreesTX x0 5
    add x1,x4,entreeTx_id_S       // recup  adresse identification sortie
    ldr x0,qAdrtbUTXOblockchain   // et recherche dans la hashmap blockchain
    bl searchKey
    cmp x0,-1
    beq 99f
    str x0,[x4,entreeTx_UTXO]    // stocke la transaction de sortie associée
    ldr x2,[x2,llist_next]       // autre entrée dans la liste
    cbnz x2,2b                   // et boucle 

3:
    ldr x0,[x19,trans_entrees]    // première entrée
    cmp x0,0
    beq 4f
    //affregtit caltotalentrees 0
    bl calculTotalEntrees
    
    ldr d1,fMontantMinimum
    fcmp d0,d1
    bgt 4f
    adr x0,szMessTXMontantPetit
    bl afficherMessage
    mov x0,-1
    b 100f
4:
    ldr d1,[x19,trans_montant]
    fsub d0,d0,d1
    mov x0,x19
    add x1,x19,trans_id       // id TX = calcul hash tx
    //affmemtit avantcalculHash x0 8
    bl calculHashTx           // TODO à revoir
    ldr x0,[x19,trans_destinataire]  // création transaction
   // affregtit avantcreatsortie1A 0
    fmov x1,d1                    // création transaction sortie pour le destinataire
    add x2,x19,trans_id
    bl creerTransactionSortie
    //affmemtit creationTXsortie1 x0 8
    mov x1,x0                     // ajout dans la liste des sorties
    add x0,x19,trans_sorties
    //affmemtit listesorties x0 5
    bl insertElement
    ldr x0,qAdrtbUTXOblockchain  // et insertion dans la hashMap bolckchain
    mov x2,x1                    // adresse transaction
    add x1,x1,sortieTx_id           // ident tX
    bl hashInsert
    
    //add x0,x19,trans_origine    // création transaction sortie pour l'envoyeur
    ldr x0,[x19,trans_origine ]
    fmov x1,d0
    //affregtit valeurEnvoyée 0
    add x2,x19,trans_id
    bl creerTransactionSortie
    //affmemtit creationTXsortie2 x0 8
    mov x1,x0                    // ajout dans la liste des sorties
    add x0,x19,trans_sorties
    bl insertElement
    add x0,x19,trans_sorties
    ldr x0,[x0]
    
    ldr x0,qAdrtbUTXOblockchain  // et insertion dans la hashMap bolckchain
    mov x2,x1                    // adresse transaction
    add x1,x1,sortieTx_id        // ident tX
    bl hashInsert
    
                                 // suppression transaction entrée traitée
    add x3,x19,trans_entrees
    cmp x3,0
    beq 7f 
    ldr x2,[x3]  
    //affregtit debuttransentrees 0
5:
    ldr x4,[x2,llist_value]        // id transaction
    mov x0,x4
    //affmemtit entrresTX1 x0 5
    add x0,x4,entreeTx_UTXO        // recup  utxo
    cmp x0,0
    beq 6f
    ldr x0,qAdrtbUTXOblockchain    // et suppression dans la hashMap bolckchain
    add x1,x4,entreeTx_id_S        // recup  adresse identification à supprimer
    bl removeKey
    cmp x0,-1
    beq 98f
6:
    ldr x2,[x2,llist_next]
    cmp x2,0
    bne 5b
7: 
    b 100f
98:
    adr x0,szMessTXnontrouveeSup
    bl afficherMessage
    mov x0,-1
    b 100f
99:
    adr x0,szMessTXnontrouvee
    bl afficherMessage
    mov x0,-1
100:
    ldp x19,x20,[sp],16           // restaur  registres
    ldp fp,lr,[sp],16           // restaur registres
    ret
szMessTXSignNonOk:       .asciz "\033[31mSignature transaction non valide !!\033[0m\n"
szMessTXMontantPetit:    .asciz "\033[31mMontant transaction trop petit !!\033[0m\n"
szMessTXnontrouvee:      .asciz "\033[31mTransaction non trouvée dans hashMap blockchain \033[0m\n"
szMessTXnontrouveeSup:   .asciz "\033[31mTransaction non trouvée dans hashMap blockchain pour suppression\033[0m\n"
.align 4
qAdrtbUTXOblockchain:    .quad tbUTXOblockchain
fMontantMinimum:         .double 0.01
/***************************************************/
/*   calcul total des entrées                      */
/***************************************************/
/* x0 contient l'adresse d'une entrée */
/* d0 retourne le total */
calculTotalEntrees:                    // INFO: calculTotalEntrees
    stp fp,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    //afficherLib calculTotalEntrees
    mov x19,x0
    mov x0,0                  // valeur 0
    fmov d0,x0
    scvtf d0,d0               // et conversion en float
    mov x3,x19
1:
    cmp x3,0                // liste chainee des entrées
    beq 2f
    ldr x2,[x3,llist_value]
    mov x0,x2
    //affmemtit txentree x0 5
    ldr x0,[x2,entreeTx_UTXO]
    cmp x0,0
    beq 11f
    //affmemtit UTXO x0 5
    ldr d1,[x0,sortieTx_montant]
    fadd d0,d0,d1
11:
    ldr x3,[x3,llist_next]
    b 1b
2:
    fmov x0,d0
    //affregtit Montantcumulé 0
100:
    ldp x19,x20,[sp],16           // restaur  registres
    ldp x2,x3,[sp],16           // restaur registres
    ldp fp,lr,[sp],16           // restaur registres
    ret
/***************************************************/
/*   calcul total des sorties                      */
/***************************************************/
/* x0 contient l'adresse d'une sortie */
/* d0 retourne le total */
calculTotalSorties:             // INFO: calculTotalSorties
    stp fp,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x19,x20,[sp,-16]!       // save  registres
   // afficherLib calculTotalSorties
    mov x19,x0
    mov x0,0                    // valeur 0
    fmov d0,x0
    scvtf d0,d0                 // et conversion en float
    mov x3,x19
1:
    cbz x3,2f                   // fin liste chainée des sorties ?
    ldr x2,[x3,llist_value]
    ldr d1,[x2,sortieTx_montant]
    fadd d0,d0,d1
    ldr x3,[x3,llist_next]
    b 1b
2:
    fmov x0,d0                  // retourne aussi le total dans x0 !!
100:
    ldp x19,x20,[sp],16         // restaur  registres
    ldp x2,x3,[sp],16           // restaur registres
    ldp fp,lr,[sp],16           // restaur registres
    ret
/***************************************************/
/*   calcul du hash d'une transaction       */
/***************************************************/
/* x0 contient l'adresse de la transaction */
/* x1 contient l'adresse de la zone de retour */
calculHashTx:                    // INFO: calculHashTx
    stp fp,lr,[sp,-16]!          // save  registres
    stp x19,x20,[sp,-16]!        // save  registres
    mov x19,x0
    mov x2,x1
    sub sp,sp,(16 * 5)
    mov fp,sp
    ldr x0,[x19,trans_origine]
    mov x1,fp
    bl prepRegistre16
    ldr x0,[x19,trans_destinataire]
    add x1,fp,16
    bl prepRegistre16
    ldr x0,[x19,trans_montant]
    add x1,fp,32
    bl prepRegistre16
    ldr x3,qAdrqNumSeqTX        // incremente le N° de sequence
    ldr x0,[x3]
    add x0,x0,1
    str x0,[x19,trans_sequence]
    str x0,[x3]
    //affregtit sequence 0
    add x1,fp,48
    bl prepRegistre16
    strb wzr,[fp,64]            // 0 final
    mov x0,fp
    //bl afficherMessage
    mov x1,x2
    bl computeSHA256            // calcul du hash complet

100:
    add sp,sp,16 * 5
    ldp x19,x20,[sp],16           // restaur  registres
    ldp fp,lr,[sp],16           // restaur registres
    ret
qAdrqNumSeqTX:        .quad qNumSeqTX
/***************************************************/
/*   calcul signature d'une transaction       */
/***************************************************/
/* x0 contient l'adresse de la transaction */
/* x1 contient l'adresse de la clé privée   */
calculSignatureTx:                 // INFO: calculSignatureTx
    stp fp,lr,[sp,-16]!            // save  registres
    stp x19,x20,[sp,-16]!          // save  registres
    mov x19,x0
    mov x20,x1
    sub sp,sp,(16 * 5)
    mov fp,sp
    ldr x0,[x19,trans_origine]
    mov x1,fp
    bl prepRegistre16
    ldr x0,[x19,trans_destinataire]
    add x1,fp,16
    bl prepRegistre16
    ldr x0,[x19,trans_montant]
    add x1,fp,32
    bl prepRegistre16
    strb wzr,[fp,48]                // 0 final
    mov x0,fp
   // bl afficherMessage
    add x1,x19,trans_signature
    add x2,x19,trans_lgsignature
    mov x3,x20
    bl signerMessage
    
100:
    add sp,sp,(16 * 5)
    ldp x19,x20,[sp],16           // restaur  registres
    ldp fp,lr,[sp],16           // restaur registres
    ret
/***************************************************/
/*   verification signature d'une transaction       */
/***************************************************/
/* x0 contient l'adresse de la transaction */
/* x1 contient l'adresse de la clé privée   */
verifierSignatureTx:                    // INFO: verifierSignatureTx
    stp fp,lr,[sp,-16]!         // save  registres
    stp x1,x2,[sp,-16]!         // save  registres
    stp x3,x4,[sp,-16]!         // save  registres
    stp x19,x20,[sp,-16]!       // save  registres
    //affregtit "verifierSignatureTx" 0
    mov x19,x0
    mov x20,x1
    sub sp,sp,(16 * 5)
    mov fp,sp
    ldr x0,[x19,trans_origine]
    mov x1,fp
    bl prepRegistre16
    ldr x0,[x19,trans_destinataire]
    add x1,fp,16
    bl prepRegistre16
    ldr x0,[x19,trans_montant]
    add x1,fp,32
    bl prepRegistre16
    strb wzr,[fp,48]            // 0 final
    mov x0,fp
    //bl afficherMessage
    add x1,x19,trans_signature
    add x2,x19,trans_lgsignature
    add x3,x19,trans_origine     // cle publique origine
    bl verifierSignature
    
100:
    add sp,sp,(16 * 5)
    ldp x19,x20,[sp],16           // restaur  registres
    ldp x3,x4,[sp],16           // restaur registres
    ldp x1,x2,[sp],16           // restaur registres
    ldp fp,lr,[sp],16           // restaur registres
    ret
    