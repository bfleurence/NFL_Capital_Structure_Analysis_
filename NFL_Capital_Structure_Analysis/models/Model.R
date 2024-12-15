install.packages("dplyr")
install.packages("tidyr")
# Load necessary libraries
library(dplyr)
library(tidyr)


# Prepare data for the model with log transformation on Spending
model_data <- final_table_nonzero %>%
  select(Team, Year, Position_Group, `Spending on The Position Group`, Wins) %>%
  pivot_wider(names_from = Position_Group, values_from = `Spending on The Position Group`, values_fill = list(`Spending on The Position Group` = 0))

# Log-transform the spending columns (add 1 to avoid log(0) issues)
model_data_log <- model_data %>%
  mutate(across(starts_with("QB"):starts_with("ST"), ~log1p(.)))  # log1p is log(1 + value), to handle 0 values

# Disable scientific notation
options(scipen = 999)

# Fit the regression model with log-transformed spending
model_log <- lm(Wins ~ QB + RB + WR + TE + OL + DL + EDGE + MLB + CB + S + ST, data = model_data_log)

# View the summary of the regression model
summary(model_log)

# Save the log-transformed data to a CSV file
write.csv(model_data_log, file = "model_data_log.csv", row.names = FALSE)


