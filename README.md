**Please note** that this is an inactive **deprecated and superceded** experimental package._You probably want [nanoarrow](https://github.com/apache/arrow-nanoarrow) instead.




<!-- README.md is generated from README.Rmd. Please edit that file -->

# narrow

<!-- badges: start -->

[![Codecov test
coverage](https://codecov.io/gh/paleolimbot/narrow/branch/master/graph/badge.svg)](https://codecov.io/gh/paleolimbot/narrow?branch=master)
[![R-CMD-check](https://github.com/paleolimbot/narrow/workflows/R-CMD-check/badge.svg)](https://github.com/paleolimbot/narrow/actions)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

The goal of narrow is to wrap the [Arrow Data C
API](https://arrow.apache.org/docs/format/CDataInterface.html) and
[Arrow Stream C
API](https://arrow.apache.org/docs/format/CStreamInterface.html) to
provide lightweight Arrow support for R packages to consume and produce
streams of data in Arrow format.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("paleolimbot/narrow")
```

## Creating arrays

You can create an Arrow array using `as_narrow_array()`. For many types
(e.g., integers and doubles), this is done without any copying of
memory: narrow just arranges the existing R vector memory and protects
it for the lifetime of the underlying `struct ArrowArray`.

``` r
library(narrow)
(array <- as_narrow_array(1:5))
#> <narrow_array i[5]>
#> - schema:
#>   <narrow_schema 'i' at 0x55967f8285a0>
#>   - format: i
#>   - name: 
#>   - flags: nullable
#>   - metadata:  list()
#>   - dictionary: NULL
#>   - children[0]:
#> - array_data:
#>   <narrow_array_data at 0x559682692480>
#>   - length: 5
#>   - null_count: 0
#>   - offset: 0
#>   - buffers[2]: List of 2
#>     $ : NULL
#>     $ : int [1:5] 1 2 3 4 5
#>   - dictionary: NULL
#>   - children[0]:
```

For `Array`s and `RecordBatch`es from the [arrow
package](https://arrow.apache.org/docs/r/), this is almost always a
zero-copy operation and is instantaneous even for very large Arrays.

``` r
library(arrow)
(array2 <- as_narrow_array(Array$create(1:5)))
#> <narrow_array i[5]>
#> - schema:
#>   <narrow_schema 'i' at 0x5596817a4350>
#>   - format: i
#>   - name: 
#>   - flags: nullable
#>   - metadata:  list()
#>   - dictionary: NULL
#>   - children[0]:
#> - array_data:
#>   <narrow_array_data at 0x559681bbade0>
#>   - length: 5
#>   - null_count: 0
#>   - offset: 0
#>   - buffers[2]: List of 2
#>     $ :<externalptr> 
#>     $ :<externalptr> 
#>   - dictionary: NULL
#>   - children[0]:
```

## Exporting arrays

To convert an array object to some other type, use
`from_narrow_array()`:

``` r
str(from_narrow_array(array))
#>  int [1:5] 1 2 3 4 5
```

The narrow package has built-in defaults for converting arrays to R
objects; you can also specify your own using the `ptype` argument:

``` r
str(from_narrow_array(array, ptype = double()))
#>  num [1:5] 1 2 3 4 5
from_narrow_array(array, ptype = arrow::Array)
#> Array
#> <int32>
#> [
#>   1,
#>   2,
#>   3,
#>   4,
#>   5
#> ]
```

## Streams

The Arrow C API also specifies an experimental stream interface. In
addition to handling streams created elsewhere, you can create streams
based on a `narrow_array()`:

``` r
stream1 <- as_narrow_array_stream(as_narrow_array(1:3))
narrow_array_stream_get_next(stream1)
#> <narrow_array i[3]>
#> - schema:
#>   <narrow_schema 'i' at 0x559682878380>
#>   - format: i
#>   - name: 
#>   - flags: nullable
#>   - metadata:  list()
#>   - dictionary: NULL
#>   - children[0]:
#> - array_data:
#>   <narrow_array_data at 0x5596812cff20>
#>   - length: 3
#>   - null_count: 0
#>   - offset: 0
#>   - buffers[2]: List of 2
#>     $ :<externalptr> 
#>     $ :<externalptr> 
#>   - dictionary: NULL
#>   - children[0]:
narrow_array_stream_get_next(stream1)
#> NULL
```

…or based on a function that returns one or more `narrow_array()`s:

``` r
counter <- -1
rows_per_chunk <- 5
csv_file <- readr::readr_example("mtcars.csv")
schema <- as_narrow_array(
  readr::read_csv(
    csv_file,
    n_max = 0,
    col_types = readr::cols(.default = readr::col_double())
  )
)$schema

stream2 <- narrow_array_stream_function(schema, function() {
  counter <<- counter + 1L
  result <- readr::read_csv(
    csv_file,
    skip = 1 + (counter * rows_per_chunk),
    n_max = rows_per_chunk,
    col_names = c(
      "mpg", "cyl", "disp", "hp", "drat",
      "wt", "qsec", "vs", "am", "gear", "carb"
    ),
    col_types = readr::cols(.default = readr::col_double())
  )

  if (nrow(result) > 0) result else NULL
})
```

You can pass these to Arrow as a `RecordBatchReader` using
`narrow_array_stream_to_arrow()`:

``` r
reader <- narrow_array_stream_to_arrow(stream2)
as.data.frame(reader$read_table())
#> # A tibble: 32 × 11
#>      mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>    <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1  21       6  160    110  3.9   2.62  16.5     0     1     4     4
#>  2  21       6  160    110  3.9   2.88  17.0     0     1     4     4
#>  3  22.8     4  108     93  3.85  2.32  18.6     1     1     4     1
#>  4  21.4     6  258    110  3.08  3.22  19.4     1     0     3     1
#>  5  18.7     8  360    175  3.15  3.44  17.0     0     0     3     2
#>  6  18.1     6  225    105  2.76  3.46  20.2     1     0     3     1
#>  7  14.3     8  360    245  3.21  3.57  15.8     0     0     3     4
#>  8  24.4     4  147.    62  3.69  3.19  20       1     0     4     2
#>  9  22.8     4  141.    95  3.92  3.15  22.9     1     0     4     2
#> 10  19.2     6  168.   123  3.92  3.44  18.3     1     0     4     4
#> # … with 22 more rows
```

Round-turn operations for `RecordBatch` also work:

``` r
df <- readr::read_csv(csv_file, show_col_types=FALSE)
as.data.frame(from_narrow_array(as_narrow_array(df), arrow::RecordBatch)) 
#> # A tibble: 32 × 11
#>      mpg   cyl  disp    hp  drat    wt  qsec    vs    am  gear  carb
#>    <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#>  1  21       6  160    110  3.9   2.62  16.5     0     1     4     4
#>  2  21       6  160    110  3.9   2.88  17.0     0     1     4     4
#>  3  22.8     4  108     93  3.85  2.32  18.6     1     1     4     1
#>  4  21.4     6  258    110  3.08  3.22  19.4     1     0     3     1
#>  5  18.7     8  360    175  3.15  3.44  17.0     0     0     3     2
#>  6  18.1     6  225    105  2.76  3.46  20.2     1     0     3     1
#>  7  14.3     8  360    245  3.21  3.57  15.8     0     0     3     4
#>  8  24.4     4  147.    62  3.69  3.19  20       1     0     4     2
#>  9  22.8     4  141.    95  3.92  3.15  22.9     1     0     4     2
#> 10  19.2     6  168.   123  3.92  3.44  18.3     1     0     4     4
#> # … with 22 more rows
```

## C data access

The C data interface is ABI stable (and a version of the stream
interface will be ABI stable in the future) so you can access the
underlying pointers in compiled code from any R package (or inline C or
C++ code). A `narrow_schema()` is an external pointer to a
`struct ArrowSchema`, a `narrow_array_data()` is an external pointer to
a `struct ArrowArray`, and a `narrow_array()` is a `list()` of a
`narrow_schema()` and a `narrow_array_data()`.

``` c
#include <R.h>
#include <Rinternals.h>
#include "narrow.h"

SEXP extract_null_count(SEXP array_data_xptr) {
  struct ArrowArray* array_data = (struct ArrowArray*) R_ExternalPtrAddr(array_data_xptr);
  return Rf_ScalarInteger(array_data->null_count);
}
```

``` r
.Call("extract_null_count", as_narrow_array(c(NA, NA, 1:5))$array_data)
#> [1] 2
```

The lifecycles of objects pointed to by the external pointers are
managed by R’s garbage collector: any object that gets garbage collected
has its `release()` callback called (if it isn’t `NULL`) and the
underlying memory for the `struct Arrow...` freed. You can call the
`release()` callback yourself from compiled code but you probably don’t
want to unless you’re explicitly limiting access to an object.
