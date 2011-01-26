# server is hardcoded to shotgun at the moment.
PORTS = {"issuer" => 4568, "hub" => 4567, }

desc "Start the shotgun servers"
task :start do
  ['issuer', 'hub',].each do |service|
    if get_pid(service) and !pid_stale?(service)
      puts "#{service} already started" and return
    else
      start_shotgun(service, PORTS[service]) and puts "#{service} started"
    end
  end
end

desc "Stop the shotgun servers"
task :stop do
  ['issuer', 'hub',].each do |service|
    if stop_shotgun(service)
      destroy_pidfile(service)
      puts "#{service} stopped"
    else
      puts "couldn't stop #{service}, is it running? "
    end
  end
end

desc "Restart the shotgun servers"
task :restart => [:stop, :start]
task :default => :restart


# helpers 
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
  if pid_stale?(service)
    destroy_pidfile(service)
    puts "#{service} pidfile stale, removing"
    return false
  end
  
  unless pid
    # puts "#{service} not running"
    return false
  end
  system "kill #{pid}"
end

def start_shotgun service, port
  system "cd %1$s && (shotgun -p#{port} -o127.0.0.1 > /dev/null 2>&1  &  echo $! > %1$s.pid)" % service
end
