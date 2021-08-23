#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

SEXP arrow_c_array_from_vector(SEXP vec, SEXP schema_xptr);
SEXP arrow_c_schema_xptr_new(SEXP format_sexp, SEXP name_sexp, SEXP metadata_sexp,
                             SEXP flags_sexp, SEXP children_sexp, SEXP dictionary_xptr);
SEXP arrow_c_schema_data(SEXP schema_xptr);

static const R_CallMethodDef CallEntries[] = {
  {"arrow_c_array_from_vector", (DL_FUNC) &arrow_c_array_from_vector, 2},
  {"arrow_c_schema_xptr_new", (DL_FUNC) &arrow_c_schema_xptr_new, 6},
  {"arrow_c_schema_data", (DL_FUNC) &arrow_c_schema_data, 1},
  {NULL, NULL, 0}
};

void R_init_arrowc(DllInfo *dll) {
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}