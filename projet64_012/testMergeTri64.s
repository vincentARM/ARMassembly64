/* Programme assembleur ARM Raspberry */
/* Assembleur 64 bits ARM Raspberry  : Vincent Leboulou */
/* modèle 3B+ 1GO Système LINUX 64 Bits Buster  voir github Sakaki */
/*  */
/* test de tris asm 64 bits d'une table avec une seule valeur numèrique */

/************************************/
/* Constantes                       */
/************************************/
.include "../constantesARM64.inc"
.equ MAXI, 100000    /* Nombre de nombre aléatoires */
.equ PLAGE, 980
.equ TAILLEBUFFER, 100
.equ CPTAFFICHER,   10
//.equ GETTIME,         113       //clock_gettime

.equ IOCTL,     0x1D                // Linux syscall
.equ READ,      0x3F
.equ PERF_EVENT_IOC_ENABLE,  0x2400      // codes commande ioctl
.equ PERF_EVENT_IOC_DISABLE, 0x2401
.equ PERF_EVENT_IOC_RESET,   0x2403

.equ PERF_TYPE_HARDWARE,     0
.equ PERF_TYPE_SOFTWARE,     1
.equ PERF_TYPE_TRACEPOINT,   2
.equ PERF_TYPE_HW_CACHE,     3
.equ PERF_TYPE_RAW,          4
.equ PERF_TYPE_BREAKPOINT,   5

.equ PERF_COUNT_HW_CPU_CYCLES,              0
.equ PERF_COUNT_HW_INSTRUCTIONS,            1
.equ PERF_COUNT_HW_CACHE_REFERENCES,        2
.equ PERF_COUNT_HW_CACHE_MISSES,            3
.equ PERF_COUNT_HW_BRANCH_INSTRUCTIONS,     4
.equ PERF_COUNT_HW_BRANCH_MISSES,           5
.equ PERF_COUNT_HW_BUS_CYCLES,              6
.equ PERF_COUNT_HW_STALLED_CYCLES_FRONTEND, 7
.equ PERF_COUNT_HW_STALLED_CYCLES_BACKEND,  8
.equ PERF_COUNT_HW_REF_CPU_CYCLES,          9

.equ PERF_COUNT_SW_CPU_CLOCK,          0
.equ PERF_COUNT_SW_TASK_CLOCK,         1
.equ PERF_COUNT_SW_PAGE_FAULTS,        2
.equ PERF_COUNT_SW_CONTEXT_SWITCHES,   3
.equ PERF_COUNT_SW_CPU_MIGRATIONS,     4
.equ PERF_COUNT_SW_PAGE_FAULTS_MIN,    5
.equ PERF_COUNT_SW_PAGE_FAULTS_MAJ,    6
.equ PERF_COUNT_SW_ALIGNMENT_FAULTS,   7
.equ PERF_COUNT_SW_EMULATION_FAULTS,   8
.equ PERF_COUNT_SW_DUMMY,              9
.equ PERF_COUNT_SW_BPF_OUTPUT,         10

.equ  PERF_FLAG_FD_NO_GROUP,    1 << 0
.equ PERF_FLAG_FD_OUTPUT,       1 << 1
.equ PERF_FLAG_PID_CGROUP,      1 << 2 /* pid=cgroup id, per-cpu mode only */
.equ PERF_FLAG_FD_CLOEXEC,      1 << 3  /* O_CLOEXEC >*/

.equ PERF_FORMAT_TOTAL_TIME_ENABLED,    1 << 0
.equ PERF_FORMAT_TOTAL_TIME_RUNNING,    1 << 1
.equ PERF_FORMAT_ID,                    1 << 2
.equ PERF_FORMAT_GROUP,                 1 << 3
/*******************************************/
/* structure de type perf_event_attr  */
/*******************************************/
    .struct  0
perf_event_type:                           // type
    .struct  perf_event_type + 4
perf_event_size:                           // taille
    .struct  perf_event_size + 4
perf_event_config:                         // configuration
    .struct  perf_event_config + 8
perf_event_sample_period:                  // ou sample_freq
    .struct  perf_event_sample_period + 8
perf_event_sample_type:                    // type
    .struct  perf_event_sample_type + 8
perf_event_read_format:                    // read format 
    .struct  perf_event_read_format + 8
perf_event_param:                          //  32 premiers bits voir la documentation
    .struct  perf_event_param + 8          // bit disabled inherit pinned exclusive 
                                           // exclude_user exclude_kernel exclude_hv exclude_idle etc 
perf_event_suite:
    .struct  perf_event_suite + 100         // voir documentation 
