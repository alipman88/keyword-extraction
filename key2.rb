ignored_words = ['']

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

puts '=================='
puts 'word: occurance(%)'
puts '------------------'

# freqs_array.first(50).each {|word, freq| puts word.gsub('_',' ')+': '+(100.0*freq/lines).round(2).to_s}

['marijuana','oil','social_security','minimum_wage','keystone_pipeline','water','s_united','citizens_united','student_loans'].each { |keyword| puts keyword.gsub('_',' ')+': '+(freqs[keyword].to_s) }

puts '=================='
puts 'What word or phrase would you like to learn more about?'
print '> '
phrase = gets.chomp
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
    if words.join(" ").include?(phrase)
      responses_sharing_keyword += 1
      words.each { |word| pos_keywords << word unless (ignored_words + phrase.split(" ")).include?(word) }
    else
      responses_not_sharing_keyword += 1
      words.each { |word| neg_keywords << word unless (ignored_words + phrase.split(" ")).include?(word) }
    end
    pos_keywords.uniq.each { |keyword| unique_positive_occurances[keyword] += 1 }
    neg_keywords.uniq.each { |keyword| unique_negative_occurances[keyword] += 1 }
    # pos_keywords.each { |keyword| positive_occurances[keyword] += 1 }
    # neg_keywords.each { |keyword| negative_occurances[keyword] += 1 }
  end
end
unique_positive_occurances = unique_positive_occurances.sort_by {|x,y| y/responses_sharing_keyword }
unique_positive_occurances.reverse!
puts '=================='
overall_score = 0.0
overall_similarity = 0.0

unique_positive_occurances.each do |word, freq|

  pos_correlation = Math.log(1 + responses_sharing_keyword/freq)
  neg_correlation = Math.log(1 + responses_not_sharing_keyword/unique_negative_occurances[word])

  pos_similarity = freq/responses_sharing_keyword
  neg_similarity = unique_negative_occurances[word]/responses_not_sharing_keyword

  idf = Math.log(total_lines/responses_sharing_keyword)

  importance = (idf) * (pos_correlation - neg_correlation)
  similarity = (idf) * (pos_similarity ** 2 - neg_similarity ** 1)

  overall_score += importance if importance > 0
  overall_similarity += similarity if similarity > 0

  # puts word+': '+similarity.to_s if similarity > 0.1
end
puts '=================='
puts 'score: '+overall_score.to_s
puts 'index: '+overall_similarity.to_s
puts 'combined: '+((overall_similarity**0.5)*overall_score).to_s
