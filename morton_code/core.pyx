cimport cython
from cython.parallel import prange
from libc.stdint cimport uint32_t
from libc.stdint cimport uint16_t
from libc.stdint cimport uint64_t

@cython.boundscheck(False)
@cython.wraparound(False)
cdef void encode32_morton2(uint16_t x_, uint16_t y_, uint32_t mc_) nogil:
  cdef int res
  res=x_|((uint64_t<y_>)<<32)
  res=(res|(res<<8))&0x00ff00ff00ff00ff
  res=(res|(res<<4))&0x0f0f0f0f0f0f0f0f
  res=(res|(res<<2))&0x3333333333333333
  res=(res|(res<<1))&0x5555555555555555
  mc_=uint32_t<res|(res>>31)>

@cython.boundscheck(False)
@cython.wraparound(False)
cdef void decode32_morton2(uint16_t x_, uint16_t y_, uint32_t mc_) nogil:
  cdef int res
  res=(mc_|(uint64_t<mc_><<31))&0x5555555555555555
  res=(res|(res>>1))&0x3333333333333333
  res=(res|(res>>2))&0x0f0f0f0f0f0f0f0f
  res=(res|(res>>4))&0x00ff00ff00ff00ff
  res=res|(res>>8)
  x_=uint16_t<res>
  y_=uint16_t<(res>>32)>

@cython.boundscheck(False)
@cython.wraparound(False)
cpdef void morton_decode_each(float[::1] img, float[:,::1] decoded_img) nogil:
  cdef int l = img.shape[0]
  cdef int mc = 0
  cdef int i = 0
  cdef int j = 0
  for mc in prange(l,nogil=True):
    decode32_morton2(i,j,mc)
    decoded_img[i][j]=img[mc]

@cython.boundscheck(False)
@cython.wraparound(False)
cpdef void morton_encode_each(float[:,::1] img, float[::1] encoded_img) nogil:
  cdef int h = img.shape[0]
  cdef int w = img.shape[1]
  cdef int mc = 0
  for i in prange(h,nogil=True):
    for j in prange(w,nogil=True):
      encode32_morton2(i,j,mc)
      encoded_img[mc]=img[i][j]

@cython.boundscheck(False)
@cython.wraparound(False)
cpdef void morton_encode_c(float[:,:,:,::1] img_batch, float[:,:,::1] encoded_imgs) nogil:
  cdef int b=img_batch.shape[0]
  cdef int c=img_batch.shape[1]
  cdef int i=0
  cdef int j=0
  for i in prange(b,nogil=True):
    for j in prange(c,nogil=True):
       morton_encode_each(img_batch[i][j],encoded_imgs[i][j])


@cython.boundscheck(False)
@cython.wraparound(False)
cpdef void morton_decode_c(float[:,:,:,::1] img_batch, float[:,:,::1] decoded_imgs) nogil:
  cdef int b=img_batch.shape[0]
  cdef int c=img_batch.shape[1]
  cdef int i=0
  cdef int j=0
  for i in prange(b,nogil=True):
    for j in prange(c,nogil=True):
       morton_decode_each(img_batch[i][j],decoded_imgs[i][j])