perf_event_fin:

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
/*********************************/
/* Initialized data              */
/*********************************/
.data
szMessDebutPgm:          .asciz "Début programme.\n"
.equ LGMESSDEBUT,        . - szMessDebutPgm
szMessFinPgm:            .asciz "Fin ok du programme.\n"
.equ LGMESSFIN,          . - szMessFinPgm
szRetourLigne:           .asciz "\n"
.equ LGRETLIGNE,         . - szRetourLigne
szMessErreur:            .asciz "Erreur rencontrée.\n"
sMessResult:             .asciz "instructions: @ Cycles: @ temps en µs: @ temps1: @ \n"
sMessResult1:            .asciz "Valeur : @ \n"

.align 4
qGraine:  .quad 1234567
/*********************************/
/* UnInitialized data            */
/*********************************/
.bss
.align 4
sZoneConv:          .skip 24
qTabOrigine:        .skip 8 * MAXI    // table de stockage des nombres
qTabNB:             .skip 8 * MAXI    // table de stockage des nombres
//iZeroes:            .skip 32
//qwDebut:    .skip 16
//qwFin:      .skip 16
sBuffer:            .skip TAILLEBUFFER
stPerf:     .skip perf_event_fin        // structure infos leader
stPerf1:    .skip perf_event_fin        // structure infos fils 1
stPerf2:    .skip perf_event_fin        // structure infos fils 2
stPerf3:    .skip perf_event_fin        // structure infos fils 3
 // chaque zone du buffer  a une longueur de 64 bits 
 // la première zone contient le nombre de compteurs lus (ici 3)
 
TableExtraSort:  .skip 8 * MAXI         // table annexe utilisée par des tris fusion
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                            // entry of program 
    ldr x0,qAdrszMessDebutPgm
    mov x1,LGMESSDEBUT
    bl affichageMessSP
    /* constitution du tableau nombres aléatoires   */
    mov x1,#0               //  compteur
    ldr x2,qAdrqTabOrigine
    ldr x3,qMaxi
