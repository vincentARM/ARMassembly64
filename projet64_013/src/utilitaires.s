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
/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text
.global comparerHash,createDList,isEmpty,insertHead,insertTail,createNode,signerMessage,verifierSignature
.global insertElement,hashInit,hashInsert,hashIndex,searchKey,removeKey,comparStrings

/******************************************************************/
/*     comparaison de 2 hash                          */ 
/******************************************************************/
/* x0 premier hash */
/* x1 deuxieme hash */
comparerHash:                   // INFO: comparerHash
    stp x2,lr,[sp,-16]!         // save  registres
    stp x3,x4,[sp,-16]!         // save  registres
    mov x2,0
1:
    ldr x3,[x0,x2]
    ldr x4,[x1,x2]
    cmp x3,x4
    bne 99f
    add x2,x2,8
    cmp x2,24
    ble 1b
    mov x0,0
    b 100f
99:
    mov x0,-1
100:
    ldp x3,x4,[sp],16           // restaur registres
    ldp x2,lr,[sp],16           // restaur registres
    ret
 /******************************************************************/
/*     create new list                         */ 
/******************************************************************/
/* x0 contains the address of the list structure */
createDList:                     // INFO: createDList
    stp x1,lr,[sp,-16]!         // save  registres
    mov x1,0
    str x1,[x0,#dllist_tail]
    str x1,[x0,#dllist_head]
    ldp x1,lr,[sp],16           // restaur registres
    ret
/******************************************************************/
/*     list is empty ?                         */ 
/******************************************************************/
/* r0 contains the address of the list structure */
/* r0 return 0 if empty  else return 1 */
isEmpty:                           // INFO:  isEmpty
    ldr x0,[x0,#dllist_head]
    cmp x0,#0
    beq 100f
    mov x0,#1
100:
    ret                                // return
/******************************************************************/
/*     insert value at list head                        */ 
/******************************************************************/
/* x0 contains the address of the list structure */
/* x1 contains block address  */
insertHead:                      // INFO: insertHead
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x4,x5,[sp,-16]!         // save  registres
    mov x4,x0                            // save address
    mov x0,x1                            // value
    bl createNode
    cmp x0,#-1                           // allocation error ?
    beq 100f
    ldr x2,[x4,#dllist_head]             // load address first node
    str x2,[x0,#NDlist_next]             // store in next pointer on new node
    mov x1,#0
    str x1,[x0,#NDlist_prev]             // store zero in previous pointer on new node
    str x0,[x4,#dllist_head]             // store address new node in address head list 
    cmp x2,#0                            // address first node is null ?
    beq 1f
    str x0,[x2,#NDlist_prev]           // no store adresse new node in previous pointer
    b 100f
1:
    str x0,[x4,#dllist_tail]           // else store new node in tail address
100:
    ldp x4,x5,[sp],16           // restaur registres
    ldp x2,x3,[sp],16           // restaur registres
    ldp x1,lr,[sp],16           // restaur registres
    ret
/******************************************************************/
/*     insert value at list tail                        */ 
/******************************************************************/
/* r0 contains the address of the list structure */
/* r1 contains value */
insertTail:                     // INFO: insertTail
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x4,x5,[sp,-16]!         // save  registres
    mov x4,x0                            // save list address
    mov x0,x1                            // value
    bl createNode                        // create new node
    cmp x0,#-1
    beq 100f                             // allocation error
    ldr x2,[x4,#dllist_tail]             // load address last node
    str x2,[x0,#NDlist_prev]             // store in previous pointer on new node
    mov x1,#0                            // store null un next pointer
    str x1,[x0,#NDlist_next]
    str x0,[x4,#dllist_tail]             // store address new node on list tail
    cmp x2,#0                            // address last node is null ?
    beq 1f
    str x0,[x2,#NDlist_next]           // no store address new node in next pointer
    b 100f
1:
    str x0,[x4,#dllist_head]           // else store in head list
100:
    ldp x4,x5,[sp],16           // restaur registres
    ldp x2,x3,[sp],16           // restaur registres
    ldp x1,lr,[sp],16           // restaur registres
    ret
/******************************************************************/
/*     Create new node                                            */ 
/******************************************************************/
/* r0 contains the value */
/* r0 return node address or -1 if allocation error*/
createNode:                     // INFO: createNode
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    mov x3,x0                            // save value
    // allocation place on the heap
    mov x0,#NDlist_fin                            // reservation place one element
    bl reserverPlace
    cmp x0,#-1                                  // allocation error
    beq 100f
    str x3,[x0,#NDlist_value]                   // store value
    mov x2,#0
    str x2,[x0,#NDlist_next]                    // store zero to pointer next
    str x2,[x0,#NDlist_prev]                    // store zero to pointer previous
100:
    ldp x2,x3,[sp],16           // restaur registres
    ldp x1,lr,[sp],16           // restaur registres
    ret
/***************************************************/
/*   signature d'un message       */
/***************************************************/
/* x0 contient l'adresse du message  */
/* x1 contient l'adresse du pointeur de la signature */
/* x2 contient l'adresse de la taille de la signature */
/* x3 contient l'adresse de la clé privée   */
signerMessage:                 // INFO: signerMessage
    stp fp,lr,[sp,-16]!        // save  registres
    stp x19,x20,[sp,-16]!      // save  registres
    stp x21,x22,[sp,-16]!      // save  registres
    stp x23,x24,[sp,-16]!      // save  registres
    sub sp,sp,16               // reserver place sur la pile
    mov fp,sp
    //afficherLib signerMessage
    mov x19,x0                 // adresse message
    mov x23,x1                 // pointeur signature
    mov x24,x2                 // adresse longueur signature 
    mov x22,x3                 // adresse clé privée 
    ldr x0,[x1]
    cbz x0,1f
    mov x1,4              // ????
    mov x2,113
    bl  CRYPTO_free
1:
    bl EVP_MD_CTX_new
    cbz x0,99f
    mov x20,x0            // contexte
    
    ldr x0,qAdrszTypeSHA256
    bl EVP_get_digestbyname
    cbz x0,99f
    mov x21,x0            //md ???
    mov x0,x20            // contexte
    mov x1,x21           // md
    mov x2,0
    bl EVP_DigestInit_ex
    cmp x0,1
    bne 99f
    mov x0,x20            // contexte
    mov x1,0
    mov x2,x21           // md
    mov x3,0
    ldr x22,[x22]
    mov x4,x22           // clé privée
    bl EVP_DigestSignInit
    cmp x0,1
    bne 99f
    mov x2,0              // longueur message
2:                        // calcul longueur du message 
    ldrb w3,[x19,x2]
    cbz  w3,3f
    add x2,x2,1
    b 2b
3:
    mov x0,x20            // contexte
    mov x1,x19            // adresse message
    bl EVP_DigestUpdate
    cmp x0,1
    bne 99f
    mov x0,x20            // contexte
    mov x1,0
    str xzr,[x24]           // raz taille
    mov x2,x24            // et adresse passée à la fonction
    bl EVP_DigestSignFinal
    cmp x0,1
    bne 99f
    ldr x0,[x24]               
    cbnz x0,4f
    afficherLib "\033[31msignature NON OK\033[0m"
    mov x0,-1
    b 100f
4:
    str x0,[fp]               // stocke la taille de la signature sur la pile
    mov x2,171
    mov x1,10                 // ?????
    bl CRYPTO_malloc
    cbz x0,99f
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
    affregtit "\033[31mErreur longueur différente\033[0m" 0
    mov x0,-1
    b 100f
5:
    //affregtit "signature OK" 0
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
    ldp x23,x24,[sp],16           // restaur  registres
    ldp x21,x22,[sp],16           // restaur  registres
    ldp x19,x20,[sp],16           // restaur  registres
    ldp fp,lr,[sp],16             // restaur registres
    ret
qAdrszTypeSHA256:       .quad szTypeSHA256

/***************************************************/
/*   verifier la signature d'un message        */
/***************************************************/
/* x0 contient l'adresse du message  */
/* x1 contient l'adresse du pointeur de la signature */
/* x2 contient l'adresse de la longueur de la signature */
/* x3 contient l'adresse de la clé publique   */
verifierSignature:               // INFO: verifierSignature
    stp x1,lr,[sp,-16]!         // save  registres
    stp x19,x20,[sp,-16]!         // save  registres
    stp x21,x22,[sp,-16]!         // save  registres
    stp x23,x24,[sp,-16]!         // save  registres
    mov x19,x0
    mov x22,x3
    mov x23,x1
    mov x24,x2
    bl EVP_MD_CTX_new
    cbz x0,99f
   // affregtit contexte 0
    mov x20,x0            // contexte
    ldr x0,qAdrszTypeSHA256
    bl EVP_get_digestbyname
    cbz x0,99f
    mov x21,x0            //md ???
    mov x0,x20            // contexte
    mov x1,x21           // md
    mov x2,0
    bl EVP_DigestInit_ex
    cmp x0,1
    bne 99f
   // affregtit avantetiq2 0
    mov x0,x20            // contexte
    mov x1,0
    mov x2,x21           // md
    mov x3,0
    ldr x4,[x22]           // clé publique
    ldr x4,[x4]
    bl EVP_DigestVerifyInit
    cmp x0,1
    bne 99f
    mov x2,0              // longueur message
2:                        // calcul longueur du message 
    ldrb w3,[x19,x2]
    cbz  w3,3f
    add x2,x2,1
    b 2b
3:
    mov x0,x20            // contexte
    mov x1,x19            // adresse message
    bl EVP_DigestUpdate
    cmp x0,1
    bne 99f
    bl ERR_clear_error    // nettoyage erreur
    mov x0,x20            // contexte
    ldr x1,[x23]            // pointeur signature
    ldr x2,[x24]          // longueur signature
    bl EVP_DigestVerifyFinal
    cmp x0,1
    bne 99f
    //afficherLib "verification OK"
    mov x0,x20            // contexte
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
/******************************************************************/
/* x0 contains the address of the list */
/* x1 contains the value of element  */
/* x0 returns address of element or - 1 if error */
insertElement:                     // INFO: insertElement
    stp x1,lr,[sp,-16]!                   // save  registers
    stp x2,x3,[sp,-16]!                   // save  registers
    mov x2,x0
    mov x0,16
    bl reserverPlace
    cmp x0,-1
    beq 100f
    str xzr,[x0,llist_next]
    str x1,[x0,llist_value]
    ldr x1,[x2]
    cmp x1,0                             // liste vide ?
    bne 1f
    str x0,[x2]                          // oui -> stockage
    b 100f
1:
    mov x2,x1
2:                                        // boucle de recherche fin liste
    ldr x1,[x2,#llist_next]               // charge l'element suivant
    cmp x1,#0                             // = zero
    csel  x2,x1,x2,ne                     // si <>0 on met x1 dans x2 sinon on laisse x2
    bne 2b                                // si <>0 boucle
    str x0,[x2,#llist_next]               // sinon on stocke l'adresse reservée du tas dans le pointeur précédent.
100:
    ldp x2,x3,[sp],16                     // restaur  2 registers
    ldp x1,lr,[sp],16                     // restaur  2 registers
    ret                                   // return to address lr x30
/***************************************************/
/*     init hashMap               */
/***************************************************/
// x0 contains address to hashMap
hashInit:                       // INFO: hashInit
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    str xzr,[x0,#hash_count]      // init counter
    mov x1,#0
    add x0,x0,#hash_key         // start zone key/value
1:
    lsl x2,x1,#3                // initialisation des zones
    add x2,x2,x0
    str xzr,[x2,#hash_key]
    str xzr,[x2,#hash_data]
    add x1,x1,#1
    cmp x1,#MAXI
    blt 1b
100:
    ldp x2,x3,[sp],16         // restaur des  2 registres
    ldp x1,lr,[sp],16         // restaur des  2 registres
    ret
/***************************************************/
/*     insert key/datas               */
/***************************************************/
// x0 contains address to hashMap
// x1 contains address to key
// x2 contains address to datas
hashInsert:                     // INFO: hashInsert
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x4,x5,[sp,-16]!         // save  registres
    stp x6,x7,[sp,-16]!         // save  registres
    mov x6,x0                   // save address 
    //affmemtit hashinsertKey  x1 3
    bl hashIndex                // search void key or identical key
    cmp x0,#0                   // error ?
    blt 100f
    //affregtit indexInsert 0 
    mov x7,x0                   // save index
    mov x0,TAILLEHASH           // taille hash
    bl reserverPlace
    cmp x0,0
    ble 99f
    mov x3,x0
    lsl x7,x7,#3               // 8 bytes
    add x5,x6,#hash_key        // start zone key/value
    ldr x4,[x5,x7]
    cmp x4,#0                  // key already stored ?
    bne 1f
    ldr x4,[x6,#hash_count]    // no -> increment counter
    add x4,x4,#1
    cmp x4,#(MAXI * COEFF / 100)
    bge 98f
    str x4,[x6,#hash_count]
1:
    str x3,[x5,x7]            // store heap key address in hashmap
    mov x4,#0
2:                            // copy key loop in heap
    ldrb w5,[x1,x4]
    strb w5,[x3,x4]
    add x4,x4,#1
    cmp x4,TAILLEHASH
    blt 2b

    mov x0,sortieTx_fin
    bl reserverPlace
    cmp x0,0
    ble 99f
    add x1,x6,#hash_data
    str x0,[x1,x7]           // store heap data address in hashmap
    mov x4,#0
3:                            // copy data loop in heap
    ldrb w5,[x2,x4]
    strb w5,[x0,x4]
    add x4,x4,#1
    cmp x4,sortieTx_fin
    blt 3b
    
    mov x0,#0                 // insertion OK
    b 100f
98:                           // error hashmap
    adr x0,szMessErrInd
    bl afficherMessage
    mov x0,#-1
    b 100f
99:                           // error heap
    adr x0,szMessErrHeap
    bl afficherMessage
    mov x0,#-1
100:
    ldp x6,x7,[sp],16         // restaur des  2 registres
    ldp x4,x5,[sp],16         // restaur des  2 registres
    ldp x2,x3,[sp],16         // restaur des  2 registres
    ldp x1,lr,[sp],16         // restaur des  2 registres
    ret
szMessErrInd:          .asciz "\033[31mError : HashMap size Filling rate Maxi !!\033[0m\n"
szMessErrHeap:         .asciz "\033[31mError : Heap size  Maxi !!\033[0m\n"
.align 4
/***************************************************/
/*     search void index in hashmap              */
/***************************************************/
// x0 contains hashMap address 
// x1 contains key address
hashIndex:                      // INFO: hashIndex  
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    stp x4,x5,[sp,-16]!         // save  registres
    add x4,x0,#hash_key
    //affmemtit hashindex x1 3
    mov x2,#0             // index
    mov x3,#0             // characters sum 
1:                        // loop to compute characters sum 
    ldrb w0,[x1,x2]
    cmp w0,#0             // string end ?
    beq 2f
    add x3,x3,x0          // add to sum
    add x2,x2,#1
    cmp x2,#LIMIT
    blt 1b
2:
    mov x5,x1             // save key address
    mov x0,x3
    mov x1,#MAXI
    udiv x2,x0,x1
    msub x3,x2,x1,x0      // compute remainder -> x3
    mov x1,x5             // key address
    
3:
    ldr x0,[x4,x3,lsl #3] // load key for computed index 
    //affregtit recherche 0
    cmp x0,#0             // void key ?
    beq 4f 
    //affmemtit compar x0 4
    bl comparerHash      // identical key ?
    cmp x0,#0
    beq 4f                // yes
    add x3,x3,#1          // no search next void key
    cmp x3,#MAXI          // maxi ?
    csel x3,xzr,x3,ge     // restart to index 0
    b 3b
4:
    mov x0,x3             // return index void array or key equal
    //affregtit index 0
100:
    ldp x4,x5,[sp],16         // restaur des  2 registres
    ldp x2,x3,[sp],16         // restaur des  2 registres
    ldp x1,lr,[sp],16         // restaur des  2 registres
    ret

/***************************************************/
/*     search key in hashmap              */
/***************************************************/
// x0 contains hash map address
// x1 contains key address
searchKey:                      // INFO: searchKey
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    mov x2,x0
    bl hashIndex
    lsl x0,x0,#3
    add x1,x0,#hash_key
    ldr x1,[x2,x1]
    cmp x1,#0
    beq 2f
    add x1,x0,#hash_data
    ldr x0,[x2,x1]
    b 100f
2:
    mov x0,#-1
100:
    ldp x2,x3,[sp],16         // restaur des  2 registres
    ldp x1,lr,[sp],16         // restaur des  2 registres
    ret
/***************************************************/
/*     remove key in hashmap              */
/***************************************************/
// x0 contains hash map address
// x1 contains key address
removeKey:                      // INFO: removeKey
    stp x1,lr,[sp,-16]!         // save  registres
    stp x2,x3,[sp,-16]!         // save  registres
    mov x2,x0
    bl hashIndex
    //affregtit suppression 0
    lsl x0,x0,#3
    add x1,x0,#hash_key
    ldr x3,[x2,x1]
    cbz x3,2f
    add x3,x2,x1
    str xzr,[x3]   
    add x1,x0,#hash_data
    add x3,x2,x1
    str xzr,[x3]
    b 100f
2:
    mov x0,#-1
100:
    ldp x2,x3,[sp],16         // restaur des  2 registres
    ldp x1,lr,[sp],16         // restaur des  2 registres
    ret
/************************************/	   
/* Strings case sensitive comparisons  */
/************************************/	  
/* x0 et x1 contains the address of strings */
/* return 0 in x0 if equals */
/* return -1 if string x0 < string x1 */
/* return 1  if string x0 > string x1 */
comparStrings:           // INFO: comparStrings
    stp x1,lr,[sp,-16]!  // save  registres
    stp x2,x3,[sp,-16]!  // save  registres
    stp x4,x5,[sp,-16]!  // save  registres
    mov x2,#0            // characters counter
1:
    ldrb w3,[x0,x2]      // byte string 1
    ldrb w4,[x1,x2]      // byte string 2
    cmp w3,w4
    blt 2f
    bgt 3f
    cmp w3,#0            // 0 end string ?
    beq 4f
    add x2,x2,#1         // else add 1 in counter
    b 1b                 // and loop
2:
    mov x0,#-1           // smaller
    b 100f
3:
    mov x0,#1            // greather
    b 100f
4:
    mov x0,#0           // equals
100:  
    ldp x4,x5,[sp],16   // restaur des  2 registres
    ldp x2,x3,[sp],16   // restaur des  2 registres
    ldp x1,lr,[sp],16   // restaur des  2 registres
    ret
    