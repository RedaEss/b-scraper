# scraper_basta_precis.R
library(rvest)
library(dplyr)
library(purrr)
library(stringr)

scrape_basta_une <- function() {
  url <- "https://portail.basta.media/"
  
  tryCatch({
    page <- read_html(url)
    
    message(" Ciblage de la section 'À la une'...")
    
    # Cibler spécifiquement le slider "À la une"
    une_section <- page %>% html_element(".home-une.slider--une.cartouche")
    
    if (is.na(une_section)) {
      message(" Section 'À la une' non trouvée")
      return(data.frame(title = character(), summary = character(), link = character(), date = character()))
    }
    
    message(" Section 'À la une' trouvée!")
    
    # Extraire les articles de la une
    articles <- une_section %>% html_elements(".resume.resume--md.article.hentry")
    
    if (length(articles) == 0) {
      # Fallback: chercher les résumés directement
      articles <- une_section %>% html_elements(".resume--md, [class*='resume']")
    }
    
    message(" Articles trouvés dans la une: ", length(articles))
    
    if (length(articles) > 0) {
      results <- map_df(articles, function(article) {
        # Titre - cibler spécifiquement la classe resume-titre
        title_elem <- article %>% html_element(".resume-titre")
        title <- if (!is.na(title_elem)) {
          html_text(title_elem, trim = TRUE)
        } else {
          article %>% html_element("h2, h3, h4") %>% html_text(trim = TRUE)
        }
        
        # Résumé - chercher le chapô ou premier paragraphe
        summary_elem <- article %>% html_element(".resume-chapo, .chapo, p, .summary")
        summary <- if (!is.na(summary_elem)) {
          html_text(summary_elem, trim = TRUE)
        } else {
          NA
        }
        
        # Lien - chercher le lien de l'article
        link_elem <- article %>% html_element("a")
        link <- if (!is.na(link_elem)) {
          html_attr(link_elem, "href")
        } else {
          NA
        }
        
        # Nettoyer et compléter le lien
        if (!is.na(link) && !str_detect(link, "^https?://")) {
          if (str_detect(link, "^/")) {
            link <- paste0("https://portail.basta.media", link)
          } else {
            link <- paste0("https://portail.basta.media/", link)
          }
        }
        
        # Date du jour
        scraped_date <- format(Sys.Date(), "%Y-%m-%d")
        
        data.frame(
          title = ifelse(is.null(title) || is.na(title), NA, title),
          summary = ifelse(is.null(summary) || is.na(summary), NA, summary),
          link = ifelse(is.null(link) || is.na(link), NA, link),
          date = scraped_date,
          stringsAsFactors = FALSE
        )
      })
      
      # Filtrer les résultats valides
      results <- results %>%
        filter(!is.na(title) & nchar(title) > 10) %>%
        distinct(title, .keep_all = TRUE)
      
      return(results)
    } else {
      message(" Aucun article trouvé dans la section 'À la une'")
      return(data.frame(title = character(), summary = character(), link = character(), date = character()))
    }
    
  }, error = function(e) {
    message(" Erreur lors du scraping: ", e$message)
    return(data.frame(title = character(), summary = character(), link = character(), date = character()))
  })
}

# Fonction pour extraire les résumés des titres
scrape_basta_direct_titles <- function() {
  url <- "https://portail.basta.media/"
  
  tryCatch({
    page <- read_html(url)
    
    message(" Extraction directe des titres 'resume-titre'...")
    
    # Extraire directement tous les titres avec la classe resume-titre
    titles <- page %>% html_elements(".resume-titre") %>% html_text(trim = TRUE)
    
    # Extraire les liens correspondants
    links <- page %>% html_elements(".resume-titre a") %>% html_attr("href")
    
    # Compléter les liens si nécessaire
    links <- map_chr(links, function(link) {
      if (!is.na(link) && !str_detect(link, "^https?://")) {
        if (str_detect(link, "^/")) {
          return(paste0("https://portail.basta.media", link))
        } else {
          return(paste0("https://portail.basta.media/", link))
        }
      }
      return(link)
    })
    
    # Date du jour
    scraped_date <- format(Sys.Date(), "%Y-%m-%d")
    
    # Créer le dataframe
    if (length(titles) > 0) {
      results <- data.frame(
        title = titles,
        summary = NA,  # Les résumés ne sont pas directement disponibles avec cette méthode
        link = links[1:length(titles)],  # S'assurer de la même longueur
        date = scraped_date,
        stringsAsFactors = FALSE
      )
      
      # Limiter aux 5 premiers (la une)
      results <- head(results, 5)
      
      message(" ", nrow(results), " titres extraits directement")
      return(results)
    } else {
      message(" Aucun titre trouvé")
      return(data.frame(title = character(), summary = character(), link = character(), date = character()))
    }
    
  }, error = function(e) {
    message(" Erreur: ", e$message)
    return(data.frame(title = character(), summary = character(), link = character(), date = character()))
  })
}