1:                         // debut de boucle 
    ldr x0,qPlage          // génération nombre compris entre 0 et PLAGE - 1
    sub x0,x0,#1
    bl genererAlea
    str x0,[x2,x1,LSL #3]  // stockage dans la table au poste indexé par r1
    add x1,x1,#1           // compteur + 1
    cmp x1,x3              // géneration de MAXI nombres 
    blt 1b                 // boucle


    affichelib triShell1   // tri de controle
    adr x0,triShell1
    bl preparationTri
    affichelib mergeSort1
    adr x0,mergeSort1
    bl preparationTri
    affichelib mergeSort
    adr x0,mergeSort
    bl preparationTri
    affichelib mergeIteratif
    adr x0,mergeSortIter
    bl preparationTri
    affichelib mergeIteratifA
    adr x0,mergeSortIterA
    bl preparationTri
    
100:                            // fin standard du programme
    ldr x0,qAdrszMessFinPgm     // message de fin
    mov x1,LGMESSFIN
    bl affichageMessSP
    mov x0,0                    // code retour
    mov x8,EXIT                 // system call "Exit"
    svc #0
qMaxi:                   .quad MAXI
qPlage:                  .quad PLAGE
qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessFinPgm:        .quad szMessFinPgm
qAdrszRetourLigne:       .quad szRetourLigne
qAdrqTabOrigine:         .quad qTabOrigine
qAdrqTabNB:              .quad qTabNB
qAdrTableExtraSort:      .quad TableExtraSort

/***************************************************/
/*   Préparationd'un tri                           */
/***************************************************/
/* r0 adresse de la routine de tri  */
preparationTri:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    mov x23,x0
    /* recopie de la table d'origine vers la table à  trier */
    bl recopieTable
    /* verif table avant tri */
    ldr x0,qAdrqTabNB
    bl afficherTable


    /* compteur temps debut */
    
    ldr x0,qAdrstPerf                   // préparation données du leader
    mov w1,#PERF_TYPE_HARDWARE          // type de compteur
    str w1,[x0,#perf_event_type]
    mov w1,#112                         // longueur de la structure
    str w1,[x0,#perf_event_size]
    mov w1,#0b01100001                  // bit disabled(1) exclude_kernel exclude_hv
    //mov w1,0
    str w1,[x0,#perf_event_param]       // dans les 8 premiers bits de param
    mov x1,#PERF_COUNT_HW_INSTRUCTIONS  // compteur instructions
    //mov x1,#PERF_COUNT_HW_CPU_CYCLES
    str x1,[x0,#perf_event_config]
    //mov x1,#0
    //mov x1,#PERF_FORMAT_GROUP|PERF_FORMAT_TOTAL_TIME_RUNNING   // lecture commune de tous les compteurs
    mov x1,#PERF_FORMAT_GROUP|PERF_FORMAT_TOTAL_TIME_ENABLED
    str x1,[x0,#perf_event_read_format]
    ldr x0,qAdrstPerf
    //affmemtit buffer x0 4
    mov x1,#0                           // pid
    mov x2,#-1                          // cpu 0
    mov x3,#-1                          // c'est le leader
    mov x4,#0                           // flags
    mov x8,#241                        // call system perf_event_open   leader
    svc 0 
    cmp x0,#0
    ble 99f                             // erreur ?
    mov x19,x0                          // save FD du leader
    //***********************Fils 1
    ldr x0,qAdrstPerf1
    mov w1,#PERF_TYPE_HARDWARE
    str w1,[x0,#perf_event_type]
    mov w1,#112
    str w1,[x0,#perf_event_size]
    mov w1,#0b01100000                  // bit disabled(0) exclude_kernel exclude_hv
    str x1,[x0,#perf_event_param]       // dans les 8 premiers bits de param
    //mov x1,#PERF_COUNT_HW_INSTRUCTIONS
    mov x1,#PERF_COUNT_HW_CPU_CYCLES
    str x1,[x0,#perf_event_config]
    mov x1,#0                           // pid
    mov x2,#-1                           // tout cpu 
    mov x3,x19                           // 
    mov x4,#0
    mov x8, #241                        // call system perf_event_open   fils
    svc 0 
    cmp x0,#0
    ble 99f
    mov x20,x0                         // eventuellement save du FD du fils
    //***********************Fils 2
    ldr x0,qAdrstPerf2
    //mov x1,#PERF_TYPE_HARDWARE
    mov x1,#PERF_TYPE_SOFTWARE
    str x1,[x0,#perf_event_type]
    mov x1,#112
    str x1,[x0,#perf_event_size]
    mov x1,#0b01100000                  // bit disabled(0) exclude_kernel exclude_hv
    str x1,[x0,#perf_event_param]       // dans les 8 premiers bits de param
    //mov x1,#PERF_COUNT_HW_INSTRUCTIONS
    //mov x1,#PERF_COUNT_HW_CPU_CYCLES
    //mov x1,#PERF_COUNT_SW_TASK_CLOCK
    mov x1,#PERF_COUNT_SW_CPU_CLOCK  
    str x1,[x0,#perf_event_config]
    mov x1,#0                           // pid
    mov x2,#-1                           // cpu 2
    mov x3,x19                           // FD
    mov x4,#0
    mov x8, #241                        // call system perf_event_open   fils 2
    svc 0 
    cmp x0,#0
    ble 99f
    mov x21,x0             // save eventuelle du FD fils 2

    /****************************************/
    // lancement des mesures
    //vidregtit mesure
    mov x0,x19                    // FD du leader 
    mov x1,#PERF_EVENT_IOC_RESET
    mov x2,#0
    mov x8, #IOCTL               // appel systeme 
    svc #0 
    cmp x0,#0
    blt 99f
    mov x0,x19                    // FD du leader
    mov x1,#PERF_EVENT_IOC_ENABLE
    mov x2,#0
    mov x8, #IOCTL               // appel systeme 
    svc #0 
    cmp x0,#0
    blt 99f
    

    /*  tri de la table */ 
    ldr x0,qAdrqTabNB
    mov x1,#0          // poste minimun  ATTENTION HARMONISATION DES TRIS A FAIRE
    ldr x2,qMaxi       // Nombre d'elements à trier
    ldr x3,qAdrTableExtraSort    // pour merge Sort
    blr x23
    
    
    
    /* compteur temps fin */
    /*********************************************/
    // fin mesure
    mov x0,x19                       // FD
    mov x1,#PERF_EVENT_IOC_DISABLE
    mov x2,#0
    mov x8, #IOCTL                   // appel systeme 
    svc #0 
    cmp x0,#0
    blt 99f

    // lecture des compteurs
    mov x0,x19                   // FD
    ldr x1,qAdrsBuffer          // un seul buffer 
    mov x2,#48                  // TODO a revoir double !!!
    mov x8, #READ               // appel systeme 
    svc #0 
    cmp x0,#0
    blt 99f
    // affichage des résultats 
    ldr x0,qAdrsBuffer 
    ldr x0,[x0,16]             // recuperation du nombre d'instructions
    ldr x1,qAdrsZoneConv
    bl conversion10
    ldr x1,qAdrsZoneConv
    ldr x0,qAdrsMessResult
    bl strInsertAtChar
    mov x5,x0
    ldr x0,qAdrsBuffer
    ldr x0,[x0,24]             // recuperation du nombre de cycles
    ldr x1,qAdrsZoneConv
    bl conversion10
    mov x0,x5
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    mov x5,x0

    ldr x0,qAdrsBuffer
    ldr x0,[x0,8]              // recuperation du temps
    ldr x1,qAdrsZoneConv
    bl conversion10
    mov x0,x5
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    mov x5,x0

    ldr x0,qAdrsBuffer
    ldr x0,[x0,32]             // recuperation du temps 2
    ldr x1,qAdrsZoneConv       // PERF_COUNT_SW_TASK_CLOCK
    bl conversion10
    mov x0,x5
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar
    bl affichageMess

    
    /* verification visuelle du tri */
    afficheLib Findutri__tabledébut
    ldr x0,qAdrqTabNB
    bl afficherTable
    afficheLib Findutri__tablefin
    ldr x0,qAdrqTabNB
    ldr x1,qMaxi
    sub x1,x1,10
    lsl x1,x1,3
    add x0,x0,x1
    bl afficherTable
    /* verification du tri */
    mov x1,#0  //  compteur
    ldr x2,qAdrqTabNB
    ldr x4,qMaxi
    ldr x0,[x2,x1,LSL #3]   // init avec la première valeur
2:    
    ldr x3,[x2,x1,LSL #3]   // chargement valeur de l'indice x1
    cmp x3,x0               // comparaison avec valeur précedente
    blt 3f                  // si inférieure il y a une erreur 
    mov x0,x3               // sinon conservation de la valeur
    add x1,x1,#1            // ajout de 1 au compteur
    cmp x1,x4               // Nombre de postes atteint ?
    blt 2b                  // non on boucle
    b 100f
3:
    affregtit erreurtri 0
    ldr x1,qAdrszMessErreur   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheErreur   /*appel affichage message  */        
    b 100f
99:                             // affichage erreur 
    ldr x1,qAdrszMessErreur     // x0 <- code erreur, x1 <- adresse chaine 
    bl   afficheErreur          // appel affichage message
    mov x0,#1                   // code erreur 
    b 100f
100:
    ldp x3,x4,[sp],16          // restaur des  2 registres
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdrszMessErreur:            .quad szMessErreur
qAdrsBuffer:             .quad sBuffer
qAdrstPerf:              .quad stPerf
qAdrstPerf1:             .quad stPerf1
qAdrstPerf2:             .quad stPerf2
qAdrstPerf3:             .quad stPerf3
qAdrsMessResult:         .quad sMessResult
qAdrsZoneConv:           .quad sZoneConv
/***************************************************/
/*  recopie table origine table à  trier               */
/***************************************************/
recopieTable:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres
    stp x3,x4,[sp,-16]!        // save  registres
    /* recopie de la table d'origine vers la table à  trier */
    mov x1,#0                 //  compteur
    ldr x2,qAdrqTabOrigine
    ldr x3,qMaxi
    ldr x4,qAdrqTabNB
1:
    ldr x0,[x2,x1,lsl #3]
    str x0,[x4,x1,lsl #3]
    add x1,x1,#1
    cmp x1,x3                // recopie poste 0 à maxi
    blt 1b
100:                         // fin standard  de la fonction
    ldp x3,x4,[sp],16        // restaur des  2 registres
    ldp x1,x2,[sp],16        // restaur des  2 registres
    ldp x0,lr,[sp],16        // restaur des  2 registres
    ret                      // retour adresse lr x30  
/******************************************************************/
/*      afficher la table de valeurs                              */ 
/******************************************************************/
/* x0 contains the address of table */
afficherTable:                  // INFO: affichageTable
    stp x1,lr,[sp,-16]!          // save  registers
    stp x2,x3,[sp,-16]!          // save  registers
    stp x4,x5,[sp,-16]!          // save  registers
    stp x6,x7,[sp,-16]!          // save  registers
    mov x2,x0                    // table address
    mov x3,0
1:                               // loop display table

    ldr x0,[x2,x3,lsl 3]               // load pointer
    ldr x1,qAdrsZoneConv
    bl conversion10
    ldr x0,qAdrsMessResult1
    ldr x1,qAdrsZoneConv
    bl strInsertAtChar        // put name in message
    bl affichageMess             // display message
    add x3,x3,1
    cmp x3,CPTAFFICHER
    blt 1b
    ldr x0,qAdrszRetourLigne
    bl affichageMess
100:
    ldp x6,x7,[sp],16            // restaur  2 registers
    ldp x4,x5,[sp],16            // restaur  2 registers
    ldp x2,x3,[sp],16            // restaur  2 registers
    ldp x1,lr,[sp],16            // restaur  2 registers
    ret                          // return to address lr x30
qAdrsMessResult1:         .quad sMessResult1
/***************************************************/
/*   Initialisation de la graine                   */
/***************************************************/
/* x0 contient une valeur initiale */
gen_init:         // fonction
    stp x1,lr,[sp,-16]!        // save  registres
    ldr x1,qAdriGraine
    str x0,[x1]
100:                           // fin standard de la fonction
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30
qAdriGraine:      .quad qGraine
/***************************************************/
/*   génération d'un nombre aléatoire              */
/***************************************************/
/* x0 contient la borne superieure */
genererAlea:         // fonction
    stp x1,lr,[sp,-16]!        // save  registres
    stp x2,x3,[sp,-16]!        // save  registres
    mov x3,x0           // valeur maxi
    ldr x0,qAdriGraine  // graine
    ldr x2,qVal1 
    ldr x1,[x0]         // charger la graine
    mul x1,x2,x1
    ldr x2,qVal2
    add x1,x1,x2
    str x1,[x0]      // sauver graine
    udiv x2,x1,x3       // 
    msub x0,x2,x3,x1    // calcul resultat modulo plage

100:                    // fin standard de la fonction
    ldp x2,x3,[sp],16          // restaur des  2 registres
    ldp x1,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

qVal1:         .quad 0x0019660d   //0x343FD
qVal2:         .quad 0x3c6ef35f //0x269EC3

/***************************************************/
/*   Tri shell avec debut de plage  >= zéro               */
/***************************************************/
/* x0  pointeur vers table à trier */
/* x1  premier poste     */
/* x2  nombre maxi     */
triShell1:
    stp x0,lr,[sp,-16]!        // save  registres
    stp x1,x2,[sp,-16]!        // save  registres

    sub x2,x2,#1              // pas = N -1 
    mov x8,x2                 // save poste maxi
1:
    lsr x2,x2,#1            // pas = pas / 2
    cbz x2,5f               // si pas = 0 alors fin
    mov x3,x2               // i 
    add x3,x3,x1            // ajout premier poste
2:
    ldr x4,[x0,x3,lsl #3]   // v
    mov x5,x3               // j
3:  
    add x7,x2,x1
    cmp x5,x7
    blt 4f
    sub x6,x5,x2              // j - pas
    ldr x7,[x0,x6,lsl #3]
    cmp x4,x7
    bge 4f
    str x7,[x0,x5,lsl #3]
    sub x5,x5,x2              // j = j - pas
    b 3b
4:
    str x4,[x0,x5,lsl #3]
    add x3,x3,#1
    cmp x3,x8                 // poste maxi ?
    ble 2b                    // non -> boucle 1
    b 1b                      // oui -> boucle nouveau pas
5:
100:
    ldp x1,x2,[sp],16          // restaur des  2 registres
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                        // retour adresse lr x30

/******************************************************************/
/*      merge sort                                                */ 
/* algorithme de Sedgewick page 176 */
/******************************************************************/
/* x0 contains the address of table */
/* x1 contains the index of first element */
/* x2 contains the number of element */
/* x3 contains address extra area */
mergeSort:
    stp x3,lr,[sp,-16]!    // save  registers
    stp x4,x5,[sp,-16]!    // save  registers
    stp x6,x7,[sp,-16]!    // save  registers
    stp x8,x9,[sp,-16]!    // save  registers
    stp x10,x11,[sp,-16]!    // save  registers
    mov x5,x3
    mov x6,x1              // save index first element
    sub x7,x2,1           // compute last element
    mov x11,x0             // save address table 
    //affregtit debsort 0
    cmp x7,x1               // end ?
    ble 100f
    add x9,x7,x1
    lsr x9,x9,1            // number of element of each subset
    add x2,x9,1            
    bl mergeSort
    mov x1,x9              // restaur number of element of each subset
    add x1,x1,1
    add x2,x7,1            // restaur  number of element
    bl mergeSort           // sort first subset
    add x10,x9,1
1:
    sub x1,x10,1
    sub x8,x10,1
    ldr x2,[x0,x1,lsl 3]
    str x2,[x5,x8,lsl 3]
    sub x10,x10,1
    cmp x10,x6
    bgt 1b
    mov x10,x9
2:
    add x1,x10,1
    add x8,x7,x9
    sub x8,x8,x10
    ldr x2,[x0,x1,lsl 3]
    str x2,[x5,x8,lsl 3]
    add x10,x10,1
    cmp x10,x7
    blt 2b

    mov x10,x6            //k
    mov x1,x6             // i
    mov x2,x7             // j
3:
    mov x0,x5             // table address x1 = i x2 = j x3 = area sort offeset
    ldr x6,[x5,x1,lsl 3]
    ldr x8,[x5,x2,lsl 3]
    cmp x6,x8
    //cmp x0,0
    bgt 5f
    blt 4f
                          // if equal and  i < pivot 
    cmp x1,x9
    ble 4f                // inverse to stable
    b 5f
4:
    mov x0,x5
    ldr x6,[x5,x1, lsl 3]
    str x6,[x11,x10, lsl 3]
    add x1,x1,1
    b 6f
5:
    mov x0,x5
    ldr x6,[x5,x2, lsl 3]
    str x6,[x11,x10, lsl 3]
    sub x2,x2,1
6:
    add x10,x10,1
    cmp x10,x7
    ble 3b
    mov x0,x11

100:
    ldp x10,x11,[sp],16         // restaur  2 registers
    ldp x8,x9,[sp],16          // restaur  2 registers
    ldp x6,x7,[sp],16          // restaur  2 registers
    ldp x4,x5,[sp],16          // restaur  2 registers
    ldp x3,lr,[sp],16          // restaur  2 registers
    ret                        // return to address lr x30
/******************************************************************/
/*      comparison sort area                                */ 
/******************************************************************/
/* x0 contains the address of table */
/* x1 indice area sort 1 */
/* x2 indice area sort 2 */
/* x3 contains the offset of area sort */
/* x4 contains the type of area sort N numeric A alpha */
comparArea:
    stp x1,lr,[sp,-16]!          // save  registers
    stp x2,x3,[sp,-16]!          // save  registers
    stp x4,x5,[sp,-16]!          // save  registers
    stp x6,x7,[sp,-16]!          // save  registers
    stp x8,x9,[sp,-16]!          // save  registers
    
    ldr x1,[x0,x1,lsl 3]         // load pointer element 1
    ldr x6,[x1,x3]               // load area sort element 1
    ldr x2,[x0,x2,lsl 3]         // load pointer element 2
    ldr x7,[x2,x3]               // load area sort element 2
    //affregtit debcompar 0
    //affregtit debcompar 6
    cmp x4,'A'                   // numeric or alpha ?
    beq 1f
    cmp x6,x7                    // compare numeric value
    blt 10f
    bgt 11f
    b 12f
1:                               // else compar alpha string
    mov x8,#0
2:
    ldrb w9,[x6,x8]              // byte string 1
    ldrb w5,[x7,x8]              // byte string 2
    cmp w9,w5
    bgt 11f                     
    blt 10f

    cmp w9,#0                    //  end string 1
    beq 12f                      // end comparaison
    add x8,x8,#1                 // else add 1 in counter
    b 2b                         // and loop
    
10:                              // lower
    mov x0,-1
    b 100f
11:                              // highter
    mov x0,1
    b 100f
12:                              // equal
    mov x0,0
100:
    ldp x8,x9,[sp],16            // restaur  2 registers
    ldp x6,x7,[sp],16            // restaur  2 registers
    ldp x4,x5,[sp],16            // restaur  2 registers
    ldp x2,x3,[sp],16            // restaur  2 registers
    ldp x1,lr,[sp],16            // restaur  2 registers
    ret                          // return to address lr x30
/******************************************************************/
/*         merge                                              */ 
/******************************************************************/
/* x0 contains the address of table */
/* x1 contains first start index
/* x2 contains second start index */
/* x3 contains the last index   */ 

merge:
    stp x1,lr,[sp,-16]!        // save  registers
    stp x2,x3,[sp,-16]!        // save  registers
    stp x4,x5,[sp,-16]!        // save  registers
    stp x6,x7,[sp,-16]!        // save  registers
    stp x8,x9,[sp,-16]!
    mov x9,x2                  // init index 
1:                             // begin loop first sectionx1
    ldr x6,[x0,x1,lsl 3]
    ldr x7,[x0,x9,lsl 3]       // load value second section index r5
    cmp x6,x7
    ble 8f                     // <=  -> location first section OK
    str x7,[x0,x1, lsl 3]
    add x8,x9,1
    cmp x8,x3                  // end second section ?
    ble 2f
    str x6,[x0,x9,lsl 3]
    b 8f                       // loop
2:                             // loop insert element part 1 into part 2
    sub x5,x8,1
    ldr x7,[x0,x8,lsl 3]       // load value 2

    cmp x6,x7                  // compare numeric 
    bgt 7f
    str x6,[x0,x5,lsl 3]
    b 8f                       // loop
7:
    str x7,[x0,x5,lsl 3]       // store value 2
    add x8,x8,1
    cmp x8,x3                  // end second section ?
    ble 2b                     // no loop 
    sub x8,x8,1
    str x6,[x0,x8,lsl 3]       // store value 1
8:
    add x1,x1,1
    cmp x1,x2                  // end first section ?
    blt 1b

100:
    ldp x8,x9,[sp],16          // restaur 1 register
    ldp x6,x7,[sp],16          // restaur  2 registers
    ldp x4,x5,[sp],16          // restaur  2 registers
    ldp x2,x3,[sp],16          // restaur  2 registers
    ldp x1,lr,[sp],16          // restaur  2 registers
    ret                        // return to address lr x30
/******************************************************************/
/*      merge sort                                                */ 
/*   alogritme rosetta code */
/******************************************************************/
/* x0 contains the address of table */
/* x1 contains the index of first element */
/* x2 contains the number of element */

mergeSort1:
    stp x3,lr,[sp,-16]!    // save  registers
    stp x4,x5,[sp,-16]!    // save  registers
    stp x6,x7,[sp,-16]!    // save  registers
    stp x8,x9,[sp,-16]!    // save  registers
    mov x9,x3 
    cmp x2,2               // end ?
    blt 100f
    lsr x8,x2,1            // number of element of each subset
    add x5,x8,1
    tst x2,#1              // odd ?
    csel x8,x5,x8,ne
    mov x5,x1              // save first element
    mov x6,x2              // save number of element
    mov x7,x8              // save number of element of each subset
    mov x2,x8
    bl mergeSort1
    mov x1,x7              // restaur number of element of each subset
    mov x2,x6              // restaur  number of element
    sub x2,x2,x1
    mov x9,x5              // restaur first element
    add x1,x1,x9              // + 1
    bl mergeSort1           // sort first subset
    mov x1,x5              // restaur first element
    mov x2,x7              // restaur number of element of each subset
    add x2,x2,x1
    mov x5,x4
    mov x4,x3
    mov x3,x6              // restaur  number of element
    add x3,x3,x1 
    sub x3,x3,1              // last index
    
    bl merge
100:
    ldp x8,x9,[sp],16          // restaur  2 registers
    ldp x6,x7,[sp],16          // restaur  2 registers
    ldp x4,x5,[sp],16          // restaur  2 registers
    ldp x3,lr,[sp],16          // restaur  2 registers
    ret                        // return to address lr x30
/******************************************************************/
/*      merge sort  iteratif                                      */ 
/******************************************************************/
/* x0 contains the address of table */
/* x1 contains the index of first element */
/* x2 contains the number of element */
/* x3 contains address extra area */
mergeSortIter:
    stp x3,lr,[sp,-16]!    // save  registers
    stp x4,x5,[sp,-16]!    // save  registers
    stp x6,x7,[sp,-16]!    // save  registers
    stp x8,x9,[sp,-16]!    // save  registers
    stp x10,x11,[sp,-16]!    // save  registers
    mov x15,x0             // save address
    mov x16,x1              // save N0 first element
    sub x17,x2,1            // save N° last  element
    mov x5,x3              // save address extra table
    //affregtit debsort 0
    mov x10,1              // subset size 
1:
    mov x6,x16              // first element
    //affregtit debut1 6
2:

    lsl x8,x10,1            // compute end subset
    add x8,x8,x6
    sub x8,x8,1
    add x7,x6,x8            // compute median
    //affregtit debut12 6
    lsr x7,x7,1
    cmp x8,x17               // maxi ?
    ble 21f                  // no
    mov x8,x17               // yes -> end subset = maxi
    cmp x6,0                 // subset final ?
    beq 21f                  // no
    cmp x7,x8                // compare median end subset
    blt 21f
    mov x7,x8                // maxi -> median 

21:
    add x9,x7,1
    mov x0,x15
    //affregtit debut2 6
3:
    sub x1,x9,1
    ldr x2,[x0,x1,lsl 3]
    str x2,[x5,x1,lsl 3]
    sub x9,x9,1
    cmp x9,x6
    bgt 3b
    //affregtit boucle1 5
    mov x9,x7
    cmp x7,x8
    beq 41f
4:
    add x1,x9,1
    add x3,x7,x8
    sub x3,x3,x9
    ldr x2,[x0,x1,lsl 3]
    str x2,[x5,x3,lsl 3]
    //affregtit boucle2 0
    add x9,x9,1
    cmp x9,x8
    blt 4b
41:
    //affregtit finboucle2 1

    mov x11,x6  //k
    mov x1,x6  // i
    mov x2,x8  // j
5:
    mov x0,x5
    ldr x3,[x5,x1,lsl 3]
    ldr x4,[x5,x2,lsl 3]
    cmp x3,x4
    bgt 7f
    blt 6f
    // si egalité et si i < pivot 
    cmp x1,x7
    ble 6f
    b 7f
6:
    ldr x12,[x5,x1, lsl 3]
    str x12,[x15,x11, lsl 3]
    add x1,x1,1
    b 8f
7:
    ldr x12,[x5,x2, lsl 3]
    str x12,[x15,x11, lsl 3]
    sub x2,x2,1
8:
    add x11,x11,1
    cmp x11,x8
    ble 5b
    
    //mov x0,x11
    //affichelib fin
    //bl displayTable
    //cmp x11,6
    //bne 9f
    //mov x0,x5
    //affichelib finextra
    //bl displayTable
9:
    mov x0,x15
    lsl x2,x10,1
    add x6,x6,x2
    cmp x6,x17            // end
    ble 2b
    lsl x10,x10,1
    cmp x10,x17
    ble 1b
    
100:
    ldp x10,x11,[sp],16          // restaur  2 registers
    ldp x8,x9,[sp],16          // restaur  2 registers
    ldp x6,x7,[sp],16          // restaur  2 registers
    ldp x4,x5,[sp],16          // restaur  2 registers
    ldp x3,lr,[sp],16          // restaur  2 registers
    ret                        // return to address lr x30
/******************************************************************/
/*      merge sort itératif                                        */ 
/* avec amélioration pour le passage 1 sans copie sur la table annexe */
/******************************************************************/
/* x0 contains the address of table */
/* x1 contains the index of first element */
/* x2 contains the number of element */
/* x3 contains address extra area */
mergeSortIterA:
    stp x3,lr,[sp,-16]!    // save  registers
    stp x4,x5,[sp,-16]!    // save  registers
    stp x6,x7,[sp,-16]!    // save  registers
    stp x8,x9,[sp,-16]!    // save  registers
    stp x10,x11,[sp,-16]!  // save  registers
    stp x12,x13,[sp,-16]!  // save  registers
    mov x11,x1              // save N0 first element
    sub x13,x2,1            // save N° last  element
    //affregtit debsort 0
    // echange 1 : comparaison de 2 valeurs consécutives et inversion si necessaire
    //  sans utiliser la table annexe
1:
    add x2,x1,1
    cmp x2,x13
    bgt 6f
    ldr x6,[x0,x1,lsl 3]         // load pointer element 1
    ldr x7,[x0,x2,lsl 3]         // load pointer element 2
    cmp x6,x7
    ble 5f
4:
    str x7,[x0,x1,lsl 3]
    str x6,[x0,x2,lsl 3]
    
5:
    add x1,x1,2
    cmp x1,x13
    blt 1b
6:
    //mov x0,x15
    mov x10,2                // début avec une taille de 2 
7:
    mov x6,x11               // first element
8:
    lsl x8,x10,1             // compute end subset
    add x8,x8,x6
    sub x8,x8,1
    add x7,x6,x8            // compute median
    //affregtit debut12 6
    lsr x7,x7,1
    cmp x8,x13               // maxi ?
    ble 9f                  // no
    mov x8,x13               // yes -> end subset = maxi
    cmp x6,0                 // subset final ?
    beq 9f                  // no
    cmp x7,x8               // else median = first element of subset - 1
    blt 9f
    mov x7,x8

9:
    add x9,x7,1             // recopie partie 1 dans extra table
10:
    sub x1,x9,1
    ldr x2,[x0,x1,lsl 3]
    str x2,[x3,x1,lsl 3]
    sub x9,x9,1
    cmp x9,x6
    bgt 10b
    //affregtit boucle1 5
    mov x9,x7
    cmp x9,x8
    beq 12f
    //affregtit boucle1 5
11:                          // recopie partie 2 inverse dans extra table
    add x1,x9,1
    add x4,x7,x8
    sub x4,x4,x9
    ldr x2,[x0,x1,lsl 3]
    str x2,[x3,x4,lsl 3]
    //affregtit boucle2 0
    add x9,x9,1
    cmp x9,x8
    blt 11b
12:
    mov x9,x6                  //k
    mov x1,x6                  // i
    mov x2,x8                  // j
13:                            // puis fusion des 2 parties dans table finale
    ldr x5,[x3,x1,lsl 3]
    ldr x12,[x3,x2,lsl 3]
    cmp x5,x12
    bgt 15f
    blt 14f

    // si egalité et si i < pivot 
    cmp x1,x7
    ble 14f
    b 15f
14:
    ldr x12,[x3,x1, lsl 3]
    str x12,[x0,x9, lsl 3]
    add x1,x1,1
    b 16f
15:
    ldr x12,[x3,x2, lsl 3]
    str x12,[x0,x9, lsl 3]
    sub x2,x2,1
16:
    add x9,x9,1
    cmp x9,x8
    ble 13b
    
17:
    lsl x2,x10,1            // taille des 2 parties
    add x6,x6,x2            // pour calculer le début suivant
    cmp x6,x13              // maxi ?
    ble 8b
    lsl x10,x10,1           // doublement de la taille à traiter
    cmp x10,x13             // maxi ?
    ble 7b
    
100:
    ldp x12,x13,[sp],16          // restaur  2 registers
    ldp x10,x11,[sp],16          // restaur  2 registers
    ldp x8,x9,[sp],16          // restaur  2 registers
    ldp x6,x7,[sp],16          // restaur  2 registers
    ldp x4,x5,[sp],16          // restaur  2 registers
    ldp x3,lr,[sp],16          // restaur  2 registers
    ret                        // return to address lr x30
    