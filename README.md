# ONS baby names: complete dataset

This repository provides a unified dataset of baby names registered in England and Wales, combining all available datasets published by the [Office for National Statistics (ONS)](https://www.ons.gov.uk/). It includes:

- Boys’ names
- Girls’ names
- Historic top 100 names
- Breakdowns by England, Wales, and England and Wales jointly

## 📦 Overview

The ONS publishes separate datasets for boys and girls, as well as a historical summary of the top 100 names going back decades. These datasets are spread across multiple Excel files and formats, with slight structural differences over time.

This repo fetches, cleans, and consolidates these into a tidy, long-format dataset for analysis and reuse.

---

## 📁 Data sources

| Dataset      | Description                                               | Link                                                                                                                                                                   |
| ------------ | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Boys' names  | Annual baby name stats for boys in England and Wales      | [ONS boys](https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths/datasets/babynamesenglandandwalesbabynamesstatisticsboys)           |
| Girls' names | Annual baby name stats for girls in England and Wales     | [ONS girls](https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths/datasets/babynamesenglandandwalesbabynamesstatisticsgirls)         |
| Historic     | Top 100 baby names from 1904 onwards at 10-year intervals | [ONS historic](https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/livebirths/datasets/babynamesenglandandwalestop100babynameshistoricaldata) |

---

## 🚀 Usage

- [`download.R`](download.R) fetches the latest datasets from ONS into the `data-raw` directory
- [`main.R`](main.R) processes these files, harmonising formats and combining them into a single dataset which is output to [`ons-baby-names-clean.csv`](ons-baby-names-clean.csv)

---

## 📊 Sample output format

| year | sex    | geography   | geography_label     | rank | name    | count |
|------|--------|-------------|---------------------|------|---------|--------|
| 1996 | Female | K04000001   | England and Wales   | 1    | Sophie  | 7087   |
| 1996 | Female | K04000001   | England and Wales   | 2    | Chloe   | 6824   |
| 1996 | Female | K04000001   | England and Wales   | 3    | Jessica | 6711   |
| 1996 | Female | K04000001   | England and Wales   | 4    | Emily   | 6415   |
| 1996 | Female | K04000001   | England and Wales   | 5    | Lauren  | 6299   |
| 1996 | Female | K04000001   | England and Wales   | 6    | Hannah  | 5916   |

---

## 📜 Licence

This project is open source under the MIT licence. Data is Crown copyright and reproduced under the terms of the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
