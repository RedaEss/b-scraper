# run_basta_scraper.R
source("scraper.R")

message(" SCRAPER BASTA MEDIA - VERSION PRÉCISE")
message("=========================================")
message(" Date du scraping: ", format(Sys.Date(), "%Y-%m-%d"))

# Méthode 1: Scraper la section "À la une"
message("\n1. Extraction de la section 'À la une'...")
data_une <- scrape_basta_une()

# Méthode 2: Extraction directe des titres (fallback)
if (nrow(data_une) == 0) {
  message("\n2. Fallback: extraction directe des titres...")
  data_une <- scrape_basta_direct_titles()
}

# Résultats finaux
final_data <- data_une

if (nrow(final_data) > 0) {
  message("\n SULTATS TROUVÉS:")
  message("====================")
  
  # Afficher les résultats
  for (i in 1:nrow(final_data)) {
    message("\n", i, ". ", final_data$title[i])
    if (!is.na(final_data$summary[i]) && nchar(final_data$summary[i]) > 0) {
      message("    ", substr(final_data$summary[i], 1, 100), "...")
    } else {
      message("    [Résumé non disponible]")
    }
    message("    ", final_data$link[i])
    message("    ", final_data$date[i])
  }
  
  # Export CSV
  write.csv(final_data, paste0(format(Sys.Date(), "%Y-%m-%d"),"_basta_une_articles.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  message( paste0("\n Fichier exporté: ",format(Sys.Date(), "%Y-%m-%d"),"_basta_une_articles.csv"))
  
  # Export JSON pour plus de flexibilité
  if (!require(jsonlite, quietly = TRUE)) {
    install.packages("jsonlite", quiet = TRUE)
    library(jsonlite, quietly = TRUE)
  }
  write_json(final_data, paste0(format(Sys.Date(), "%Y-%m-%d"),"_basta_une_articles.json"), pretty = TRUE)
  message(paste0("\n Fichier exporté: ",format(Sys.Date(), "%Y-%m-%d"),"_basta_une_articles.json"))
  
  # Statistiques
  message("\n STATISTIQUES:")
  message("   - Articles trouvés: ", nrow(final_data))
  message("   - Date du scraping: ", unique(final_data$date))
  
} else {
  message("\n AUCUN ARTICLE TROUVÉ")
  message("Conseils:")
  message("1. Vérifiez que le site https://portail.basta.media/ est accessible")
  message("2. Les sélecteurs CSS peuvent avoir changé")
  message("3. Consultez le fichier 'basta_structure_diagnostic.html' pour inspection")
}

message("\n SCRAPING TERMINÉ - ", nrow(final_data), " articles trouvés")