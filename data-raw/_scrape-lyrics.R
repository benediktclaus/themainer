library(tidyverse)
library(genius)
library(lubridate)

source("03 R/helper-functions.R")




# Discography from Wikipedia ----------------------------------------------
tribble(
  ~ album, ~type,         ~ released,   ~ label,
  "Can't Stop Won't Stop", "Studio Album", "2008-07-08", "Fearless",
  "Black & White", "Studio Album", "2010-07-12", "Warner Bros.",
  "Pioneer", "Studio Album", "2011-12-02", "Action Theory",
  "Forever Halloween", "Studio Album", "2013-03-04", "8123",
  "American Candy", "Studio Album", "2015-03-31", "8123",
  "Lovely Little Lonely", "Studio Album", "2017-04-07", "8123",
  "You Are OK", "Studio Album", "2019-03-29", "8123",
  "Stay Up, Get Down", "Extended Play", "2007-05-08", "Self-released",
  "The Way We Talk", "Extended Play", "2007-12-11", "Fearless",
  "...And A Happy New Year", "Extended Play", "2008-12-08", "Fearless",
  "This is Real Life", "Extended Play", "2009-12-07", "Fearless",
  "Daytrotter Sessions", "Extended Play", "2010-09-07", "Daytrotter",
  "In Darkness & in Light", "Extended Play", "2010-12-27", "Warner Bros.",
  "Good Love (The Pioneer B-Sides)", "Extended Play", "2012-09-11", "Fearless",
  "Imaginary Numbers", "Extended Play", "2013-12-10", "8123",
  "Covers", "Extended Play", "2016-06-24", "8123",
  "...And To All A Good Night", "Extended Play", "2017-12-15", "8123"
) %>%
  mutate(released = as_date(released)) %>%
  arrange(released) %>%
  relocate(label, .after = album) %>%
  write_rds("01 Raw Data/maine_discography.rds")




# Scrape Lyrics from Genius -----------------------------------------------
# Some albums must run multiple times if they throw an error
genius_album_robust(album_number = "01", album_title = "Stay Up, Get Down")
genius_album_robust(album_number = "02", album_title = "The Way We Talk")
genius_album_robust(album_number = "03", album_title = "Can't Stop Won't Stop")
genius_album_robust(album_number = "04", album_title = "...And A Happy New Year")
genius_album_robust(album_number = "05", album_title = "Black And White")
genius_album_robust(album_number = "06", album_title = "In Darkness And In Light")
genius_album_robust(album_number = "07", album_title = "Pioneer")
genius_album_robust(album_number = "08", album_title = "Good Love (The Pioneer B-Sides) EP")
genius_album_robust(album_number = "09", album_title = "Forever Halloween")
genius_album_robust(album_number = "10", album_title = "Imaginary Numbers")
genius_album_robust(album_number = "11", album_title = "American Candy")
genius_album_robust(album_number = "12", album_title = "Covers")
genius_album_robust(album_number = "13", album_title = "Lovely Little Lonely")
genius_album_robust(album_number = "14", album_title = "...And To All A Good Night")
genius_album_robust(album_number = "15", album_title = "Less Noise: A Collection of Songs by a Band Called The Maine")
genius_album_robust(album_number = "16", album_title = "You Are OK")




# Join Discohraphy and Lyrics ---------------------------------------------
# Read in all lyrics files and correct album names for proper joining
complete_lyrics <- fs::dir_ls("01 Raw Data/", regexp = "disco", invert = TRUE) %>%
  map_df(read_rds) %>%
  mutate(
    album = str_replace(album, "Black.*", "Black & White"),
    album = str_replace(album, "In Darkness.*", "In Darkness & in Light"),
    album = str_replace(album, "Good Love.*", "Good Love (The Pioneer B-Sides)")
  )

# Read in the complete discography
discography <- read_rds("01 Raw Data/maine_discography.rds")

# Join discography and lyrics
discography %>%
  left_join(complete_lyrics, by = "album") %>%
  write_rds("02 Data/the_maine_lyrics.rds")




# Load Lyrics for Package -------------------------------------------------
the_maine <- read_rds("data-raw/the_maine_lyrics.rds")
use_data(the_maine, overwrite = TRUE)
