
test_that("NULL to vctr works", {
  vctr <- as_carrow_array(NULL)
  expect_identical(vctr$schema$format, "n")
  expect_identical(vctr$array$length, as_carrow_int64(0))
  expect_identical(vctr$array$null_count, as_carrow_int64(0))
  expect_length(vctr$array$buffers, 0)
})

test_that("logical(0) to vctr works", {
  l <- logical(0)
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "i")
  expect_identical(vctr$array$length, as_carrow_int64(0))
  expect_identical(vctr$array$null_count, as_carrow_int64(0))
  expect_identical(vctr$array$buffers[[2]], l)
})

test_that("NA to vctr works", {
  l <- NA
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "i")
  expect_identical(vctr$schema$flags, carrow_schema_flags(nullable = TRUE))
  expect_identical(vctr$array$length, as_carrow_int64(1))
  expect_identical(vctr$array$null_count, as_carrow_int64(1))
  expect_identical(vctr$array$buffers[[1]], as_carrow_bitmask(FALSE))
  expect_identical(vctr$array$buffers[[2]], l)
})

test_that("integer(0) to vctr works", {
  l <- integer(0)
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "i")
  expect_identical(vctr$array$length, as_carrow_int64(0))
  expect_identical(vctr$array$null_count, as_carrow_int64(0))
  expect_identical(vctr$array$buffers[[2]], l)
})

test_that("NA_integer_ to vctr works", {
  l <- NA_integer_
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "i")
  expect_identical(vctr$schema$flags, carrow_schema_flags(nullable = TRUE))
  expect_identical(vctr$array$length, as_carrow_int64(1))
  expect_identical(vctr$array$null_count, as_carrow_int64(1))
  expect_identical(vctr$array$buffers[[1]], as_carrow_bitmask(FALSE))
  expect_identical(vctr$array$buffers[[2]], l)
})

test_that("double(0) to vctr works", {
  l <- double(0)
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "g")
  expect_identical(vctr$array$length, as_carrow_int64(0))
  expect_identical(vctr$array$null_count, as_carrow_int64(0))
  expect_identical(vctr$array$buffers[[2]], l)
})

test_that("NA_real_ to vctr works", {
  l <- NA_real_
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "g")
  expect_identical(vctr$schema$flags, carrow_schema_flags(nullable = TRUE))
  expect_identical(vctr$array$length, as_carrow_int64(1))
  expect_identical(vctr$array$null_count, as_carrow_int64(1))
  expect_identical(vctr$array$buffers[[1]], as_carrow_bitmask(FALSE))
  expect_identical(vctr$array$buffers[[2]], l)
})

test_that("character(0) to vctr works", {
  l <- character(0)
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "u")
  expect_identical(vctr$array$length, as_carrow_int64(0))
  expect_identical(vctr$array$null_count, as_carrow_int64(0))
  expect_identical(vctr$array$buffers[[2]], 0L)
  expect_identical(vctr$array$buffers[[3]], raw())
})

test_that("NA_character_ to vctr works", {
  l <- NA_character_
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "u")
  expect_identical(vctr$schema$flags, carrow_schema_flags(nullable = TRUE))
  expect_identical(vctr$array$length, as_carrow_int64(1))
  expect_identical(vctr$array$null_count, as_carrow_int64(1))
  expect_identical(vctr$array$buffers[[1]], as_carrow_bitmask(FALSE))
  expect_identical(vctr$array$buffers[[2]], c(0L, 0L))
  expect_identical(vctr$array$buffers[[3]], raw())
})

test_that("small character(0) to vctr works", {
  l <- c("a", "bc", "def")
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "u")
  expect_identical(vctr$array$length, as_carrow_int64(3))
  expect_identical(vctr$array$null_count, as_carrow_int64(0))
  expect_identical(vctr$array$buffers[[2]], c(0L, 1L, 3L, 6L))
  expect_identical(vctr$array$buffers[[3]], charToRaw("abcdef"))
})

test_that("large character() to vctr works", {
  # this allocs ~4 GB, so skip anywhere except locally
  skip_on_cran()
  skip_on_ci()
  # 1 MB * 2048
  l <- rep(strrep("a", 2 ^ 20), 2 ^ 11)
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "U")
  expect_identical(vctr$array$length, as_carrow_int64(2 ^ 11))
  expect_identical(vctr$array$null_count, as_carrow_int64(0))
  expect_identical(length(vctr$array$buffers[[3]]), 2 ^ 31)
})

test_that("factor() to vctr works", {
  l <- factor(c(NA, rep(letters, 2)))
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "i")
  expect_identical(vctr$schema$dictionary$format, "u")
  expect_identical(vctr$array$length, as_carrow_int64(26 * 2 + 1))
  expect_identical(vctr$array$null_count, as_carrow_int64(1))
  expect_identical(vctr$array$buffers[[1]], as_carrow_bitmask(!is.na(l)))
  expect_equal(unclass(vctr$array$buffers[[2]]), c(NA, 0:25, 0:25), ignore_attr = TRUE)
  expect_equal(vctr$array$dictionary$buffers[[2]], c(0L, 1:26))
  expect_equal(vctr$array$dictionary$buffers[[3]], charToRaw(paste(letters, collapse = "")))
})

test_that("raw(0) to vctr works", {
  l <- raw(0)
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "C")
  expect_identical(vctr$array$length, as_carrow_int64(0))
  expect_identical(vctr$array$null_count, as_carrow_int64(0))
  expect_identical(vctr$array$buffers[[2]], l)
})

test_that("as.raw(0xff) to vctr works", {
  l <- as.raw(0xff)
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "C")
  expect_identical(vctr$array$length, as_carrow_int64(1))
  expect_identical(vctr$array$null_count, as_carrow_int64(0))
  expect_identical(vctr$array$buffers[[2]], l)
})

test_that("data.frame to vctr works", {
  l <- data.frame(a = TRUE, b = 1L, c = 1)
  vctr <- as_carrow_array(l)
  expect_identical(vctr$schema$format, "+s")
  expect_identical(vctr$array$length, as_carrow_int64(1))
  expect_identical(vctr$array$null_count, as_carrow_int64(0))
  # won't be true for character() since these are represented differently
  expect_identical(
    lapply(vctr$array$children, function(x) x$buffers[[2]]),
    lapply(l, identity)
  )
})