args <- commandArgs(trailingOnly = TRUE)
format <- if (length(args)) args[1] else "all"
output <- switch(format, html = "html_document", pdf = "pdf_document", "all")
rmarkdown::render("STAT6011_HW1.Rmd", output_format = output,
                  envir = new.env(), encoding = "UTF-8")
