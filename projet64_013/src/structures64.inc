/************************************/
/* Structures       */
/************************************/
/* entête d'un bloc */
    .struct  0
bloc_hash:                        // signature bloc
    .struct  bloc_hash + TAILLEHASH
bloc_hash_prec:                   // signature bloc précédent
    .struct  bloc_hash_prec + TAILLEHASH
bloc_Transactions:
    .struct bloc_Transactions + TAILLELONGUEUR     // liste chainée des transactions
bloc_timbre:
    .struct  bloc_timbre + TAILLETIMBRE
bloc_longDonnées:
    .struct  bloc_longDonnées  + TAILLELONGUEUR   // longueur des données (y compris le 0 final)
bloc_nonce:
    .struct  bloc_nonce  + TAILLELONGUEUR   // zone necessaire pour le minage
bloc_données:      // = merkleroot
    .struct  bloc_données  + TAILLEHASH
bloc_fin:
/* portefeuille */
    .struct  0
porteF_clePriv:                        //  pointeur clé privé
    .struct  porteF_clePriv + 8
porteF_clePub:                         //  pointeur clé publique
    .struct  porteF_clePub + 8
porteF_UTXO:                         //  pointeur hashMap transactions sorties
    .struct  porteF_UTXO + 8
porteF_fin:
/* transaction */
    .struct  0
trans_id:                        //  identification = hash
    .struct  trans_id + TAILLEHASH
trans_origine:                   // 
    .struct  trans_origine + 8
trans_destinataire:               // 
    .struct  trans_destinataire + 8
trans_montant:               // 
    .struct  trans_montant + 8
trans_signature:               // 
    .struct  trans_signature + 8
trans_lgsignature:               // 
    .struct  trans_lgsignature + 8
trans_entrees:               // 
    .struct  trans_entrees + 8
trans_sorties:               // 
    .struct  trans_sorties + 8

trans_sequence:               // 
    .struct  trans_sequence + 8
trans_fin:

/* transaction entrée */
    .struct  0
entreeTx_id_S:                        //
    .struct  entreeTx_id_S + TAILLEHASH
entreeTx_UTXO:                        //
    .struct  entreeTx_UTXO + 8
entreeTx_fin:
/* transaction sorties */
    .struct  0
sortieTx_id:                                //
    .struct  sortieTx_id + TAILLEHASH       // 32 octets 
sortieTx_destinataire:                      //
    .struct  sortieTx_destinataire + 8
sortieTx_montant:                           //
    .struct  sortieTx_montant + 8
sortieTx_Parent_id:                         //
    .struct  sortieTx_Parent_id + TAILLEHASH    // 32 octets de l'ID du parent
sortieTx_fin:

/* structure hashMap   */
    .struct  0
hash_count:                       //  stored values counter
    .struct  hash_count + 8
hash_key:                         //  key
    .struct  hash_key + (8 * MAXI)
hash_data:                        // data
    .struct  hash_data + (8 * MAXI)
hash_fin:

/* structure liste chainée*/
    .struct  0
llist_next:                    // next element
    .struct  llist_next + 8
llist_value:                   // element value
    .struct  llist_value + 8
llist_fin:

/* structure liste chainée spécial hash */
    .struct  0
hlist_next:                    // next element
    .struct  hlist_next + 8
hlist_hash:                   // hash sur 32 caractères
    .struct  hlist_hash + 32    
hlist_fin:

/* structure Double liste chainée */
    .struct  0
dllist_head:                    // head node
    .struct  dllist_head + 8
dllist_tail:                    // tail node
    .struct  dllist_tail  + 8
dllist_fin:
/* structure des noeuds d'une liste chainée double */
    .struct  0
NDlist_next:                    // next element
    .struct  NDlist_next + 8
NDlist_prev:                    // previous element
    .struct  NDlist_prev + 8
NDlist_value:                   // pointeur bloc
    .struct  NDlist_value + 8 
NDlist_fin:
