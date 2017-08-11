#!/usr/bin/env ruby

# Small script that ensures the velum:development image is used
# by kubelet instead of the default one.
#
# Written in ruby because yaml is part of the core ruby lib, one less
# thing to install on a brand new machine.

require 'yaml'
require 'optparse'

options = {}
opts_parser = OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename(__FILE__)} [options] <manifest file>"

    opts.on("-oOUTPUT", "--output OUTPUT", "Write patched manifest to specified file") do |o|
      options[:out] = o
    end
end
opts_parser.parse!

if ARGV.size != 1
  puts "Wrong usage"
  puts opts_parser
  exit 1
end

manifest = YAML.load_file(ARGV[0])

# ugly hack to replace production with development inside
# of annotations
# Don't patch this for now, as it changes the DB name from velum_production -> velum_development.
#manifest["metadata"]["annotations"]["pod.beta.kubernetes.io/init-containers"].gsub!("production", "development")

manifest["spec"]["containers"].each do |container|
  if container["image"] =~ /.*velum.*/
    container["image"] = "sles12/velum:development"
    container["volumeMounts"] << {
      "mountPath" => "/srv/velum",
      "name" => "velum-devel",
    }
    container["env"].each do |env|
      env["value"] = "development" if env["name"] == "RAILS_ENV"
    end

    # Ensure the velum_production db is used, this is what the
    # salt mysql returner is configured to use
    container["env"] << {
      "name" => "VELUM_DB_NAME",
      "value" => "velum_production",
    }
  end
end

manifest["spec"]["volumes"] << {
  "name" => "velum-devel",
  "hostPath" => {"path" => "/var/lib/misc/velum-dev" },
}

if options[:out]
  File.open(options[:out], "w") do |out|
    YAML.dump(manifest, out)
  end
else
  puts YAML.dump(manifest)
end
