# Scrape lyrics for a whole album in a robust way
genius_album_robust <- function(album_title, album_number, saving_folder = "01 Raw Data/") {
  saving_title <- snakecase::to_snake_case(album_title)
  saving_path <- str_glue("{saving_folder}{ album_number }_{ saving_title }.rds")
  
  # Get as mch as possible at first try
  lyrics_object <- genius_album("The Maine", album_title)
  
  
  while(anyNA(lyrics_object[, 2])) {
    # Get songs that weren't scraped
    to_be_scraped <- lyrics_object %>% 
      filter(is.na(line)) %>%
      pull(track_n, track_title) %>% 
      benelib::to_tibble(row_name = "track_title") %>% 
      rename(track_n = ".")
    
    # Scrape to be scraped (missing) lyrics
    # additional_lyrics <- 
    additional_lyrics <- to_be_scraped %>% 
      mutate(
        lyrics = map(track_title, ~ genius_lyrics("The Maine", .)),
        retrieval = map_lgl(lyrics, ~ if_else(nrow(.) != 0, TRUE, FALSE))
      )
    
    # If only one song is left, check, whether retrieval was succesfull
    if (nrow(additional_lyrics) == 1) {
      while (additional_lyrics %>% pluck("retrieval", 1) == FALSE) {
        additional_lyrics <- additional_lyrics %>% 
          mutate(
            lyrics = map(track_title, ~ genius_lyrics("The Maine", .)),
            retrieval = map_lgl(lyrics, ~ if_else(nrow(.) != 0, TRUE, FALSE))
          )
      }
    }
    
    # Check, if retrieval was succesfull for at least one song
    if (nrow(additional_lyrics) > 1) {
      while (all(additional_lyrics %>% pull("retrieval") == FALSE)) {
        additional_lyrics <- additional_lyrics %>% 
          mutate(
            lyrics = map(track_title, ~ genius_lyrics("The Maine", .)),
            retrieval = map_lgl(lyrics, ~ if_else(nrow(.) != 0, TRUE, FALSE))
          )
      }
    }
    
    # Extract scraped additional lyrics
    to_be_added <- additional_lyrics %>% 
      mutate(
        keep = if_else(map_dbl(lyrics, ~ nrow(.)) != 0, TRUE, FALSE),
        lyrics = map(lyrics, ~ select(., -track_title))
      ) %>%
      filter(keep) %>% 
      select(-keep) %>% 
      unnest(lyrics) %>% 
      select(track_n, line, lyric, track_title)
    
    # Get the names of those additional songs found to filter them from the lyrics
    # object
    added_songs <- to_be_added %>% 
      distinct(track_title) %>% 
      pull(track_title)
    
    # Filter empty line to for to be added songs out and append songs
    lyrics_object <- lyrics_object %>% 
      filter(!(track_title %in% added_songs)) %>% 
      bind_rows(to_be_added)
  }
  
  # Arrange after track and line number
  lyrics_object %>% 
    arrange(track_n, line) %>% 
    mutate(album = album_title) %>% 
    relocate(album, track_title, everything()) %>% 
    filter(!is.na(lyric)) %>% 
    group_by(track_title) %>% 
    mutate(line = row_number()) %>% 
    ungroup() %>% 
    write_rds(file = saving_path)
}