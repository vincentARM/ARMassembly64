/* table des puissance de 2 normalisées pour grisu2 */
/* de 10E-309 à 10E+307 */
tablePuis10G2: 
  .quad  0x3986B3C0CF469000, -1085  // poste 0
  .quad  0xAB70FE17C79AC800, -1060  // poste 1
  .quad  0xFF77B1FCBEBCE000, -1034  // poste 2
  .quad  0xBE5691EF416BD800, -1007  // poste 3
  .quad  0x8DD01FAD90800000, -980  // poste 4
  .quad  0xD3515C2831559800, -954  // poste 5
  .quad  0x9D71AC8FADA6C800, -927  // poste 6
  .quad  0xEA9C227723EE8800, -901  // poste 7
  .quad  0xAECC499140785000, -874  // poste 8
  .quad  0x823C12795DB6D000, -847  // poste 9
  .quad  0xC21094364DFB5800, -821  // poste 10
  .quad  0x9096EA6F38489800, -794  // poste 11
  .quad  0xD77485CB25823800, -768  // poste 12
  .quad  0xA086CFCD97BF9800, -741  // poste 13
  .quad  0xEF340A98172AB000, -715  // poste 14
  .quad  0xB23867FB2A35B000, -688  // poste 15
  .quad  0x84C8D4DFD2C64000, -661  // poste 16
  .quad  0xC5DD44271AD3D000, -635  // poste 17
  .quad  0x936B9FCEBB25C800, -608  // poste 18
  .quad  0xDBAC6C247D62A800, -582  // poste 19
  .quad  0xA3AB66580D5FD800, -555  // poste 20
  .quad  0xF3E2F893DEC3F000, -529  // poste 21
  .quad  0xB5B5ADA8AAFF8000, -502  // poste 22
  .quad  0x87625F056C7C4800, -475  // poste 23
  .quad  0xC9BCFF6034C13000, -449  // poste 24
  .quad  0x964E858C91BA2800, -422  // poste 25
  .quad  0xDFF9772470298000, -396  // poste 26
  .quad  0xA6DFBD9FB8E5B800, -369  // poste 27
  .quad  0xF8A95FCF88748000, -343  // poste 28
  .quad  0xB94470938FA89800, -316  // poste 29
  .quad  0x8A08F0F8BF0F1800, -289  // poste 30
  .quad  0xCDB0255565313000, -263  // poste 31
  .quad  0x993FE2C6D07B8000, -236  // poste 32
  .quad  0xE45C10C42A2B3800, -210  // poste 33
  .quad  0xAA24249969739000, -183  // poste 34
  .quad  0xFD87B5F28300C800, -157  // poste 35
  .quad  0xBCE5086492111800, -130  // poste 36
  .quad  0x8CBCCC096F508800, -103  // poste 37
  .quad  0xD1B71758E2196800, -77  // poste 38
  .quad  0x9C40000000000000, -50  // poste 39
  .quad  0xE8D4A51000000000, -24  // poste 40
  .quad  0xAD78EBC5AC620000, +3  // poste 41
  .quad  0x813F3978F8940800, +30  // poste 42
  .quad  0xC097CE7BC9071800, +56  // poste 43
  .quad  0x8F7E32CE7BEA6000, +83  // poste 44
  .quad  0xD5D238A4ABE98000, +109  // poste 45
  .quad  0x9F4F2726179A2000, +136  // poste 46
  .quad  0xED63A231D4C4F800, +162  // poste 47
  .quad  0xB0DE65388CC8B000, +189  // poste 48
  .quad  0x83C7088E1AAB6800, +216  // poste 49
  .quad  0xC45D1DF942712000, +242  // poste 50
  .quad  0x924D692CA61BE800, +269  // poste 51
  .quad  0xDA01EE641A709000, +295  // poste 52
  .quad  0xA26DA3999AEF7800, +322  // poste 53
  .quad  0xF209787BB47D6800, +348  // poste 54
  .quad  0xB454E4A179DD1800, +375  // poste 55
  .quad  0x865B86925B9BC800, +402  // poste 56
  .quad  0xC83553C5C8966000, +428  // poste 57
  .quad  0x952AB45CFA97A000, +455  // poste 58
  .quad  0xDE469FBD99A06000, +481  // poste 59
  .quad  0xA59BC234DB399000, +508  // poste 60
  .quad  0xF6C69A72A398A000, +534  // poste 61
  .quad  0xB7DCBF5354E9C000, +561  // poste 62
  .quad  0x88FCF317F2224000, +588  // poste 63
  .quad  0xCC20CE9BD35C7800, +614  // poste 64
  .quad  0x98165AF37B215000, +641  // poste 65
  .quad  0xE2A0B5DC971F3000, +667  // poste 66
  .quad  0xA8D9D1535CE3B000, +694  // poste 67
  .quad  0xFB9B7CD9A4A74800, +720  // poste 68
  .quad  0xBB764C4CA7A44800, +747  // poste 69
  .quad  0x8BAB8EEFB640A000, +774  // poste 70
  .quad  0xD01FEF10A6578800, +800  // poste 71
  .quad  0x9B10A4E5E9913000, +827  // poste 72
  .quad  0xE7109BFBA19C1000, +853  // poste 73
  .quad  0xAC2820D9623BF800, +880  // poste 74
  .quad  0x80444B5E7AA7D000, +907  // poste 75
  .quad  0xBF21E44003ACE000, +933  // poste 76
  .quad  0x8E679C2F5E450000, +960  // poste 77
.equ NBPOSTETABLE10,    (. - tablePuis10G2) / 16
/*  table des puissance de 10 */
Table10:         .quad 10000000000000000000
                 .quad 1000000000000000000
                 .quad 100000000000000000
                 .quad 10000000000000000
                 .quad 1000000000000000
                 .quad 100000000000000
                 .quad 10000000000000
                 .quad 1000000000000
                 .quad 100000000000
                 .quad 10000000000
                 .quad 1000000000
                 .quad 100000000
                 .quad 10000000
                 .quad 1000000
                 .quad 100000
                 .quad 10000
                 .quad 1000
                 .quad 100
                 .quad 10
                 .quad 1
                 