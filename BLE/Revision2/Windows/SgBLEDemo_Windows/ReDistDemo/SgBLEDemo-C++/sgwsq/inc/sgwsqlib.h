/*
 * sgwsqlib.h
 *
 * Copyright (c) 2009 SecuGen Corporation. All Rigths Reserved
 *
 *  This supports WSQ Compression format.
 *
 * @version  1.00    June 22, 2009
 */

#ifndef SGWSQ_H
#define SGWSQ_H

#include <windows.h>

#if (defined(WIN32) || defined(_WIN32_WCE))

   #ifdef SGWSQLIB_EXPORTS
     #define SGWSQ_DLL_DECL __declspec(dllexport)
   #else
     #define SGWSQ_DLL_DECL __declspec(dllimport)
   #endif

#else
   #define SGWSQ_DLL_DECL
   #define WINAPI
   #define FAR

   #ifndef NULL
   #define NULL 0
   #endif

   #ifndef TRUE
   #define TRUE 1
   #endif

   #ifndef FALSE
   #define FALSE (!TRUE)
   #endif

/*
   typedef unsigned long   DWORD;
   typedef unsigned char   BYTE;
*/

#endif      /* WIN32 */


#ifdef __cplusplus
extern "C" {
#endif
/*
 * LOSSY COMPRESSION BIT RATES
*/
#define BITRATE_5_TO_1  2.25 // yields around 5:1 compression
#define BITRATE_15_TO_1 0.75 // yields around 15:1 compression

/*
 * Error codes
 */
enum SgWsqErrorCode {

   /*  General error */
   SGWSQ_ERROR_NONE = 0,
   SGWSQ_ERROR_FUNCTION_FAILED = 2,
   SGWSQ_ERROR_INVALID_PARAM = 3,               /* It calls a function with invalid parameters. */

};

/* decoder.c */
SGWSQ_DLL_DECL DWORD WINAPI SGWSQ_Decode(
                        BYTE **fingerImageOut,
                        DWORD *width, 
                        DWORD *height, 
                        DWORD *pixelDepth, 
                        DWORD *ppi,
                        DWORD *lossyFlag,
                        BYTE *wsqImage, 
                        DWORD wsqImageLength);

/* encoder.c */
SGWSQ_DLL_DECL DWORD WINAPI SGWSQ_Encode(
                        BYTE ** wsqImageOut,  
                        DWORD *wsqImageOutSize,
                        float wsqBitRate,  
                        BYTE * fingerImage,
                        DWORD width, 
                        DWORD height, 
                        DWORD pixelDepth, 
                        DWORD ppi, 
                        char *commentText);


SGWSQ_DLL_DECL DWORD WINAPI  SGWSQ_Free(BYTE *mem);

#ifdef __cplusplus
}
#endif

#endif /* SGWSQ_H */
