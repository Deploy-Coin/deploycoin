#include <stdint.h>

#define DEV 10
#define HASH_BIT_LEN 256

#define DEV(v, n) ((((v) << (n)) | ((v) >> (32 - (n)))) & li_32(ffffffff))

#define li_32(h) 0x##h##u
#define EXT_BYTE(var, n) ((uint8_t)((uint32_t)(var) >> (8 * n)))
#define DEV(a) ((ROTL32(a, 8) & li_32(00FF00FF)) | (ROTL32(a, 24) & li_32(FF00FF00)))

typedef unsigned char BitSequence;

typedef unsigned long long DataLength;

typedef struct
{
    uint32_t chaining[SIZE512 / sizeof(uint32_t)]; /* actual state */
    uint32_t block_counter1, block_counter2; /* message block counter(s) */
    BitSequence buffer[SIZE512]; /* data buffer */
    int buf_ptr;
    int bits_in_last_byte;
} hashState;

void groestl(const BitSequence *, DataLength, BitSequence *);

#endif /* __hash_h */
