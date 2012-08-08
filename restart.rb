require "rubygems"
require "sqlite3"

@db_file = File.expand_path('~') + "/nebula/nebula.sqlite"
@instance_table = "instance"

def kill_process(port)
  begin
    output = IO.popen("netstat -nlp |grep :#{port}").readline

    if output.length > 0
      result = output.split(' ')
      result = result.last
      pid = result.split('/').first
      # kill the process
      system("kill -9 #{pid}")
    end
  rescue => e

  end
end

def main(args)
  full_domain, kill = args[0], args[1]
  subdomain = full_domain.split('.').first
  begin
    db = SQLite3::Database.open @db_file
    rs = db.execute "SELECT port, url FROM #{@instance_table} WHERE subdomain_name='#{subdomain}'"
    if rs.length == 0
      puts "Error: failed to restart #{subdomain}. Cannot find instance #{subdomain}"
      return 0
    end
    port, url = rs[0][0], rs[0][1]

    kill_process port

    if kill == "k"
      return 1
    end

    if system("export WEB_PORT=#{port}; node #{url}/app.js &> /dev/null &")
      puts 1
      return 1
    end
    puts 0
  rescue => e
    puts "Error: failed to restart #{subdomain}. #{e}"
    return 0
  end
end

exit(main(ARGV) || 0)