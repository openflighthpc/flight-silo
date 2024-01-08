require 'yaml'

hash = {
  "items" => []
}

File.open('testc/test.yaml', 'w') do |file|
  file.write(hash.to_yaml)
end
