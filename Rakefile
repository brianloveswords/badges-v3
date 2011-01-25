# put some server functions in here, will ya?!
HUB_PORT = 4567

task :start do
  ports = {"issuer" => 4568, "hub" => 4567, }
  ['issuer'].each do |service|
    if get_pid(service) and !pid_stale?(service)
      puts "#{service} already started" and return
    else
      start_shotgun(service, ports[service]) and puts "#{service} started"
    end
  end
end

task :stop do
  ['issuer'].each do |service|
    if stop_shotgun(service)
      destroy_pidfile(service)
      puts "#{service} stopped"
    else
      puts "couldn't stop #{service}, is it running? "
    end
  end
end

task :test do
  puts stop_shotgun "issuer"
end

task :stale do
  puts check_stale "issuer"
end

def get_pid service
  return false unless File.exists?("%1$s/%1$s.pid" % service)
  return File.read("%1$s/%1$s.pid" % service).chomp
end

def pid_stale? service
  pid = get_pid "issuer"
  return false unless pid
  cmd = `ps -p #{pid} -o comm=`.chomp
  return cmd != "shotgun"
end

def destroy_pidfile service
  return File.unlink("%1$s/%1$s.pid" % service)
end

def stop_shotgun service
  pid = get_pid(service)
  unless pid
    # puts "#{service} not running"
    return false
  end
  system "kill #{pid}"
end

def start_shotgun service, port
  system "cd %1$s && (shotgun -p#{port} -o127.0.0.1 > /dev/null 2>&1  &  echo $! > %1$s.pid)" % service
end


task :restart => [:stop, :start]
task :default => :start

