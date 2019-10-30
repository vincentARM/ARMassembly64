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
.macro affichelib str 
    str x0,[sp,-32]!        // save  registre
    mrs x0,nzcv             // save du registre d'état
    str x0,[sp,16]          // save  registres
    adr x0,libaff1\@        // recup adresse libellé passé dans str
    bl affichageMess
    ldr x0,[sp,16]
    msr nzcv,x0             // restaur registre d'état 
    ldr x0,[sp],32          // on restaure x0 pour avoir une pile réalignée
    b smacroafficheMess\@   // pour sauter le stockage de la chaine.
libaff1\@:  .ascii "\str"
               .asciz "\n"
.align 8
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
.align 8
smacro1affbintit\@:
.endm
