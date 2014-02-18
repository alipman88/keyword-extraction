ignored_words = ['']

common_words = [
  # hundred most common phrases in english language
  "the", "be", "to", "of", "and", "a", "in", "that", "have", "i", "it", "for", "not", "on", "with", "he", "as", "you", "do", "at", "this", "but", "his", "by", "from", "they", "we", "say", "her", "she", "or", "an", "will", "my", "one", "all", "would", "there", "their", "what", "so", "up", "out", "if", "about", "who", "get", "which", "go", "me", "when", "make", "can", "like", "time", "no", "just", "him", "know", "take", "people", "into", "year", "your", "good", "some", "could", "them", "see", "other", "than", "then", "now", "look", "only", "come", "its", "over", "think", "also", "back", "after", "use", "two", "how", "our", "work", "first", "well", "way", "even", "new", "want", "because", "any", "these", "give", "day", "most", "us"
]

filename = 'next_order.txt'
freqs = Hash.new(0)

lines = 0

File.open(filename) do |f|
  f.each_line do |line|
    lines += 1
    keywords = []
    bi_grams = []
    words = line.split(/[^a-zA-Z]/).map(&:downcase)
    (0...words.length).each do |n|
      bi_grams << (words[n] + '_' + words[n+1]) unless ignored_words.include?(words[n]) || ignored_words.include?(words[n+1] || '')
      keywords << words[n] unless ignored_words.include?(words[n])
    end
    keywords.uniq.each { |k| freqs[k] += 1 }
    bi_grams.uniq.each { |k| freqs[k] += 1 }
  end
end

freqs_array = freqs.sort_by {|x,y| y }
freqs_array.reverse!

words_to_check = []

freqs_array.each do |word, freq|
  percent = (100.0*freq/lines).round(2)
  if percent > 0.5 && ! word.split('_').any? { |part| part.length <= 2 } && ! common_words.any?{ |common_word| word.split('_').include?(common_word) }
    words_to_check << word
    puts word.gsub('_',' ')+': '+percent.to_s
  end
end

puts words_to_check.length

ranked_findings = Hash.new(0)

words_to_check.each do |phrase|

  unique_positive_occurances = Hash.new(0)
  unique_negative_occurances = Hash.new(0)
  positive_occurances = Hash.new(0)
  negative_occurances = Hash.new(0)
  responses_sharing_keyword = 0.0
  responses_not_sharing_keyword = 0.0
  total_lines = 0.0
  File.open(filename) do |f|
    f.each_line do |line|
      words = line.split(/[^a-zA-Z]/).map(&:downcase)
      pos_keywords = []
      neg_keywords = []
      total_lines += 1
      if words.join("_").include?(phrase)
        responses_sharing_keyword += 1
        words.each { |word| pos_keywords << word unless (ignored_words + phrase.split("_")).include?(word) }
      else
        responses_not_sharing_keyword += 1
        words.each { |word| neg_keywords << word unless (ignored_words + phrase.split("_")).include?(word) }
      end
      pos_keywords.uniq.each { |keyword| unique_positive_occurances[keyword] += 1 }
      neg_keywords.uniq.each { |keyword| unique_negative_occurances[keyword] += 1 }
    end
  end
  unique_positive_occurances = unique_positive_occurances.sort_by {|x,y| y/responses_sharing_keyword }
  unique_positive_occurances.reverse!
  overall_score = 0.0
  overall_similarity = 0.0

  unique_positive_occurances.each do |word, freq|

    pos_correlation = Math.log(1 + responses_sharing_keyword/freq)
    neg_correlation = Math.log(1 + responses_not_sharing_keyword/unique_negative_occurances[word])

    pos_similarity = freq/responses_sharing_keyword
    neg_similarity = (unique_negative_occurances[word])/responses_not_sharing_keyword

    idf = Math.log(total_lines/responses_sharing_keyword)

    importance = (idf) * (pos_correlation - neg_correlation)
    similarity = (freq) * (pos_similarity**2 - neg_similarity)

    overall_score += importance if importance > 0

  end

  ranked_findings[phrase] = overall_score
  puts '"'+phrase.gsub('_',' ')+'",'+(100.0*freqs[phrase]/lines).round(2).to_s+','+overall_score.round(2).to_s

end
