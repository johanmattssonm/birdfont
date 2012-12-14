#ifndef __PYX_HAVE__cy_cxxtest
#define __PYX_HAVE__cy_cxxtest


#ifndef __PYX_HAVE_API__cy_cxxtest

#ifndef __PYX_EXTERN_C
  #ifdef __cplusplus
    #define __PYX_EXTERN_C extern "C"
  #else
    #define __PYX_EXTERN_C extern
  #endif
#endif

__PYX_EXTERN_C DL_IMPORT(void) cy_hello(void);

#endif /* !__PYX_HAVE_API__cy_cxxtest */

#if PY_MAJOR_VERSION < 3
PyMODINIT_FUNC initcy_cxxtest(void);
#else
PyMODINIT_FUNC PyInit_cy_cxxtest(void);
#endif

#endif /* !__PYX_HAVE__cy_cxxtest */
