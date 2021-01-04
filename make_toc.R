make_toc <- function(
  filename, 
  toc_header_name = "Table of Contents",
  base_level = NULL,
  toc_depth = 2
) {
  # credit original: Garrick Aden-Buie, render_toc function
  # https://www.garrickadenbuie.com/blog/add-a-generated-table-of-contents-anywhere-in-rmarkdown/
  # for Rmarkdown html_document, use the original above.
  # modified to use with **blogdown/Hugo-generated anchor links** 
  #   in combination with https://ericbryantphd.com/2020/01/13/add-section-links-in-blogdown/#my-solution
  # modifications: Ignore headers with {-} 
  #                Ignore punctuation/special chars EXCEPT periods
  # warning:       fails with underscores in headings (unless used to bold/ital)
  #                but should otherwise handle most sane headers
  x <- readLines(filename, warn = FALSE)
  x <- paste(x, collapse = "\n")
  x <- paste0("\n", x, "\n")
  for (i in 5:3) {
    regex_code_fence <- paste0("\n[`]{", i, "}.+?[`]{", i, "}\n")
    x <- gsub(regex_code_fence, "", x)
  }
  x <- strsplit(x, "\n")[[1]]
  x <- x[grepl("^#+", x)]
  x <- x[!grepl("^# \\{", x)]
  x <- x[!grepl("\\{-\\}", x)]       # ADDED: ignore headings containing "{-}"
  if (!is.null(toc_header_name)) 
    x <- x[!grepl(paste0("^#+ ", toc_header_name), x)]
  if (is.null(base_level))
    base_level <- min(sapply(gsub("(#+).+", "\\1", x), nchar))
  start_at_base_level <- FALSE
  x <- sapply(x, function(h) {
    level <- nchar(gsub("(#+).+", "\\1", h)) - base_level
    if (level < 0) {
      stop("Cannot have negative header levels. Problematic header \"", h, '" ',
           "was considered level ", level, ". Please adjust `base_level`.")
    }
    if (level > toc_depth - 1) return("")
    if (!start_at_base_level && level == 0) start_at_base_level <<- TRUE
    if (!start_at_base_level) return("")
    if (grepl("\\{#.+\\}(\\s+)?$", h)) {
      # has special header slug
      header_text <- gsub("#+ (.+)\\s+?\\{.+$", "\\1", h)
      header_slug <- gsub(".+\\{\\s?#([-_.a-zA-Z]+).+", "\\1", h)
    } else {
      header_text <- gsub("#+\\s+?", "", h)
      header_text <- gsub("\\s+?\\{.+\\}\\s*$", "", header_text) # strip { .tabset ... }
      header_text <- gsub("^[^[:alpha:]]*\\s*", "", header_text) # remove up to first alpha char  
      # ADDED: strip special characters, then replace multiple spaces with dash
      # This works with blogdown/hugo-generated anchors
      # But not basic rmarkdown html_document anchors
      pre_slug <- gsub("[^-.a-zA-Z0-9 ]", "", header_text)
      pre_slug <- gsub('---', ' ', pre_slug)  # special case - long dash
      pre_slug <- gsub('\\s*$', '', pre_slug) # remove trailing spaces
      pre_slug <- gsub('\\s+', '-', pre_slug)
      header_slug <- tolower(pre_slug) 
    }
    if (header_text != ""){
      paste0(strrep(" ", level * 4), "- [", header_text, "](#", header_slug, ")")
    }
  })
  x <- x[x != ""]
  knitr::asis_output(paste(x, collapse = "\n"))
}