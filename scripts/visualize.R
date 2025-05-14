
# VISUALIZATION SCRIPT


library(tidyverse)
library(lubridate)
library(scales)
library(stringr)


# 1. Energy Mix Overview
energy_mix <- data %>%
  select(DateTime, Solar, Wind, Hydroelectric, Coal, `Oil and Gas`, Nuclear) %>%
  pivot_longer(-DateTime, names_to = "Source", values_to = "MW") %>%
  mutate(Source = factor(Source, 
                         levels = c("Coal", "Oil and Gas", "Nuclear", 
                                    "Hydroelectric", "Wind", "Solar"))) %>%
  group_by(Source) %>%
  summarise(Mean_MW = mean(MW, na.rm = TRUE)) %>%
  ggplot(aes(x = reorder(Source, Mean_MW), y = Mean_MW, fill = Source)) +
  geom_col() +
  scale_fill_manual(values = c(
    "Coal" = "#303030",
    "Oil and Gas" = "#636363",
    "Nuclear" = "#8c62f0",
    "Hydroelectric" = "#1a9641",
    "Wind" = "#2b83ba",
    "Solar" = "#fdae61"
  )) +
  labs(
    title = "Romania's Energy Production by Source (2019-2024)",
    subtitle = "Mean hourly production in megawatts (MW)",
    x = NULL,
    y = "Average Production (MW)",
    caption = "Data: Transelectrica | Hydropower dominates renewable output"
  ) +
  coord_flip() +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")

ggsave("output/energy_mix.png", energy_mix, width = 10, height = 6, dpi = 300)

# 2. Seasonal Comparison 
seasonal_plot <- data %>%
  mutate(Season = case_when(
    month(DateTime) %in% c(12,1,2) ~ "Winter",
    month(DateTime) %in% 3:5 ~ "Spring",
    month(DateTime) %in% 6:8 ~ "Summer",
    TRUE ~ "Autumn"
  )) %>%
  group_by(Season) %>%
  summarise(
    Consumption = mean(Consumption),
    Production = mean(Production)
  ) %>%
  pivot_longer(-Season, names_to = "Type", values_to = "MW") %>%
  ggplot(aes(x = Season, y = MW, fill = Type)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_fill_manual(values = c("Consumption" = "#d7191c", "Production" = "#2c7bb6")) +
  labs(
    title = "Seasonal Energy Balance",
    subtitle = "Winter shows consistent production deficit",
    x = NULL,
    y = "Average (MW)",
    fill = NULL,
    caption = "Deficit calculated as (Production - Consumption)/Consumption"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top")

ggsave("output/seasonal_diff.png", seasonal_plot, width = 8, height = 6, dpi = 300)

# 3. Renewable Trends 
renewable_trends <- data %>%
  select(DateTime, Solar, Wind, Hydroelectric) %>%
  pivot_longer(-DateTime, names_to = "Source", values_to = "MW") %>%
  mutate(Year = year(DateTime)) %>%
  group_by(Year, Source) %>%
  summarise(Monthly_Avg = mean(MW)) %>%
  ggplot(aes(x = Year, y = Monthly_Avg, color = Source)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  scale_color_manual(values = c(
    "Hydroelectric" = "#1a9641",
    "Wind" = "#2b83ba",
    "Solar" = "#fdae61"
  )) +
  labs(
    title = "Renewable Energy Growth (2019-2024)",
    subtitle = "Monthly average production by source",
    x = NULL,
    y = "Average Production (MW)",
    color = "Source",
    caption = "Solar shows fastest growth rate (1137% since 2019)"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top")

ggsave("output/renewable_trends.png", renewable_trends, width = 10, height = 6, dpi = 300)

# 4. Impact Coefficients 
model <- lm(Consumption ~ Solar + Wind + Hydroelectric + Coal + `Oil and Gas`, data = data)

coefficients_plot <- broom::tidy(model) %>%
  filter(term != "(Intercept)") %>%
  mutate(term = str_replace_all(term, "`", "")) %>%
  ggplot(aes(x = reorder(term, estimate), y = estimate, fill = term)) +
  geom_col() +
  geom_errorbar(aes(ymin = estimate - std.error, 
                    ymax = estimate + std.error),
                width = 0.2) +
  scale_fill_manual(values = c(
    "Coal" = "#303030",
    "Oil and Gas" = "#636363",
    "Hydroelectric" = "#1a9641",
    "Wind" = "#2b83ba",
    "Solar" = "#fdae61"
  )) +
  labs(
    title = "Energy Source Impact on Consumption",
    subtitle = "Regression coefficients with standard error bars",
    x = NULL,
    y = "Impact Coefficient",
    caption = "Positive values indicate consumption increases with production"
  ) +
  coord_flip() +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")

ggsave("output/coefficients.png", coefficients_plot, width = 9, height = 5, dpi = 300)

# summary table for seasonal data
data %>%
  mutate(Season = case_when(
    month(DateTime) %in% c(12,1,2) ~ "Winter",
    month(DateTime) %in% 3:5 ~ "Spring",
    month(DateTime) %in% 6:8 ~ "Summer",
    TRUE ~ "Autumn"
  )) %>%
  group_by(Season) %>%
  summarise(
    `Avg Consumption (MW)` = round(mean(Consumption)),
    `Avg Production (MW)` = round(mean(Production)),
    Deficit = paste0(round((mean(Production) - mean(Consumption))/mean(Consumption)*100), "%")
  ) %>%
  knitr::kable(format = "markdown")

