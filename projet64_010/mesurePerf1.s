/* Programme assembleur ARM Raspberry */
/* Assembleur ARM 64 bits Raspberry  : Vincent Leboulou */
/* modèle pi3B+ 1GO   */
/*  */
/* Comptage nombre d'instructions de cycles et temps  */
/* en utilisant les fonctions de PERF_EVENT_OPEN      */
/* groupement des résultats   */
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ NBBOUCLES,          1000
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
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros64.s"
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
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessDebutPgm:      .asciz "Début du programme. \n"
szMessErreur:        .asciz "Erreur rencontrée.\n"
szMessFinOK:         .asciz "Fin normale du programme. \n"
sMessResult:         .asciz "instructions: @ Cycles: @ temps en µs: @ temps1: @ \n"

szRetourligne:       .asciz  "\n"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
sZoneConv:   .skip 24
stPerf:     .skip perf_event_fin        // structure infos leader
stPerf1:    .skip perf_event_fin        // structure infos fils 1
stPerf2:    .skip perf_event_fin        // structure infos fils 2
stPerf3:    .skip perf_event_fin        // structure infos fils 3
sBuffer:    .skip 100                   // buffer de lecture 
 // chaque zonedu buffer  a une longueur de 64 bits 
 // la première zone contient le nombre de compteurs lus (ici 3)
/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global main                            // 'main' point d'entrée doit être  global 

main:                                   // programme principal 
    ldr x0,qAdrszMessDebutPgm           // x0 ← adresse message debut 
    bl affichageMess                    // affichage message dans console   
  
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

    mov x23,NBBOUCLES
    /********************************************/
1:
    mov x0,#1
    mul x5,x0,x23
    //udiv x0,x5,x23
    //ldr x0,qAdrstPerf            // mesure de ces instructions
    //vidmemtit buffer x0, 4
    //bl appelProc
    sub x23,x23,1
    cbnz x23,1b
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


    ldr x0,qAdrszMessFinOK      // fin OK
    bl affichageMess
    mov x0,#0                   // code retour OK 
    b 100f
99:                             // affichage erreur 
    ldr x1,qAdrszMessErreur     // x0 <- code erreur, x1 <- adresse chaine 
    bl   afficheErreur          // appel affichage message
    mov x0,#1                   // code erreur 
    b 100f
100:                            // fin de programme standard  
    mov x8, #EXIT               // appel fonction systeme pour terminer 
    svc 0 
/************************************/
//qAdrszMessChaine:       .quad szMessChaine
qAdrszMessDebutPgm:      .quad szMessDebutPgm
qAdrszMessErreur:        .quad szMessErreur
qAdrszMessFinOK:         .quad szMessFinOK
qAdrsBuffer:             .quad sBuffer
qAdrstPerf:              .quad stPerf
qAdrstPerf1:             .quad stPerf1
qAdrstPerf2:             .quad stPerf2
qAdrstPerf3:             .quad stPerf3
qAdrsMessResult:         .quad sMessResult
qAdrsZoneConv:           .quad sZoneConv
qAdrszRetourligne:       .quad szRetourligne
/***************************************************/
/*   Exemple d'appel d'une fonction               */
/***************************************************/
appelProc:         // fonction
    stp x0,lr,[sp,-16]!        // save  registres

    affregtit proc 0

100:                    // fin standard de la fonction
    ldp x0,lr,[sp],16          // restaur des  2 registres
    ret                // retour de la fonction en utilisant lr



/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM64.inc"
    