#!/usr/bin/ruby

require "sqlite3"
adj_file = "./adjectives"
noun_file = "./nouns"
db_file = "./nebula.sqlite"
subdomain_table = "subdomain"


begin


  unless File.exist? db_file
    SQLite3::Database.new db_file
  end

  db = SQLite3::Database.open db_file

  db.execute "CREATE TABLE IF NOT EXISTS #{subdomain_table}(subdomain_name TEXT)"

  db.execute "CREATE UNIQUE INDEX IF NOT EXISTS `domain_name` ON `#{subdomain_table}` (`subdomain_name` ASC)"

  if (File.exist? adj_file) && (File.exist? noun_file)
    adj_words = (File.read adj_file).split(' ')
    noun_words = (File.read noun_file).split(' ')

    rs = 1

    begin
      i = Random.new.rand(0..adj_words.length-1)
      j = Random.new.rand(0..noun_words.length-1)

      subdomain_name = "#{adj_words[i]}_#{noun_words[j]}"
      puts subdomain_name
      rs = db.execute "SELECT COUNT(*) FROM #{subdomain_table} WHERE subdomain_name='#{subdomain_name}'"

    end while rs == 1

    unless rs == 1
      db.execute "INSERT INTO #{subdomain_table}(subdomain_name) VALUES('#{subdomain_name}')"
    end

  else
    puts "Cannot find dictionary files '#{adj_file}' and '#{noun_file}'"
  end

rescue => e
  puts "Error: #{e}"
end