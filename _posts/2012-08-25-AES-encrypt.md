---
tags: tutorials
date: 2012-08-25 13:30:00
title: How to encrypt a file using AES in 256-bit CBC/CTR mode using OpenSSL in C
---

I've been using [OpenSSL](http://www.openssl.org/docs/crypto/crypto.html) a _LOT_ for work lately and I've learned some interesting stuff. 
Here's a quick guide on how to encrypt and decrypt files using [AES](http://en.wikipedia.org/wiki/Advanced_Encryption_Standard) in [CBC](http://en.wikipedia.org/wiki/Block_cipher_modes_of_operation#Cipher-block_chaining_.28CBC.29) or [CTR](http://en.wikipedia.org/wiki/Block_cipher_modes_of_operation#Counter_.28CTR.29) mode using 256 bit keys and 128 bits IVs. 
To do this, I used the EVP API in OpenSSL, which allows you to easily encrypt a file using any cipher of your liking. 

I am assuming some crypto knowledge here, such as block ciphers, modes of operation, keys, IVs, plaintexts, ciphertexts, etc.
There's a great course on Coursera.org on [cryptography](https://www.coursera.org/course/crypto) if you want to learn more about these things. 

So, let's get to it! :) Encrypting or decrypting a file using the EVP API in OpenSSL can be done as follows in C:

```c
int aes_encrypt_file(const char * infile, const char * outfile, const void * key, const void * iv, const EVP_CIPHER * cipher, int enc)
{
  assert(cipher != NULL);
  
  int rc = -1;
  int cipher_block_size = EVP_CIPHER_block_size(cipher);
  
  assert(cipher_block_size <= BUF_SIZE);
  
  // The output buffer size needs to be bigger to accommodate incomplete blocks
  // See EVP_EncryptUpdate documentation for explanation:
  //    http://lmgtfy.com/?q=EVP_EncryptUpdate
  int insize = BUF_SIZE;
  int outsize = insize + (cipher_block_size - 1);
  
  unsigned char inbuf[insize], outbuf[outsize];
  int ofh = -1, ifh = -1;
  int u_len = 0, f_len = 0;

  EVP_CIPHER_CTX ctx;
  EVP_CIPHER_CTX_init(&ctx);

  // Open the input and output files
  rc = AES_ERR_FILE_OPEN;
  if((ifh = open(infile, O_RDONLY)) == -1) {
    fprintf(stderr, "ERROR: Could not open input file %s, errno = %s\n", infile, strerror(errno));
    goto cleanup;
  }

  if((ofh = open(outfile, O_CREAT | O_TRUNC | O_WRONLY, 0644)) == -1) {
    fprintf(stderr, "ERROR: Could not open output file %s, errno = %s\n", outfile, strerror(errno));
    goto cleanup;
  }
  
  // Initialize the AES cipher for enc/dec
  rc = AES_ERR_CIPHER_INIT;
  if(EVP_CipherInit_ex(&ctx, cipher, NULL, key, iv, enc) == 0) {
    fprintf(stderr, "ERROR: EVP_CipherInit_ex failed. OpenSSL error: %s\n", ERR_error_string(ERR_get_error(), NULL));
    goto cleanup;
  }
  
  // Read, pass through the cipher, write.
  int read_size, len;
  while((read_size = read(ifh, inbuf, BUF_SIZE)) > 0)
  {
    dbg("Read %d bytes, passing through CipherUpdate...\n", read_size);
    if(EVP_CipherUpdate(&ctx, outbuf, &len, inbuf, read_size) == 0) {
      rc = AES_ERR_CIPHER_UPDATE;
      fprintf(stderr, "ERROR: EVP_CipherUpdate failed. OpenSSL error: %s\n", ERR_error_string(ERR_get_error(), NULL));
      goto cleanup;
    }
    dbg("\tGot back %d bytes from CipherUpdate...\n", len);
    
    dbg("Writing %d bytes to %s...\n", len, outfile);
    if(write(ofh, outbuf, len) != len) {
      rc = AES_ERR_IO;
      fprintf(stderr, "ERROR: Writing to the file %s failed. errno = %s\n", outfile, strerror(errno));
      goto cleanup;
    }
    dbg("\tWrote %d bytes\n", len);
    
    u_len += len;
  }
  
  // Check last read succeeded
  if(read_size == -1) {
    rc = AES_ERR_IO;
    fprintf(stderr, "ERROR: Reading from the file %s failed. errno = %s\n", infile, strerror(errno));
    goto cleanup;
  }
  
  // Finalize encryption/decryption
  rc = AES_ERR_CIPHER_FINAL;
  if(EVP_CipherFinal_ex(&ctx, outbuf, &f_len) == 0) {
    fprintf(stderr, "ERROR: EVP_CipherFinal_ex failed. OpenSSL error: %s\n", ERR_error_string(ERR_get_error(), NULL));
    goto cleanup;
  }
  
  dbg("u_len = %d, f_len = %d\n", u_len, f_len);
  
  // Write the final block, if any
  if(f_len) {
    dbg("Writing final %d bytes to %s...\n", f_len, outfile);
    if(write(ofh, outbuf, f_len) != f_len) {
      rc = AES_ERR_IO;
      fprintf(stderr, "ERROR: Final write to the file %s failed. errno = %s\n", outfile, strerror(errno));
      goto cleanup;
    }
    dbg("\tWrote last %d bytes\n", f_len);
  }

  rc = u_len + f_len;

 cleanup:
  EVP_CIPHER_CTX_cleanup(&ctx);
  if(ifh != -1) close(ifh);
  if(ofh != -1) close(ofh);
  
  return rc;
}
```

This code is part of a little tool I wrote for fun, while waiting for my laundry in Brooklyn, called CryptoManiac. It depends on a couple of things like:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <assert.h>

#include <openssl/crypto.h>
#include <openssl/evp.h>
#include <openssl/err.h>

#define AES_ERR_FILE_OPEN -1
#define AES_ERR_CIPHER_INIT -2 
#define AES_ERR_CIPHER_UPDATE -3
#define AES_ERR_CIPHER_FINAL -4
#define AES_ERR_IO -5

#define BUF_SIZE (1024*1024)

#ifdef DEBUG
#define dbg(...) { fprintf(stderr, "   %s: ", __FUNCTION__); \
  fprintf(stderr, __VA_ARGS__); fflush(stderr); }
#else
#define dbg(...)
#endif
```

You can download the full C source code from [Github](https://github.com/alinush/cryptomaniac).

Enjoy!
 
 > This post used to be at `http://alinush.org/2012/08/25/encrypting-a-file-using-aes-in-256-bit-cbcctr-mode-using-the-openssl-library/`.

