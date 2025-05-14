# import librarii necesare
library(readr)
library(dplyr)
library(ggplot2)
library(tidyr)

# citirea datelor
data <- read_csv("data/electricityConsumptionAndProductioction.csv")

# verificare date de baza
head(data) # afiseaza primele randuri din setul de date
summary(data) # statistici generale despre date
colSums(is.na(data)) # verificam daca sunt valori lipsa *din fericire nu sunt*

# statistici descriptive pentru consum si productie
summary(data[c("Consumption", "Production")])

# histograma pentru consum
ggplot(data, aes(x = Consumption)) +
  geom_histogram(binwidth = 100, fill = "blue", color = "black") +
  labs(
    title = "Distribuția consumului de electricitate",
    x = "Consum (MW)",
    y = "Frecvență"
  )

# conversia coloanei DateTime in format datetime
data$DateTime <- as.POSIXct(data$DateTime, format = "%Y-%m-%d %H:%M:%S")

# grafic pentru productia de energie regenerabila in timp
ggplot(data, aes(x = DateTime)) +
  geom_line(aes(y = Wind, color = "Wind"), size = 1) +
  geom_line(aes(y = Solar, color = "Solar"), size = 1) +
  geom_line(aes(y = Hydroelectric, color = "Hydroelectric"), size = 1) +
  labs(
    title = "Producția de energie regenerabilă în România (2019 - 2024)",
    x = "Ani",
    y = "Producție (MW)",
    color = "Tip Energie"
  ) +
  scale_color_manual(
    values = c("Wind" = "blue", "Solar" = "orange", "Hydroelectric" = "green")
  ) +
  theme_minimal()

# calcularea valorilor maxime si medii pentru sursele regenerabile
max_solar <- max(data$Solar, na.rm = TRUE)
max_wind <- max(data$Wind, na.rm = TRUE)
max_hydro <- max(data$Hydroelectric, na.rm = TRUE)

mean_solar <- mean(data$Solar, na.rm = TRUE)
mean_wind <- mean(data$Wind, na.rm = TRUE)
mean_hydro <- mean(data$Hydroelectric, na.rm = TRUE)

# afisarea valorilor maxime si medii
list(
  Max_Solar = max_solar,
  Max_Wind = max_wind,
  Max_Hydroelectric = max_hydro,
  Mean_Solar = mean_solar,
  Mean_Wind = mean_wind,
  Mean_Hydroelectric = mean_hydro
)

# functie pentru a determina anotimpul din luna
get_season <- function(month) {
  if (month %in% c(12, 1, 2)) {
    return("Iarna")
  } else if (month %in% c(3, 4, 5)) {
    return("Primavara")
  } else if (month %in% c(6, 7, 8)) {
    return("Vara")
  } else {
    return("Toamna")
  }
}

# adaugam o coloana pentru anotimp
data$Season <- sapply(as.numeric(format(data$DateTime, "%m")), get_season)

# calcularea mediei consumului si productiei pe anotimpuri
seasonal_data <- data %>%
  group_by(Season) %>%
  summarise(
    Avg_Consumption = mean(Consumption, na.rm = TRUE),
    Avg_Production = mean(Production, na.rm = TRUE)
  )

# reordonam anotimpurile pentru grafice
seasonal_data$Season <- factor(seasonal_data$Season, levels = c("Iarna", "Primavara", "Vara", "Toamna"))

# transformam datele pentru grafic comparativ (aici am intampinat o problema unde nu puteam sa pun coloanele unele langa altele, ci se suprapuneau)
seasonal_data_long <- seasonal_data %>%
  pivot_longer(cols = c(Avg_Consumption, Avg_Production),
               names_to = "Type",
               values_to = "Value") %>%
  mutate(Type = ifelse(Type == "Avg_Consumption", "Consumption", "Production"))

# grafic consum vs productie pe anotimpuri
ggplot(seasonal_data_long, aes(x = Season, y = Value, fill = Type)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), color = "black") +
  labs(
    title = "Consum vs Producție în funcție de anotimp",
    x = "Anotimp",
    y = "Media (MW)",
    fill = "Tip"
  ) +
  scale_fill_manual(values = c("Consumption" = "blue", "Production" = "green")) +
  theme_minimal()

# calcularea valorilor maxime si medii pentru sursele neregenerabile
max_oil_gas <- max(data$`Oil and Gas`, na.rm = TRUE)
max_coal <- max(data$Coal, na.rm = TRUE)

mean_oil_gas <- mean(data$`Oil and Gas`, na.rm = TRUE)
mean_coal <- mean(data$Coal, na.rm = TRUE)

# calcularea valorilor pentru energia nucleara
max_nuclear <- max(data$Nuclear, na.rm = TRUE)
mean_nuclear <- mean(data$Nuclear, na.rm = TRUE)

# crearea unui dataframe cu toate sursele
energy_sources <- data.frame(
  Source = c("Solar", "Wind", "Hydroelectric", "Nuclear", "Oil and Gas", "Coal"),
  Category = c("Regenerabilă", "Regenerabilă", "Regenerabilă", 
               "Neregenerabilă", "Neregenerabilă", "Neregenerabilă"),
  Mean_Production = c(
    mean_solar,
    mean_wind,
    mean_hydro,
    mean_nuclear,
    mean_oil_gas,
    mean_coal
  )
)

# grafic comparativ pentru productia medie
ggplot(energy_sources, aes(x = Source, y = Mean_Production, fill = Category)) +
  geom_bar(stat = "identity", color = "black") +
  labs(
    title = "Producția medie a surselor regenerabile și neregenerabile",
    x = "Sursa de energie",
    y = "Producție medie (MW)",
    fill = "Categorie"
  ) +
  scale_fill_manual(values = c("Regenerabilă" = "green", "Neregenerabilă" = "gray")) +
  theme_minimal()

# model de regresie multipla
model_comparativ <- lm(Consumption ~ Solar + Wind + Hydroelectric + Nuclear + `Oil and Gas` + Coal, data = data)

# rezumatul modelului
summary(model_comparativ)

# extragerea coeficienților și crearea unui grafic
coefficients <- summary(model_comparativ)$coefficients[-1, 1]

energy_sources <- data.frame(
  Source = c("Solar", "Wind", "Hydroelectric", "Nuclear", "Oil and Gas", "Coal"),
  Coefficient = coefficients
)

ggplot(energy_sources, aes(x = Source, y = Coefficient, fill = Source)) +
  geom_bar(stat = "identity", color = "black") +
  labs(
    title = "Influența surselor de energie asupra consumului",
    x = "Sursa de energie",
    y = "Coeficient (Impact asupra consumului)"
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
