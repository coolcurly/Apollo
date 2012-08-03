#!/usr/bin/ruby


require "sqlite3"
require "fileutils"

@adj_file = "./adjectives"
@noun_file = "./nouns"
@db_file = "./nebula.sqlite"
@instance_table = "instance"
@base_port = 3000
#@nginx_config_file = "/etc/nginx/sites-enabled/default"
@nginx_config_file = "./test"
@base_domain = "nebulatec.us"
@server_template = "#Instance: %s
server {
  listen  80;
  server_name %s;
  location / {
    proxy_pass: http://127.0.0.1:%s;
  }
}"


def open_db
  unless File.exist? @db_file
    SQLite3::Database.new @db_file
  end

  db = SQLite3::Database.open @db_file

  db.execute "CREATE TABLE IF NOT EXISTS #{@instance_table}(user_name varchar(64), instance_name varchar(64), url varchar(4096), subdomain_name varchar(64), port integer)"

  db.execute "CREATE UNIQUE INDEX IF NOT EXISTS `idx_subdomain_name` ON `#{@instance_table}` (`subdomain_name` ASC)"

  db.execute "CREATE UNIQUE INDEX IF NOT EXISTS `idx_url` ON `#{@instance_table}` (`url` ASC)"

  return db
end

def generate_subdomain

  if (File.exist? @adj_file) && (File.exist? @noun_file)
    adj_words = (File.read @adj_file).split(' ')
    noun_words = (File.read @noun_file).split(' ')

    rs = 1

    begin
      i = Random.new.rand(0..adj_words.length-1)
      j = Random.new.rand(0..noun_words.length-1)

      subdomain_name = "#{adj_words[i]}_#{noun_words[j]}"
      puts subdomain_name
      rs = @db.execute "SELECT COUNT(*) FROM #{@instance_table} WHERE subdomain_name='#{subdomain_name}'"

    end while rs[0][0] == 1

    return subdomain_name

    #unless rs == 1
    #  db.execute "INSERT INTO #{@instance_table}(subdomain_name) VALUES('#{subdomain_name}')"
    #end

  else
    raise "Cannot find dictionary files '#{@adj_file}' and '#{@noun_file}'"
  end
end

def get_port
  rs = @db.execute "SELECT COUNT(*) FROM #{@instance_table}"
  return rs[0][0] + @base_port
end


def write_nginx_config(instance_url, domain_name, port)
  if File.exist? @nginx_config_file
    File.open(@nginx_config_file, "r") do |file|
      line = file.gets
      if line.include? instance_url
        return
      end
    end
  end


  File.open(@nginx_config_file, 'a') do |file|
    file.puts @server_template % [instance_url, domain_name, port]
  end
end

def main(args)
  begin
    if args.length != 3
      raise "Please pass in 'user name', 'instance name' and 'instance address' as parameters"
    end
    user_name, instance_name, url = args[0], args[1], args[2]

    @db = open_db

    rs = @db.execute "SELECT port FROM #{@instance_table} WHERE url='#{url}'"

    if rs.length > 0
      return rs[0][0]
    end

    port = get_port
    subdomain_name = generate_subdomain

    write_nginx_config(url, "#{subdomain_name}.#{@base_domain}", port)

    @db.execute "INSERT INTO #{@instance_table} VALUES('#{user_name}', '#{instance_name}', '#{url}', '#{subdomain_name}', '#{port}')"

    return port
  rescue => e
    puts "Error: #{e}"
  end
  return 0
end

exit(main(ARGV))
