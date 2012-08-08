require "rubygems"
require "sqlite3"

@db_file = File.expand_path('~') + "/nebula/nebula.sqlite"
@instance_table = "instance"
@base_domain = "nebulatec.us"
@nginx_config_file = "/etc/nginx/sites-enabled/default"

# arg[1] = old domain, arg[2] = new domain
def main(args)
  if args.length != 2
    puts "Error: please input valid parameters"
    return 0
  end

  old_domain, new_domain = args[0], args[1]
  subdomain1 = old_domain.split('.').first
  subdomain2 = new_domain.split('.').first

  begin
    # upaate database entry
    db = SQLite3::Database.open @db_file
    db.execute "UPDATE #{@instance_table} SET subdomain_name='#{subdomain2}' WHERE subdomain_name='#{subdomain1}'"

    # replace nginx config
    if File.exist? @nginx_config_file
      text = File.read(@nginx_config_file)
      replaced_text = text.gsub("#{subdomain1}.#{@base_domain}".downcase, "#{subdomain2}.#{@base_domain}".downcase)
      File.open(@nginx_config_file, "w") { |file| file.puts replaced_text }
    end

    # restart nginx server
    system("sudo /etc/init.d/nginx restart > /dev/null &")

  rescue => e
    puts "Error: failed to reset url from #{old_domain} to #{new_domain}. #{e}"
  end


end


exit(main(ARGV) || 0)