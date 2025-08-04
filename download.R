# Boys names:
boys <- "https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths/datasets/babynamesenglandandwalesbabynamesstatisticsboys"

# Girls names:
girls <- "https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths/datasets/babynamesenglandandwalesbabynamesstatisticsgirls"

# Long-term historic dataset:
historic <- "https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths/datasets/babynamesenglandandwalestop100babynameshistoricaldata"

library(purrr)
library(stringr)
library(rvest)

download_datasets <- function(page_url, dest_dir = "data-raw") {
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  download_urls <- read_html(page_url) |>
    html_nodes(".btn--thick") |>
    html_attr("href") |>
    (function(x) paste0("https://www.ons.gov.uk", x))()

  walk(
    download_urls,
    ~ {
      filename <- basename(
        str_extract(
          .x,
          "(?<=/)([^/?]+\\.[a-zA-Z0-9]+)(?=[?]|$)"
        )
      )
      download.file(.x, file.path(dest_dir, filename), mode = "wb")
      cat("Downloaded:", filename, "\n")
      Sys.sleep(2) # Pause to avoid 429 rate limiting
    }
  )

  cat("Complete! Downloaded", length(download_urls), "files to", dest_dir, "\n")
}

download_datasets(boys)
download_datasets(girls)
download_datasets(historic)
