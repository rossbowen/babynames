library(dplyr)
library(tidyr)
library(readxl)
library(janitor)
library(stringr)
library(glue)

# Geography codes
ENGLAND <- "E92000001"
WALES <- "W92000004"
ENGLAND_AND_WALES <- "K04000001"

process_baby_names_sheet <- function(
  file,
  sheet,
  skip_rows = 0,
  max_rows = Inf,
  slice_first = FALSE,
  year,
  sex,
  geography,
  processing_type
) {
  df <- read_excel(
    file,
    sheet = sheet,
    skip = skip_rows,
    n_max = max_rows,
    .name_repair = "unique_quiet"
  )

  # Remove first row if needed
  if (slice_first) {
    df <- slice(df, -1)
  }

  if (processing_type == "historic") {
    df |>
      pivot_longer(
        cols = -1,
        names_to = "year",
        values_to = "name"
      ) |>
      clean_names() |>
      mutate(
        year = as.integer(year),
        sex = sex,
        geography = geography,
        rank = as.integer(rank),
        name = str_to_title(name)
      ) |>
      select(year, sex, geography, rank, name)
  } else if (processing_type == "standard" && geography != ENGLAND_AND_WALES) {
    # Two-column layout (England/Wales side by side)
    na_col <- which(sapply(df, function(x) all(is.na(x))))
    if (length(na_col) > 0) {
      second_block_start <- na_col[1] + 1

      process_block <- function(block) {
        names(block) <- c("rank", "name", "count")
        block |>
          filter(!is.na(name), !is.na(rank)) |>
          mutate(
            year = year,
            sex = sex,
            geography = geography,
            rank = as.integer(rank),
            name = str_to_title(name),
            count = as.integer(count)
          ) |>
          select(year, sex, geography, rank, name, count)
      }

      bind_rows(
        process_block(df[1:3]),
        process_block(df[second_block_start:(second_block_start + 2)])
      )
    }
  } else if (processing_type == "modern" || geography == ENGLAND_AND_WALES) {
    # Single column layout (modern or 'full' sheet)
    df <- df[1:min(3, ncol(df))]
    names(df) <- c("rank", "name", "count")[1:ncol(df)]

    df |>
      filter(!is.na(name), !is.na(rank)) %>%
      mutate(
        year = year,
        sex = sex,
        geography = geography,
        rank = as.integer(rank),
        name = str_to_title(name),
        count = as.integer(count)
      ) |>
      select(year, sex, geography, rank, name, count)
  }
}

# fmt: skip
file_configs <- tribble(
  ~pattern, ~sex, ~sheets, ~processing_type,
  # Historic data
  "historicname", "Male", list(full = 2), "historic",
  "historicname", "Female", list(full = 3), "historic",

  # Standard patterns by year range
  "1996boys", "Male", list(full = 4), "standard",
  "1996girls", "Female", list(full = 4), "standard",

  # 1997-2010 pattern
  "(199[7-9]|200[0-9]|2010)boys", "Male", list(england = 3, wales = 4, full = 7), "standard",
  "(199[7-9]|200[0-9]|2010)girls", "Female", list(england = 3, wales = 4, full = 7), "standard",

  # 2011-2020 pattern
  "(201[1-9]|2020)boys", "Male", list(england = 5, wales = 6, full = 9), "standard",
  "(201[1-9]|2020)girls", "Female", list(england = 5, wales = 6, full = 9), "standard",

  # 2021 special case
  "2021boys", "Male", list(england = 6, wales = 7, full = 10), "modern",
  "2021girls", "Female", list(england = 5, wales = 6, full = 9), "modern",

  # 2022+ pattern
  "boysnames202[2-9]", "Male", list(england = 5, wales = 6, full = 9), "modern",
  "girlsnames202[2-9]", "Female", list(england = 5, wales = 6, full = 9), "modern"
)


# Get processing parameters for a file
# sheet_type can be "england", "wales", or "full"
get_file_configs <- function(filename, sheet_type) {
  # Extract year from filename
  year <- str_extract(filename, "\\d{4}") |> as.integer()

  configs <- file_configs |>
    filter(str_detect(filename, pattern)) |>
    filter(is.na(year) | year == !!year)

  if (nrow(configs) == 0) {
    stop(glue("No configuration found for file: {filename}"))
  }

  result <- lapply(seq_len(nrow(configs)), function(i) {
    config <- configs[i, ]
    params <- list(
      sheet = config$sheets[[1]][[sheet_type]],
      skip_rows = case_when(
        config$processing_type == "historic" ~ 3L,
        year == 2021 ~ 6L,
        config$processing_type == "modern" ~ 4L,
        sheet_type == "full" & year >= 1996 & year <= 2020 ~ 4L,
        year >= 2011 ~ 6L,
        TRUE ~ 6L
      ),
      slice_first = case_when(
        config$processing_type == "historic" ~ TRUE,
        config$processing_type == "modern" ~ FALSE,
        sheet_type == "full" & year >= 2012 & year <= 2020 ~ FALSE,
        year == 2011 & config$sex == "Female" ~ FALSE,
        TRUE ~ TRUE
      ),
      max_rows = if (config$processing_type == "historic") 101 else Inf
    )
    list(
      year = year,
      sex = config$sex,
      sheet = params$sheet,
      skip_rows = params$skip_rows,
      slice_first = params$slice_first,
      max_rows = params$max_rows,
      processing_type = config$processing_type
    )
  })
  result
}


process_all_files <- function(
  data_dir = "data-raw",
  start_year = 1996,
  end_year = Inf
) {
  files <- list.files(data_dir, pattern = "\\.(xls|xlsx)$", full.names = TRUE)
  all_data <- list()

  for (file in files) {
    filename <- basename(file)

    tryCatch(
      {
        for (sheet_type in c("england", "wales", "full")) {
          configs <- tryCatch(
            get_file_configs(filename, sheet_type),
            error = function(e) NULL
          )
          if (is.null(configs)) {
            next
          }

          for (config in configs) {
            # Skip if outside year range
            if (config$year < start_year || config$year > end_year) {
              next
            }

            # Skip england and wales for historic processing
            if (config$processing_type == "historic" && sheet_type != "full") {
              next
            }

            # Skip england and wales for 1996
            if (config$year == 1996 && sheet_type != "full") {
              next
            }

            message(glue(
              "Processing {filename} | {config$year} | {config$sex} | {sheet_type} | {config$processing_type}"
            ))

            geography <- case_when(
              sheet_type == "england" ~ ENGLAND,
              sheet_type == "wales" ~ WALES,
              sheet_type == "full" ~ ENGLAND_AND_WALES,
              TRUE ~ ENGLAND_AND_WALES
            )

            df <- process_baby_names_sheet(
              file = file,
              sheet = config$sheet,
              skip_rows = config$skip_rows,
              max_rows = config$max_rows,
              slice_first = config$slice_first,
              year = config$year,
              sex = config$sex,
              geography = geography,
              processing_type = config$processing_type
            )

            key <- glue("{config$year}_{config$sex}_{sheet_type}")
            all_data[[key]] <- df
          }
        }
      },
      error = function(e) {
        message(glue("Error processing {filename}: {e$message}"))
      }
    )
  }

  bind_rows(all_data) |>
    arrange(year, geography, sex, rank) |>
    mutate(
      geography_label = case_when(
        geography == ENGLAND ~ "England",
        geography == WALES ~ "Wales",
        geography == ENGLAND_AND_WALES ~ "England and Wales"
      ),
      .after = geography
    )
}


all_names <- process_all_files()

readr::write_csv(all_names, "ons-baby-names-clean.csv", na = "")
