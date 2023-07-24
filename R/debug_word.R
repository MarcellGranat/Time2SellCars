debug_word <- function(files) {
  
library(reticulate)

quarto_code <- read_lines("manuscript.qmd")

replacements <<- quarto_code |> 
  str_extract("#[|] label: tbl-.*") |> 
  str_remove(".* ") |> 
  str_c("@", `...` = _) |> 
  discard(is.na)

reticulate::py_run_string(
'from docx import Document
import re

document = Document("manuscript.docx")
paragraphs = [t.text for t in document.paragraphs]

replacements = r.replacements + ["random", "xxx"]
replacements = ["\\?" + t + " " for t in replacements]

for i, pattern in enumerate(replacements):
  table_i = "Table " + str(i + 1) + " "
  for j, p in enumerate(paragraphs):
      replaced_text = re.sub(pattern, table_i, p)
      if replaced_text != p:
        document.paragraphs[j].text = re.sub(pattern, table_i, p)

def delete_paragraph(paragraph):
    p = paragraph._element
    p.getparent().remove(p)
    paragraph._p = paragraph._element = None

n_del = 0
for j, p in enumerate(paragraphs):
  if bool(re.search("\\?[(]caption[)]", p)):
    delete_paragraph(document.paragraphs[j - n_del])
    n_del = n_del + 1

document.save("manuscript.docx")'
)
}
