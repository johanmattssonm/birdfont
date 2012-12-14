cimport cy_cxxtest

def pyhello():
    cy_cxxtest.hello()

cdef public api void cy_hello():
    print("hello cython-world!")
    
