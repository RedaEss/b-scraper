# diagnose_basta.R
library(rvest)
library(dplyr)
library(purrr)

diagnose_basta_structure <- function() {
  url <- "https://portail.basta.media/"
  
  tryCatch({
    page <- read_html(url)
    
    message("=== DIAGNOSTIC BASTA MEDIA ===")
    message("URL: ", url)
    message("==============================")
    
    # 1. Analyser la structure globale
    message("\n1. STRUCTURE GLOBALE:")
    containers <- page %>% html_elements("div[class*='container'], section, main, .main, .content")
    message("Conteneurs principaux trouvés: ", length(containers))
    
    # 2. Chercher les sliders
    message("\n2. SLIDERS/CAROUSELS:")
    sliders <- page %>% html_elements("[class*='slider'], [class*='carousel'], [class*='slide']")
    message("Sliders trouvés: ", length(sliders))
    
    if (length(sliders) > 0) {
      walk(sliders, function(slider) {
        classes <- html_attr(slider, "class")
        message("  - Classes: ", classes)
      })
    }
    
    # 3. Chercher les articles
    message("\n3. ARTICLES:")
    articles <- page %>% html_elements("article, [class*='article'], [class*='card'], [class*='news']")
    message("Articles trouvés: ", length(articles))
    
    if (length(articles) > 0) {
      walk(articles[1:3], function(art) {
        classes <- html_attr(art, "class")
        title <- art %>% html_element("h1, h2, h3, h4, [class*='title']") %>% html_text(trim = TRUE)
        message("  - Classes: ", classes)
        message("    Titre: ", substr(title, 1, 50))
      })
    }
    
    # 4. Analyser les titres
    message("\n4. TITRES (h1-h6):")
    titles <- page %>% html_elements("h1, h2, h3, h4, h5, h6")
    message("Titres trouvés: ", length(titles))
    
    walk(titles[1:5], function(title) {
      text <- html_text(title, trim = TRUE)
      classes <- html_attr(title, "class")
      message("  - ", substr(text, 1, 60), " [Classes: ", classes, "]")
    })
    
    # 5. Analyser les liens
    message("\n5. LIENS PRINCIPAUX:")
    links <- page %>% html_elements("a[href*='/article'], a[href*='/news'], a[href*='/blog']")
    message("Liens d'articles trouvés: ", length(links))
    
    if (length(links) > 0) {
      walk(links[1:3], function(link) {
        href <- html_attr(link, "href")
        text <- html_text(link, trim = TRUE)
        message("  - Lien: ", href)
        message("    Texte: ", substr(text, 1, 50))
      })
    }
    
    # 6. Exporter la structure HTML pour inspection
    write_html(page, "basta_structure_diagnostic.html")
    message("\n✅ Structure HTML exportée dans 'basta_structure_diagnostic.html'")
    
  }, error = function(e) {
    message("❌ Erreur lors du diagnostic: ", e$message)
  })
}

# Exécuter le diagnostic
diagnose_basta_structure()