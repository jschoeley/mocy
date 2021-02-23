cat(crayon::blue(crayon::bold('Render visual consistency checks\n')))

library(here); library(glue)
library(rmarkdown)

wd <- here()

render(
  input = glue('{wd}/src/test/visual_consistency_checks.Rmd'),
  output_format = 'html_document',
  output_file = 'visual_consistency_checks.html',
  output_dir = glue('{wd}/out/'),
  knit_root_dir = wd
)
