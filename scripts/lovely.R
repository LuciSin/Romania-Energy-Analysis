# Load required libraries
library(readr)    # For data import
library(dplyr)    # For data manipulation
library(ggplot2)  # For data visualization
library(tidyr)    # For data tidying

# Import electricity data from CSV file
data <- read_csv("data/electricityConsumptionAndProduction.csv")

# Basic data inspection
head(data)         # Display first few rows
summary(data)      # Show summary statistics
colSums(is.na(data)) # Check for missing values (none found)

# Descriptive statistics for consumption and production
summary(data[c("Consumption", "Production")])

# Consumption distribution histogram
ggplot(data, aes(x = Consumption)) +
  geom_histogram(binwidth = 100, fill = "blue", color = "black") +
  labs(
    title = "Electricity Consumption Distribution",
    x = "Consumption (MW)",
    y = "Frequency"
  )

# Convert DateTime column to proper format
data$DateTime <- as.POSIXct(data$DateTime, format = "%Y-%m-%d %H:%M:%S")

# Time series plot of renewable energy production
ggplot(data, aes(x = DateTime)) +
  geom_line(aes(y = Wind, color = "Wind"), size = 1) +
  geom_line(aes(y = Solar, color = "Solar"), size = 1) +
  geom_line(aes(y = Hydroelectric, color = "Hydroelectric"), size = 1) +
  labs(
    title = "Renewable Energy Production in Romania (2019-2024)",
    x = "Year",
    y = "Production (MW)",
    color = "Energy Type"
  ) +
  scale_color_manual(
    values = c("Wind" = "blue", "Solar" = "orange", "Hydroelectric" = "green")
  ) +
  theme_minimal()

# Calculate max and mean values for renewables
max_solar <- max(data$Solar, na.rm = TRUE)
max_wind <- max(data$Wind, na.rm = TRUE)
max_hydro <- max(data$Hydroelectric, na.rm = TRUE)

mean_solar <- mean(data$Solar, na.rm = TRUE)
mean_wind <- mean(data$Wind, na.rm = TRUE)
mean_hydro <- mean(data$Hydroelectric, na.rm = TRUE)

# Display calculated values
list(
  Max_Solar = max_solar,
  Max_Wind = max_wind,
  Max_Hydroelectric = max_hydro,
  Mean_Solar = mean_solar,
  Mean_Wind = mean_wind,
  Mean_Hydroelectric = mean_hydro
)

# Function to determine season from month
get_season <- function(month) {
  if (month %in% c(12, 1, 2)) {
    return("Winter")
  } else if (month %in% c(3, 4, 5)) {
    return("Spring")
  } else if (month %in% c(6, 7, 8)) {
    return("Summer")
  } else {
    return("Autumn")
  }
}

# Add season column to data
data$Season <- sapply(as.numeric(format(data$DateTime, "%m")), get_season)

# Calculate seasonal averages
seasonal_data <- data %>%
  group_by(Season) %>%
  summarise(
    Avg_Consumption = mean(Consumption, na.rm = TRUE),
    Avg_Production = mean(Production, na.rm = TRUE)
  )

# Reorder seasons for proper plotting
seasonal_data$Season <- factor(seasonal_data$Season, 
                               levels = c("Winter", "Spring", "Summer", "Autumn"))

# Reshape data for side-by-side comparison
seasonal_data_long <- seasonal_data %>%
  pivot_longer(cols = c(Avg_Consumption, Avg_Production),
               names_to = "Type",
               values_to = "Value") %>%
  mutate(Type = ifelse(Type == "Avg_Consumption", "Consumption", "Production"))

# Seasonal comparison plot
ggplot(seasonal_data_long, aes(x = Season, y = Value, fill = Type)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), color = "black") +
  labs(
    title = "Consumption vs Production by Season",
    x = "Season",
    y = "Average (MW)",
    fill = "Type"
  ) +
  scale_fill_manual(values = c("Consumption" = "blue", "Production" = "green")) +
  theme_minimal()

# Calculate stats for non-renewables
max_oil_gas <- max(data$`Oil and Gas`, na.rm = TRUE)
max_coal <- max(data$Coal, na.rm = TRUE)

mean_oil_gas <- mean(data$`Oil and Gas`, na.rm = TRUE)
mean_coal <- mean(data$Coal, na.rm = TRUE)

# Nuclear energy stats
max_nuclear <- max(data$Nuclear, na.rm = TRUE)
mean_nuclear <- mean(data$Nuclear, na.rm = TRUE)

# Create energy sources dataframe
energy_sources <- data.frame(
  Source = c("Solar", "Wind", "Hydroelectric", "Nuclear", "Oil and Gas", "Coal"),
  Category = c("Renewable", "Renewable", "Renewable", 
               "Non-renewable", "Non-renewable", "Non-renewable"),
  Mean_Production = c(
    mean_solar,
    mean_wind,
    mean_hydro,
    mean_nuclear,
    mean_oil_gas,
    mean_coal
  )
)

# Comparative production plot
ggplot(energy_sources, aes(x = Source, y = Mean_Production, fill = Category)) +
  geom_bar(stat = "identity", color = "black") +
  labs(
    title = "Average Production: Renewable vs Non-renewable Sources",
    x = "Energy Source",
    y = "Average Production (MW)",
    fill = "Category"
  ) +
  scale_fill_manual(values = c("Renewable" = "green", "Non-renewable" = "gray")) +
  theme_minimal()

# Multiple regression model
model_comparative <- lm(Consumption ~ Solar + Wind + Hydroelectric + Nuclear + `Oil and Gas` + Coal, data = data)

# Model summary
summary(model_comparative)

# Extract coefficients for visualization
coefficients <- summary(model_comparative)$coefficients[-1, 1]

energy_sources <- data.frame(
  Source = c("Solar", "Wind", "Hydroelectric", "Nuclear", "Oil and Gas", "Coal"),
  Coefficient = coefficients
)

# Coefficient impact plot
ggplot(energy_sources, aes(x = Source, y = Coefficient, fill = Source)) +
  geom_bar(stat = "identity", color = "black") +
  labs(
    title = "Energy Sources' Impact on Consumption",
    x = "Energy Source",
    y = "Coefficient (Impact on Consumption)"
  ) +
  scale_fill_manual(values = c(
    "Solar" = "orange",
    "Wind" = "blue",
    "Hydroelectric" = "green",
    "Nuclear" = "purple",
    "Oil and Gas" = "gray",
    "Coal" = "black"
  )) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))