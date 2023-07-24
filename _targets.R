# setup -------------------------------------------------------------------

suppressMessages({
  library(targets)
  library(tidyverse)
  library(magrittr)
  library(crew)
})

conflicted::conflict_prefer_all("dplyr", quiet = TRUE)
conflicted::conflict_prefer("set_names", "purrr", quiet = TRUE)
conflicted::conflict_prefer("extract", "tidyr", quiet = TRUE)

options(clustermq.scheduler = "multicore")

tar_source() # Run the R scripts in the R/ folder

# targets -----------------------------------------------------------------

list(
  tar_target(name = raw_cars, command = {
      rvest::read_html(
        "https://github.com/MarcellGranat/hasznaltauto/tree/main/data/cars_data"
      ) |> 
        as.character() |> 
        str_extract_all("cars_data.*?RDS") |> # file names
        reduce(c) |> 
        discard(str_detect, "/") |> 
        setdiff("cars_data.RDS") |> 
        str_c(
          "https://raw.githubusercontent.com/MarcellGranat/hasznaltauto/",
          "main/data/cars_data/", # subfolder
          `...` = _ # file_name 
        ) |>  
        map_df(.progress = "raw data from github", read_rds) |> 
        distinct(url_to_car, .keep_all = TRUE)
    }),
  tar_target(name = raw_prices, command = {
      rvest::read_html(
        str_c(
        "https://github.com/MarcellGranat/hasznaltauto/tree/",
        "main/data/available_cars"
        )
      ) |> 
        as.character() |> 
        str_extract_all("available_cars.*?RDS") |> # file names
        reduce(c) |> 
        discard(str_detect, "/") |> 
        str_c(
          "https://raw.githubusercontent.com/MarcellGranat/hasznaltauto/",
          "main/data/available_cars/", # subfolder
          `...` = _ # file_name 
        ) |> 
        map_df(
          .progress = "prices from github",
          .f = \(x) {
            read_rds(x) |> 
              mutate(
                time = str_extract(x, "\\d{4}-\\d{2}-\\d{2}"),
                time = lubridate::ymd(time),
                .before = 1
              )
          }
        )
    }),
  tarchetypes::tar_quarto(manuscript, "manuscript.qmd"),
  tar_target(finalise_manuscript, debug_word(manuscript))
)
