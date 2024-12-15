# Load necessary libraries
install.packages("dplyr")
install.packages("tidyverse")
install.packages("scales")

library(dplyr)
library(tidyverse)
library(scales)

# Read the raw data
file_path <- "~/Downloads/NFL_Capital_Structure_Analysis/data/01-raw_data/raw_data.csv" 
raw_data <- read.csv(file_path)

# Ensure raw_data_2 is loaded (You must have raw_data_2 available)
# raw_data_2 <- read.csv("path_to_raw_data_2.csv")

# Define offensive and special teams positions
offensive_positions <- c("QB", "HB", "FB", "WR", "TE", "LT", "LG", "RG", "C", "RT", "G", "RB", "T")
special_teams_positions <- c("K", "P", "LS")

# Convert Cap.Hit to numeric once
raw_data <- raw_data %>%
  mutate(Cap.Hit.Numeric = as.numeric(gsub("[^0-9.]", "", Cap.Hit)))

# Create the cleaned dataset with offense_or_defense and Position_Group
cleaned_data <- raw_data %>%
  mutate(
    offense_or_defense = case_when(
      Pos %in% offensive_positions ~ "Offense",
      Pos %in% special_teams_positions ~ "Special Teams",
      TRUE ~ "Defense"
    ),
    Position_Group = case_when(
      Pos %in% c("LT", "LG", "C", "RG", "RT", "G", "T") ~ "OL",
      Pos %in% c("HB", "FB", "RB") ~ "RB",
      Pos == "QB" ~ "QB",
      Pos == "TE" ~ "TE",
      Pos == "WR" ~ "WR",
      Pos %in% c("DE", "DT") ~ "DL",
      Pos == "OLB" ~ "EDGE",
      Pos %in% c("ILB", "LB") ~ "MLB",
      Pos == "CB" ~ "CB",
      Pos %in% c("FS", "SS", "S") ~ "S",
      Pos %in% special_teams_positions ~ "ST",
      TRUE ~ "Other"
    )
  )

# Summarize Position_Group_Spending
position_spending <- cleaned_data %>%
  group_by(Team, Year, Position_Group) %>%
  summarize(Position_Group_Spending = sum(Cap.Hit.Numeric, na.rm = TRUE), .groups = "drop")

# Clean Team columns in both datasets
cleaned_data <- cleaned_data %>%
  mutate(Team = gsub("[^a-zA-Z0-9 ]", "", Team))

raw_data_2 <- raw_data_2 %>%
  mutate(Team = gsub("[^a-zA-Z0-9 ]", "", Team))

# Ensure we have all Team-Year combos from both cleaned_data and raw_data_2
all_team_years <- cleaned_data %>%
  distinct(Team, Year) %>%
  union_all(
    raw_data_2 %>%
      distinct(Team, Year)
  )

# Define all position groups from position_spending data
all_position_groups <- unique(position_spending$Position_Group)

# Create a complete grid of Team, Year, and Position_Group
full_grid <- all_team_years %>%
  expand(Team, Year, Position_Group = all_position_groups)

# Merge the spending data into the full grid
final_table <- full_grid %>%
  left_join(position_spending, by = c("Team", "Year", "Position_Group")) %>%
  # Replace missing spending values with 0 instead of filtering them out
  mutate(Position_Group_Spending = replace_na(Position_Group_Spending, 0))

# Add Wins from raw_data_2
final_table <- final_table %>%
  left_join(
    raw_data_2 %>% select(Team, Year, Wins),
    by = c("Team", "Year")
  )

# Remove rows where Position_Group_Spending is 0
final_table_nonzero <- final_table %>%
  filter(Position_Group_Spending != 0)

# Confirm we have all 32 teams and the four years of interest
expected_teams <- 32
expected_years <- c(2021, 2022, 2023, 2024)

# Check the number of unique teams
num_teams <- length(unique(final_table_nonzero$Team))
if (num_teams == expected_teams) {
  message("All 32 teams are present.")
} else {
  warning(paste("Expected 32 teams, but found", num_teams))
}

# Check if the years match the expected list
years_present <- sort(unique(final_table_nonzero$Year))
if (all(expected_years %in% years_present)) {
  message("All four years (2021, 2022, 2023, 2024) are present.")
} else {
  warning(paste("Not all expected years are present. Found years:", paste(years_present, collapse=", ")))
}

# Define the file path to the cleaned_data folder
output_file_path <- "~/Downloads/NFL_Capital_Structure_Analysis/data/03-cleaned_data/final_table_nonzero.csv"

# Save final_table_nonzero as a CSV file
write.csv(final_table_nonzero, file = output_file_path, row.names = FALSE)

# Confirmation message
cat("final_table_nonzero has been saved to:", output_file_path, "\n")

