#include <stdlib.h>
#include <sys/mman.h>
#include <lightning.h>

/* This library contains function equivalents for the macros in GNU
   lightning. Hopefully this will make it possible for Guile to use
   them. */

/* this is a pseudo-register: it could actually be an Rn register. */
int reg_ret = JIT_RET;

/* three caller-save integer registers */
int reg_r0 = JIT_R0;
int reg_r1 = JIT_R1;
int reg_r2 = JIT_R2;

/* three callee-save integer registers */
int reg_v0 = JIT_V0;
int reg_v1 = JIT_V1;
int reg_v2 = JIT_V2;

/* six caller-save floating-point registers */
int reg_fpr0 = JIT_FPR0;
int reg_fpr1 = JIT_FPR1;
int reg_fpr2 = JIT_FPR2;
int reg_fpr3 = JIT_FPR3;
int reg_fpr4 = JIT_FPR4;
int reg_fpr5 = JIT_FPR5;

/* and a floating-point return register (unclear from the docs if it's
   a pseudoregister or not - better assume it is) */
/* this is commented out because gcc didn't believe JIT_FPRET was
   defined, and it's not really important to me. */
/* int reg_fpret = JIT_FPRET; */

/* Using this from Scheme will leak memory. */
jit_insn *make_instruction_array(int bytes)
{
  jit_insn *array;
  size_t pagesize, size;

  pagesize = getpagesize();

  size = (bytes/pagesize)*pagesize;   /* these two lines together make */
  if (size < bytes) size += pagesize; /* size the smallest multiple of */
                                      /* pagesize that's >= bytes */

  array = mmap(0, size, PROT_WRITE | PROT_EXEC,
               MAP_ANON | MAP_PRIVATE, 0, 0);

  if (array == MAP_FAILED) {
    return NULL; /* todo: make better error convention. */
  } else {
    return array;
  }
}

void *begin_function_in_buffer(jit_insn *buffer)
{
  return jit_set_ip(buffer).iptr; /* it doesn't matter what type we
                              use because it'll be cast by the Guile
                              interface code anyway. */
  /* the return value is also the pointer to the function which we
     will hopefully construct in the buffer. */
}

void declare_leaf_function(int num_args)
{
  jit_leaf(num_args);
}

int make_int_argument(void)
{
  return jit_arg_i();
}

void retrieve_int_argument(int reg, int argument)
{
  jit_getarg_i(reg, argument);
}

void move_integer_between_regs(int dest, int src)
{
  jit_movr_i(dest, src);
}

void make_return(void)
{
  jit_ret();
}

void flush_instruction_buffer(jit_insn *buffer)
{
  jit_flush_code(buffer, jit_get_ip().ptr);
}

/*
typedef int (*pifi)(int);

int main(int argc, char *argv[])
{
  jit_insn *insn_buffer = make_instruction_array(1024);
  pifi pointer_to_beginning = begin_function_in_buffer(insn_buffer);
  int arg;
  pifi function;

  if (insn_buffer == NULL) {
    perror("Couldn't allocate instruction buffer");
    exit(1);
  }

  declare_leaf_function(1);
  arg = make_int_argument();
  retrieve_int_argument(JIT_R0, arg);
  move_integer_between_regs(JIT_RET, JIT_R0);
  make_return();
  flush_instruction_buffer(insn_buffer);
  function = pointer_to_beginning;

  printf("Ran function(1); got %d\n", function(1));

  return 0;
}
*/
