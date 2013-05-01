# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'minitest' do
  watch(%r|^test/(.*)\/?test_(.*)\.rb|)
  watch(%r|^lib/(.*)([^/]+)\.rb|)            { |m| "test/#{m[1]}test_#{m[2]}.rb" }
  watch(%r|^lib/docusign_rest/(.+)\.rb$|)    { |m| "test/docusign_rest/#{m[1]}_test.rb" }
  watch(%r|^test/helper\.rb|)                { "test" }
end
