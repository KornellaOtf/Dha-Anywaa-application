/* key_guard.c — native asset-guard for Dha Anywaa.
 *
 * Holds the asset-key passphrase split across two constant arrays and
 * XOR-reassembled only inside native code. Also provides:
 *   - HMAC-SHA256 filename derivation (matches tools/encrypt_assets.py)
 *   - container magic bytes
 *   - expected APK signing-cert SHA-256
 *   - basic root/emulator detection
 *
 * Nothing here exposes the raw passphrase to Dart; JNI returns only the
 * derived 32-byte AES key, transiently, per call.
 */
#include <jni.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/system_properties.h>
#include <sys/ptrace.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

/* ------------------------------------------------------------------ */
/* SHA-256 (compact public-domain-style implementation)               */
/* ------------------------------------------------------------------ */
typedef struct { uint32_t h[8]; uint64_t len; uint8_t buf[64]; size_t n; } Sha256;

static const uint32_t K[64] = {
  0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
  0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
  0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
  0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
  0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
  0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
  0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
  0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

static uint32_t rotr(uint32_t x, int n) { return (x >> n) | (x << (32 - n)); }

static void sha256_block(Sha256 *c, const uint8_t *p) {
  uint32_t w[64];
  for (int i = 0; i < 16; i++)
    w[i] = ((uint32_t)p[i*4]<<24)|((uint32_t)p[i*4+1]<<16)|((uint32_t)p[i*4+2]<<8)|p[i*4+3];
  for (int i = 16; i < 64; i++) {
    uint32_t s0 = rotr(w[i-15],7)^rotr(w[i-15],18)^(w[i-15]>>3);
    uint32_t s1 = rotr(w[i-2],17)^rotr(w[i-2],19)^(w[i-2]>>10);
    w[i] = w[i-16]+s0+w[i-7]+s1;
  }
  uint32_t a=c->h[0],b=c->h[1],cc=c->h[2],d=c->h[3],e=c->h[4],f=c->h[5],g=c->h[6],h=c->h[7];
  for (int i = 0; i < 64; i++) {
    uint32_t S1=rotr(e,6)^rotr(e,11)^rotr(e,25);
    uint32_t ch=(e&f)^(~e&g);
    uint32_t t1=h+S1+ch+K[i]+w[i];
    uint32_t S0=rotr(a,2)^rotr(a,13)^rotr(a,22);
    uint32_t mj=(a&b)^(a&cc)^(b&cc);
    uint32_t t2=S0+mj;
    h=g;g=f;f=e;e=d+t1;d=cc;cc=b;b=a;a=t1+t2;
  }
  c->h[0]+=a;c->h[1]+=b;c->h[2]+=cc;c->h[3]+=d;c->h[4]+=e;c->h[5]+=f;c->h[6]+=g;c->h[7]+=h;
}

static void sha256_init(Sha256 *c) {
  static const uint32_t iv[8]={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
  memcpy(c->h,iv,sizeof iv); c->len=0; c->n=0;
}
static void sha256_update(Sha256 *c, const uint8_t *p, size_t n) {
  c->len += n;
  while (n) {
    size_t take = 64 - c->n; if (take > n) take = n;
    memcpy(c->buf + c->n, p, take); c->n += take; p += take; n -= take;
    if (c->n == 64) { sha256_block(c, c->buf); c->n = 0; }
  }
}
static void sha256_final(Sha256 *c, uint8_t out[32]) {
  uint64_t bits = c->len * 8;
  uint8_t pad = 0x80; sha256_update(c, &pad, 1);
  uint8_t z = 0; while (c->n != 56) sha256_update(c, &z, 1);
  uint8_t lb[8]; for (int i=0;i<8;i++) lb[i]=(uint8_t)(bits>>(56-8*i));
  sha256_update(c, lb, 8);
  for (int i=0;i<8;i++){out[i*4]=c->h[i]>>24;out[i*4+1]=c->h[i]>>16;out[i*4+2]=c->h[i]>>8;out[i*4+3]=c->h[i];}
}
static void sha256(const uint8_t *p, size_t n, uint8_t out[32]) {
  Sha256 c; sha256_init(&c); sha256_update(&c,p,n); sha256_final(&c,out);
}

/* HMAC-SHA256 → hex */
static void hmac_sha256_hex(const uint8_t *key, size_t klen,
                            const uint8_t *msg, size_t mlen,
                            char *hex /*64 chars + NUL*/) {
  uint8_t k0[64]; memset(k0,0,64);
  if (klen > 64) { sha256(key,klen,k0); } else memcpy(k0,key,klen);
  uint8_t ipad[64],opad[64];
  for (int i=0;i<64;i++){ipad[i]=k0[i]^0x36;opad[i]=k0[i]^0x5c;}
  Sha256 c; uint8_t inner[32],out[32];
  sha256_init(&c); sha256_update(&c,ipad,64); sha256_update(&c,msg,mlen); sha256_final(&c,inner);
  sha256_init(&c); sha256_update(&c,opad,64); sha256_update(&c,inner,32); sha256_final(&c,out);
  for (int i=0;i<32;i++) sprintf(hex+i*2,"%02x",out[i]);
  hex[64]=0;
}

/* XOR-encoded strings (key 0x5A) — decoded at call site only. */
static void unxor(const unsigned char *in, size_t n, char *out) {
    for (size_t i = 0; i < n; i++) out[i] = (char)(in[i] ^ 0x5A);
    out[n] = 0;
}
#define XS_0 (0)
#define XS_1 (1)
#define XS_2 (2)
#define XS_3 (3)
#define XS_4 (4)
#define XS_5 (5)
#define XS_6 (6)
#define XS_7 (7)
#define XS_8 (8)
#define XS_9 (9)
#define XS_10 (10)
#define XS_11 (11)
#define XS_12 (12)
#define XS_13 (13)
#define XS_14 (14)
#define XS_15 (15)
#define XS_16 (16)
#define XS_17 (17)
#define XS_18 (18)
#define XS_19 (19)
#define XS_20 (20)
#define XS_21 (21)
#define XS_22 (22)
#define XS_23 (23)
#define XS_24 (24)
#define XS_25 (25)
#define XS_26 (26)
#define XS_27 (27)
#define XS_28 (28)
#define XS_29 (29)
#define XS_30 (30)
static const unsigned char kStrData[] = {
    0x28,0x35,0x74,0x31,0x3F,0x28,0x34,0x3F,0x36,0x74,0x2B,0x3F,0x37,0x2F,
    0x28,0x35,0x74,0x32,0x3B,0x28,0x3E,0x2D,0x3B,0x28,0x3F,
    0x28,0x35,0x74,0x2A,0x28,0x35,0x3E,0x2F,0x39,0x2E,0x74,0x37,0x35,0x3E,0x3F,0x36,
    0x28,0x35,0x74,0x3E,0x3F,0x38,0x2F,0x3D,0x3D,0x3B,0x38,0x36,0x3F,
    0x3C,0x28,0x33,0x3E,0x3B,
    0x3D,0x2F,0x37,0x77,0x30,0x29,0x77,0x36,0x35,0x35,0x2A,
    0x3D,0x37,0x3B,0x33,0x34,
    0x36,0x33,0x34,0x30,0x3F,0x39,0x2E,0x35,0x28,
    0x22,0x2A,0x35,0x29,0x3F,0x3E,
    0x36,0x29,0x2A,0x35,0x29,0x3F,0x3E,
    0x29,0x2F,0x38,0x29,0x2E,0x28,0x3B,0x2E,0x3F,
    0x3F,0x2A,0x33,0x39,
    0x29,0x3B,0x34,0x3E,0x32,0x35,0x35,0x31,
    0x3F,0x3E,0x22,0x2A,
    0x2A,0x33,0x34,0x3F,
    0x3E,0x35,0x38,0x38,0x23,
    0x75,0x2A,0x28,0x35,0x39,0x75,0x29,0x3F,0x36,0x3C,0x75,0x37,0x3B,0x2A,0x29,
    0x75,0x2A,0x28,0x35,0x39,0x75,0x29,0x3F,0x36,0x3C,0x75,0x29,0x2E,0x3B,0x2E,0x2F,0x29,
    0x0E,0x28,0x3B,0x39,0x3F,0x28,0x0A,0x33,0x3E,0x60,
    0x75,0x29,0x23,0x29,0x2E,0x3F,0x37,0x75,0x38,0x33,0x34,0x75,0x29,0x2F,
    0x75,0x29,0x23,0x29,0x2E,0x3F,0x37,0x75,0x22,0x38,0x33,0x34,0x75,0x29,0x2F,
    0x75,0x29,0x38,0x33,0x34,0x75,0x29,0x2F,
    0x75,0x29,0x2F,0x75,0x38,0x33,0x34,0x75,0x29,0x2F,
    0x75,0x3E,0x3B,0x2E,0x3B,0x75,0x36,0x35,0x39,0x3B,0x36,0x75,0x29,0x2F,
    0x75,0x3E,0x3B,0x2E,0x3B,0x75,0x3E,0x3B,0x2E,0x3B,0x75,0x3E,0x3F,0x74,0x28,0x35,0x38,0x2C,0x74,0x3B,0x34,0x3E,0x28,0x35,0x33,0x3E,0x74,0x22,0x2A,0x35,0x29,0x3F,0x3E,0x74,0x33,0x34,0x29,0x2E,0x3B,0x36,0x36,0x3F,0x28,
    0x3D,0x35,0x36,0x3E,0x3C,0x33,0x29,0x32,
    0x28,0x3B,0x34,0x39,0x32,0x2F,
    0x2C,0x38,0x35,0x22,
    0x29,0x3E,0x31,
    0x1F,0x37,0x2F,0x36,0x3B,0x2E,0x35,0x28,
    0x1B,0x34,0x3E,0x28,0x35,0x33,0x3E,0x7A,0x09,0x1E,0x11,
};
static const unsigned short kStrOff[32] = {
    0,
    14,
    25,
    41,
    54,
    59,
    70,
    75,
    84,
    90,
    97,
    106,
    110,
    118,
    122,
    126,
    131,
    146,
    163,
    173,
    187,
    202,
    210,
    220,
    234,
    277,
    285,
    291,
    295,
    298,
    306,
    317,
};
static void xstr(int idx, char *out, size_t cap) {
    (void)cap;
    unxor(kStrData + kStrOff[idx], kStrOff[idx+1]-kStrOff[idx], out);
}

/* ------------------------------------------------------------------ */
/* Split key material (XOR of kPartA ^ kPartB = passphrase)            */
/* ------------------------------------------------------------------ */
static const unsigned char kPartA[64] = {
    0x39, 0x0C, 0x8C, 0x7D, 0x72, 0x47, 0x34, 0x2C, 0xD8, 0x10, 0x0F, 0x2F,
    0x6F, 0x77, 0x0D, 0x65, 0xD6, 0x70, 0xE5, 0x8E, 0x03, 0x51, 0xD8, 0xAE,
    0x8E, 0x4F, 0x6E, 0xAC, 0x34, 0x2F, 0xC2, 0x31, 0xB7, 0xB0, 0x87, 0x16,
    0xEB, 0x3F, 0xC1, 0x28, 0x96, 0xB9, 0x62, 0x23, 0x17, 0x74, 0x94, 0x28,
    0x77, 0x33, 0xC2, 0x8E, 0xE8, 0xBA, 0x53, 0xBD, 0xB5, 0x6B, 0x88, 0x24,
    0x57, 0x7D, 0x53, 0xEC
};
static const unsigned char kPartB[64] = {
    0x5B, 0x6D, 0xBF, 0x1F, 0x40, 0x22, 0x03, 0x4E, 0xE0, 0x23, 0x3F, 0x49,
    0x58, 0x16, 0x6F, 0x52, 0xB0, 0x13, 0xD5, 0xBF, 0x34, 0x61, 0xBA, 0x9F,
    0xEA, 0x2D, 0x0F, 0x95, 0x51, 0x4C, 0xA3, 0x54, 0xD6, 0xD1, 0xE4, 0x2E,
    0x8A, 0x0D, 0xA4, 0x4A, 0xA0, 0x80, 0x53, 0x1A, 0x71, 0x41, 0xA5, 0x1F,
    0x44, 0x03, 0xF6, 0xBF, 0xDE, 0x83, 0x61, 0xDF, 0xD0, 0x0D, 0xB9, 0x1C,
    0x33, 0x45, 0x61, 0xDE
};

/* Derived AES-256 key = SHA-256(passphrase) — computed per call. */
static void asset_key(uint8_t out[32]) {
    uint8_t pass[64];
    for (int i = 0; i < 64; i++) pass[i] = kPartA[i] ^ kPartB[i];
    sha256(pass, 64, out);
    memset(pass, 0, sizeof pass);
}

/* Container magic (must match docs/ASSET_FORMAT.md). */
static const uint8_t kMagic[8] = {0xA7,0x4E,0x43,0x52,0x59,0x50,0x54,0x21};

/* Expected release signing-cert SHA-256 (no colons, uppercase). */
static const char kExpectedCertSha256[] =
    "92AD5B4BB49166ED09547E04EE7763D133FF9302F9B8A77AABA67686988A8253";

/* ------------------------------------------------------------------ */
/* JNI surface                                                        */
/* ------------------------------------------------------------------ */
#define JNI_NAME(pkg, cls, fn) Java_##pkg##_##cls##_##fn

JNIEXPORT jbyteArray JNICALL
JNI_NAME(com_kornellaotf_learn_1dha_1anywaa, MainActivity, getAssetKey)(
    JNIEnv *env, jobject thiz) {
    uint8_t key[32];
    asset_key(key);
    jbyteArray arr = (*env)->NewByteArray(env, 32);
    (*env)->SetByteArrayRegion(env, arr, 0, 32, (const jbyte *)key);
    memset(key, 0, sizeof key);
    return arr;
}

JNIEXPORT jstring JNICALL
JNI_NAME(com_kornellaotf_learn_1dha_1anywaa, MainActivity, getAssetName)(
    JNIEnv *env, jobject thiz, jstring jlogicalId) {
    const char *id = (*env)->GetStringUTFChars(env, jlogicalId, NULL);
    if (!id) return NULL;
    uint8_t key[32];
    asset_key(key);
    char msg[512];
    int mlen = snprintf(msg, sizeof msg, "name:%s", id);
    char hex[65];
    hmac_sha256_hex(key, 32, (const uint8_t *)msg, (size_t)mlen, hex);
    memset(key, 0, sizeof key);
    (*env)->ReleaseStringUTFChars(env, jlogicalId, id);
    char name[17];
    memcpy(name, hex, 16); name[16] = 0;
    return (*env)->NewStringUTF(env, name);
}

JNIEXPORT jbyteArray JNICALL
JNI_NAME(com_kornellaotf_learn_1dha_1anywaa, MainActivity, getMagicBytes)(
    JNIEnv *env, jobject thiz) {
    jbyteArray arr = (*env)->NewByteArray(env, 8);
    (*env)->SetByteArrayRegion(env, arr, 0, 8, (const jbyte *)kMagic);
    return arr;
}

JNIEXPORT jstring JNICALL
JNI_NAME(com_kornellaotf_learn_1dha_1anywaa, MainActivity, expectedCertHash)(
    JNIEnv *env, jobject thiz) {
    return (*env)->NewStringUTF(env, kExpectedCertSha256);
}

JNIEXPORT jboolean JNICALL
JNI_NAME(com_kornellaotf_learn_1dha_1anywaa, MainActivity, isTrustedEnvironment)(
    JNIEnv *env, jobject thiz) {
    char v[PROP_VALUE_MAX];
    char pn[64], n1[16], n2[16], n3[16], n4[16];
    xstr(0,pn,sizeof pn); if (__system_property_get(pn, v) > 0 && strcmp(v,"1")==0) return JNI_FALSE;
    xstr(1,pn,sizeof pn); xstr(25,n1,sizeof n1); xstr(26,n2,sizeof n2); xstr(27,n3,sizeof n3);
    if (__system_property_get(pn, v) > 0 &&
        (strstr(v,n1)||strstr(v,n2)||strstr(v,n3))) return JNI_FALSE;
    xstr(2,pn,sizeof pn); xstr(28,n4,sizeof n4); xstr(29,n1,sizeof n1); xstr(30,n2,sizeof n2);
    if (__system_property_get(pn, v) > 0 &&
        (strstr(v,n4)||strstr(v,n1)||strstr(v,n2))) return JNI_FALSE;
    /* Root / debuggable detection — soft signal only */
    xstr(3,pn,sizeof pn); if (__system_property_get(pn, v) > 0 && strcmp(v,"1")==0) return JNI_FALSE;
    char p1[64],p2[64],p3[64],p4[64],p5[64],p6[64];
    xstr(19,p1,sizeof p1); xstr(20,p2,sizeof p2); xstr(21,p3,sizeof p3);
    xstr(22,p4,sizeof p4); xstr(23,p5,sizeof p5); xstr(24,p6,sizeof p6);
    if (access(p1, F_OK) == 0 || access(p2, F_OK) == 0 ||
        access(p3, F_OK) == 0 || access(p4, F_OK) == 0 ||
        access(p5, F_OK) == 0 || access(p6, F_OK) == 0) return JNI_FALSE;
    return JNI_TRUE;
}

/* ------------------------------------------------------------------ */
/* Anti-debug / anti-hook checks (Prompt 7)                           */
/* Returns 1 = clean, 0 = suspicious. Failures look identical to the  */
/* caller — no reason is exposed.                                    */
/* ------------------------------------------------------------------ */
static int maps_contains_x(int needleIdx) {
    char path[64]; xstr(16, path, sizeof path);
    FILE *f = fopen(path, "r");
    if (!f) return 0;
    char line[512];
    int found = 0;
    char needle[32]; xstr(needleIdx, needle, sizeof needle);
    while (fgets(line, sizeof line, f)) {
        if (strstr(line, needle)) { found = 1; break; }
    }
    fclose(f);
    return found;
}

static int tracer_pid(void) {
    char path[64]; xstr(17, path, sizeof path);
    FILE *f = fopen(path, "r");
    if (!f) return 0;
    char line[256];
    int pid = 0;
    while (fgets(line, sizeof line, f)) {
        char tp[16]; xstr(18, tp, sizeof tp);
        if (strncmp(line, tp, strlen(tp)) == 0) {
            pid = atoi(line + 10);
            break;
        }
    }
    fclose(f);
    return pid;
}

static int port_open(uint16_t port) {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return 0;
    struct timeval tv = {0, 200000}; /* 200 ms */
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof tv);
    struct sockaddr_in a;
    memset(&a, 0, sizeof a);
    a.sin_family = AF_INET;
    a.sin_port = htons(port);
    a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    int r = connect(fd, (struct sockaddr *)&a, sizeof a);
    close(fd);
    return r == 0;
}

static int anti_tamper_native(void) {
    /* ptrace self-attach: fails if a debugger/frida already attached */
    if (ptrace(PTRACE_TRACEME, 0, 0, 0) == -1) return 0;
    ptrace(PTRACE_DETACH, 0, 0, 0);
    /* a live tracer shows up in status even if traceme raced */
    if (tracer_pid() > 0) return 0;
    /* frida / hooking frameworks in memory maps */
    static const int bad[] = {4,5,6,7,8,9,10,11,12,13,14,15};
    for (size_t i = 0; i < sizeof(bad)/sizeof(bad[0]); i++)
        if (maps_contains_x(bad[i])) return 0;
    /* default frida-server port */
    if (port_open(27042)) return 0;
    /* xposed installer package dir */
    char xp[128]; xstr(24, xp, sizeof xp);
    if (access(xp, F_OK) == 0) return 0;
    return 1;
}

JNIEXPORT jboolean JNICALL
JNI_NAME(com_kornellaotf_learn_1dha_1anywaa, MainActivity, antiTamperOk)(
    JNIEnv *env, jobject thiz) {
    return anti_tamper_native() ? JNI_TRUE : JNI_FALSE;
}
