# Load text-mining library
library(tm)

args <- commandArgs(trailingOnly = TRUE)
filename <- args[1]

responses.txt <- readLines(filename)
responses.list <- VectorSource(responses.txt)
responses.corpus <- Corpus(responses.list)
responses.length <- length(responses.corpus)

# Custom sanitizer function - replace all non-letter characters with spaces
stripNonLetters <- content_transformer(function(response) { return (gsub("[^a-zA-Z]", " ", response)) })

# Sanitize corpus - strip punctuation, convert to lowercase, and strip excess whitespace
responses.corpus <- tm_map(responses.corpus, tolower)
responses.corpus <- tm_map(responses.corpus, stripNonLetters)
responses.corpus <- tm_map(responses.corpus, stripWhitespace)

# We could also remove common English words, but we won't for the sake of demonstrating our word-ranking
# responses.corpus <- tm_map(responses.corpus, removeWords, stopwords("english"))

# Was the corpus loaded succesfully? Print a randon response
writeLines(as.character(responses.corpus[[sample(1:responses.length, 1)]]))

# Create a document-term matrix
dtm <- DocumentTermMatrix(responses.corpus)

# Transform to R's native data structure for matrices, for faster processing
dtm.mtrx <- as.matrix(dtm)

# Remove duplicate word occurrences from each document
# (If a word occured in a document more than once, set the corresponding matrix element to a value of 1)
dtm.mtrx[dtm.mtrx > 1] <- 1

# Determine the number of distinct responses each word appears in
total_occurrences <- colSums(dtm.mtrx)

# Less efficient way of doing the same thing:
# total_occurrences <- apply(dtm.mtrx, 2, function(x){ sum(x) })

# Identify the words which occur in at least 1% of responses
common_words <- total_occurrences[total_occurrences >= 0.01 * responses.length]

print(paste("Found", length(common_words), "common words"))

# Initialize an empty data frame to store the results
results <- data.frame(word=character(), frequency=double(), adjusted_importance=double())

# For each common word...
for (common_word in names(common_words)) {
  # Count the distinct number of responses the common word occurs and doesn't occur in
  responses_sharing_keyword     <- common_words[common_word]
  responses_not_sharing_keyword <- responses.length - responses_sharing_keyword

  # For each word in the document term matrix, identify the responses in which it co-occurs with the common word
  co_occurrences <- subset(dtm.mtrx, dtm.mtrx[,common_word] == 1)
  # Determine the raw number of co-occurrences
  co_occurrences.count <- colSums(co_occurrences)
  # Remove any words that didn't co-occur at least once
  co_occurrences.filtered <- subset(co_occurrences.count, co_occurrences.count > 0)

  # Repeat the above transformations, but this time for each instance a word in the document term matrix didn't co-occur with the common word
  non_co_occurrences <- subset(dtm.mtrx, dtm.mtrx[,common_word] == 0)
  non_co_occurrences.count <- colSums(non_co_occurrences)
  non_co_occurrences.filtered <- subset(non_co_occurrences.count, non_co_occurrences.count > 0)

  overall_score <- 0.0

  for (word in names(co_occurrences.filtered)) {
    # Estimate the specificity of the co-occurring word, based on co-occurrence with other words in the document term matrix
    pos_correlation <- log(1 + responses_sharing_keyword / co_occurrences.filtered[word])
    neg_correlation <- log(1 + responses_not_sharing_keyword / non_co_occurrences.filtered[word])
    specificity <- pos_correlation - neg_correlation

    # Calculate the common word's inverse document frequency
    idf <- log(responses.length / responses_sharing_keyword)

    # Gauge the common word's importance
    importance <- idf * specificity

    # If the importance of the co-occuring word is positive, add it to the common word's overall score
    if (!is.na(importance) && importance > 0) {
      overall_score <- overall_score + importance
    }
  }

  print(paste(common_word, responses_sharing_keyword, round(overall_score)))

  # Append to the results dataset
  results <- rbind(results, data.frame(word=common_word, frequency=responses_sharing_keyword, adjusted_importance=overall_score))
}

write.csv(results, file="results.csv", row.names=FALSE)
