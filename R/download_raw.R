#' Download raw data from GitHub
#'
#' This function downloads raw data from GitHub repository and returns
#' dataframes for cars and prices.
#' 

download_raw <- function() {
  
raw_cars_df <- rvest::read_html(
  "https://github.com/MarcellGranat/hasznaltauto/tree/main/data/cars_data"
) |> 
  as.character() |> 
  str_extract_all("cars_data.*?RDS") |> # file names
  reduce(c) |> 
  discard(str_detect, "/") |> 
  setdiff("cars_data.RDS") |> 
  str_c(
    "https://raw.githubusercontent.com/MarcellGranat/hasznaltauto/", # repo
    "main/data/cars_data/", # subfolder
    `...` = _ # file_name 
  ) |>  
  map_df(.progress = "raw data from github", read_rds) |> 
  distinct(url_to_car, .keep_all = TRUE)

# Download prices from github repo ---------------------------------

raw_prices_df <- rvest::read_html(
  "https://github.com/MarcellGranat/hasznaltauto/tree/main/data/available_cars"
) |> 
  as.character() |> 
  str_extract_all("available_cars.*?RDS") |> # file names
  reduce(c) |> 
  discard(str_detect, "/") |> 
  str_c(
    "https://raw.githubusercontent.com/MarcellGranat/hasznaltauto/", # repo
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

list(
  data = raw_cars_df,
  price = raw_prices_df
)
}
