require "sqlite"
adj = "./adjectives"
noun = "./nouns"

if File.exist? adj && File.exist? noun
  adj_words = File.read adj
  noun_words = File.read noun


else
  puts "Cannot find dictionary files '#{adj}' and '#{noun}'"
end