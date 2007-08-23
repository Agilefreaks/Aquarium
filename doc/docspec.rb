# Helper for webgen doco that works on both windows and posix
# cd ../aquarium && ruby bin/spec
Dir.chdir(File.dirname(__FILE__) + '/../aquarium') do
  puts `ruby bin/spec #{ARGV.join(" ")}`
end
nil
