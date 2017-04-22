# Keyword extraction in R

### Background

In February 2014, Democracy for America (the organization I work for) issued an online survey asking progressives "What executive order should President Obama sign next?"

I was tasked with analyzing the responses for common subjects. As the question was formatted as a free-text field, and we received over 10,000 responses, I had a lot of unstructured data to work with.

My first attempt was a straightword examination of the most frequent words, as determined by the total number of distinct responses a word appeared in. Unsurprisingly, the most frequent words turned to be the most common words in the English language (e.g. "the," "and," "for," etc.):

<p align=center><img src=https://raw.githubusercontent.com/alipman88/keyword-extraction/master/raw_frequency.png width=500 /></p>

Next, I removed the 100 most common English words prior to processing the responses. This greatly improved the usefulness of the results. However, many words like "President" and "Obama" crowded out the more meaningful/specific words and phrases, like "fracking," "minimum wage," "keystone pipeline," etc.

Still not satisfied with the results, I looked into text mining strategies that could be applied. [Term frequency–inverse document frequency](https://en.wikipedia.org/wiki/Tf–idf) sounded particularly promising. In short, tf–idf compares word frequencies from a document one wishes to analyze to word frequencies in a selection of sample documents (known as a corpus). Words which occur more frequently in the document being examined than in the corpus are judged to be more relevant to the document's subject matter.

However, having several thousand documents that needed examination, and not having immediate access to a corpus appropriate to subject matter at hand, I needed to fine-tune my approach. With some trial and error, I came up with a ranking scheme that weighted common words based on their associations with other words. Frequently appearing words lacking strong patterns of association were weighted less strongly, while words with more "clustered" associations were ranked higher:

<p align=center><img src=https://raw.githubusercontent.com/alipman88/keyword-extraction/master/specificity.png width=500 /></p>

*The above word cloud includes the 60 words determined to be the most specific or meaningful keywords, with each word's size/shading determined by its frequency. (Common English words were not removed when generating the above image, to demonstrate the effectiveness of the weighting adjustment.)*

The original script was written in Ruby, and as a side-project, re-written in April 2017 in R. (Much of the R code used [this excellent introduction to text mining concepts in R](https://eight2late.wordpress.com/2015/05/27/a-gentle-introduction-to-text-mining-using-r/) for reference.)

### Usage

Install the R text mining library "tm." (Also install "wordcloud," if you wish to generate visual word clouds.)

Place your documents in a line-break separated text file, so that each line corresponds to an individual response. (Remove any line-breaks within an individual response, and replace them with a space.)

Run the keywords.R script, passing the file you wish to examine as a command line argument:

```
Rscript keywords.R obama_next_exec_order.txt
```

This will generate a CSV of common words, with columns for raw frequency and adjusted importance. To generate a word cloud, here's some code one might run in the R console:

```
library("wordcloud")

words <- read.csv("results.csv")

# Create word cloud by raw frequency
wordcloud(
  word = words$word,
  freq = words$frequency,
  min.freq = 1,
  max.words = 100,
  colors = rev(gray.colors(8, start=0.2, end=0.8))
)

# Or by adjusted importance
wordcloud(
  word = words$word,
  freq = words$adjusted_importance,
  min.freq = 1,
  max.words = 100,
  colors = rev(gray.colors(8, start=0.2, end=0.8))
)

# Or by "specificity"
wordcloud(
  word = words$word,
  freq = words$adjusted_importance / words$frequency,
  min.freq = 1,
  max.words = 100,
  colors = rev(gray.colors(8, start=0.2, end=0.8))
)
```