/*********************************************/
/*           CONSTANTES                      */
/********************************************/
.equ STDOUT,        1     // Linux output console
.equ EXIT,         93     // Linux syscall 64 bits
.equ WRITE,        64     // Linux syscall 64 bits
.equ READ,         63     // lecture fichier (ou console)
.equ GETTIME,      113    // clock_gettime
.equ GETTIMEOFDAY, 169
.equ BRK,          214    // allocation tas

.equ RSA_F4,  0x10001
.equ TAILLEHASH,      32
.equ TAILLETIMBRE,     8
.equ TAILLELONGUEUR,     8
.equ DIFFICULTE,      3
.equ MAXI,    20                // nombre d'élement maxi de la hashmap
.equ LIMIT, 32                  // nombre d'octets pour le hachage de la clé
.equ COEFF, 80                  // taux de remplissage de la hashmap 80 = 80%
