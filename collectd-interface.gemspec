Gem::Specification.new do |s|
  s.name = %q{collectd-interface}
  s.version = "0.3.0"
  s.authors = ["Victor Penso"]
  s.date = '2012-02-22'
  s.homepage = 'https://github.com/vpenso/collectd-interface'
  s.email = 'vic.penso@gmail.com'
  s.licenses = 'GPLv3'
  s.description = <<-EOF
  EOF
  s.summary = %q{Web and REST interface to data stored by Collectd.}
  s.default_executable = %q{collectd-interface-daemon}
  s.executables = [
    'collectd-interface-daemon',
    'collectd-interface-plugins'
  ]
  s.add_dependency('sinatra', '>= 1.3')
  s.requirements << 'Collectd  (http://collectd.org)'
  s.files = Dir.glob('**/*/**')
  s.has_rdoc = false
  s.extra_rdoc_files = [ 'README.md' ]
  s.rdoc_options << 
    '--line-numbers' <<
    '--inline-source' <<
    '--title' << 'Collectd Interface'
  s.require_paths = ['views/']
  s.rubyforge_project = %q{collectd-interface}
end
