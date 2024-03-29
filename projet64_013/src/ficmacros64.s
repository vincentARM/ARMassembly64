/* Programme assembleur ARM Raspberry */
/* Assembleur ARM 64 bits Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle 3B+ 1GO   */
/***************************************
/* Fichier des macros                 */
/**************************************/
/****************************************************/
/* macro d'affichage d'un libellé                   */
/****************************************************/
/* pas d'espace dans le libellé     */
.macro afficherlib str 
    str x0,[sp,-32]!        // save  registre
    mrs x0,nzcv             // save du registre d'état
    str x0,[sp,16]          // save  registres
    adr x0,libaff1\@        // recup adresse libellé passé dans str
    bl afficherMessage
    ldr x0,[sp,16]
    msr nzcv,x0             // restaur registre d'état 
    ldr x0,[sp],32          // on restaure x0 pour avoir une pile réalignée
    b smacroafficheMess\@   // pour sauter le stockage de la chaine.
libaff1\@:  .ascii "\str"
               .asciz "\n"
.align 4
smacroafficheMess\@:
.endm                       // fin de la macro
/********************************************************************/
/* macro d'enrobage affichage binaire d'un registre  avec étiquette */
/********************************************************************/
.macro affbintit str 
    str x1,[sp,-32]!        // save  registre
    mrs x1,nzcv             // save du registre d'état
    str x1,[sp,16]          // save  registres
    adr x1,libbin1\@        // utilisation de adr suite pb gros programme
    bl affichageReg2        // affichage du registre en base 2
    ldr x1,[sp,16]
    msr nzcv,x1             // restaur registre d'état 
    ldr x1,[sp],32          // on restaure x1 pour avoir une pile réalignée
    b smacro1affbintit\@    // pour sauter le stockage de la chaine.
libbin1\@:  .asciz "\str"
.align 4
smacro1affbintit\@:
.endm
/********************************************************************/
/* macro d'enrobage affichage de 6 registres en hexa  avec étiquette */
/********************************************************************/
.macro affregtit str, num
    stp x0,x1,[sp,-32]!        // save  registre
    mrs x1,nzcv             // save du registre d'état
    str x1,[sp,16]          // save  registres
    mov x0,#\num            // premier registre a afficher */
    adr x1,libreg1\@        // utilisation de adr suite pb gros programme
    stp x0,x1,[sp,-16]!
    ldp x0,x1,[sp,16]
    bl affRegistres16        // affichage de 6 registres en hexa
    //ldp x0,x1,[sp],16
    ldr x1,[sp,16]
    msr nzcv,x1             // restaur registre d'état 
    ldp x0,x1,[sp],32          // on restaure x1 pour avoir une pile réalignée
    b smacro1affregtit\@    // pour sauter le stockage de la chaine.
libreg1\@:  .asciz "\str"
.align 4
smacro1affregtit\@:
.endm
/********************************************************************/
/* macro d'enrobage affichage binaire d'un registre  avec étiquette */
/********************************************************************/
.macro affetattit str 
    str x1,[sp,-32]!        // save  registre
    //mrs x1,nzcv             // save du registre d'état
    //str x1,[sp,16]          // save  registres
    adr x1,libetat1\@        // utilisation de adr suite pb gros programme
    bl affichetat        // affichage du registre en base 2
    //ldr x1,[sp,16]
    //msr nzcv,x1             // restaur registre d'état 
    ldr x1,[sp],32          // on restaure x1 pour avoir une pile réalignée
    b smacro1affetattit\@    // pour sauter le stockage de la chaine.
libetat1\@:  .asciz "\str"
.align 4
smacro1affetattit\@:
.endm
/****************************************************/
/* macro de vidage memoire                          */
/****************************************************/
/* n'affiche que les adresses ou les registre x0 et x1      */
.macro affmemtit str, adr, nb 
    stp x0,x1,[sp,-32]!        // save  registre
    stp x2,x3,[sp,16]          // save  registre
    mrs x3,nzcv                // save du registre d'état dans x3
    adr x2,lib1\@              // recup adresse libellé passé dans str
    .ifc \adr,x1
    mov x0,x1
    .else
    .ifnc \adr,x0
    ldr x0,zon1\@
    .endif
    .endif
    mov x1,#\nb                // nombre de bloc a afficher
    bl affmemoireTit
    msr nzcv,x3                // restaur registre d'état
    ldp x0,x1,[sp],16          // restaur des registre
    ldp x2,x3,[sp],16          // restaur des registr
    b smacro1affmemtit\@       // pour sauter le stockage de la chaine.
.ifnc \adr,x0
.ifnc \adr,x1
zon1\@:  .quad \adr
.endif
.endif
lib1\@:  .asciz "\str"
.align 4
smacro1affmemtit\@:
.endm
