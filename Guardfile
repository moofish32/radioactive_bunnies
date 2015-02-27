guard :rspec, cmd: 'rspec' do

   watch(%r|^spec/(.*)_spec\.rb|)
   watch(%r|^lib/(.*)([^/]+)\.rb|)     { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
   watch(%r|^spec/spec_helper\.rb|)    { "spec" }
end

guard 'coffeescript', :input => 'lib/frenzy_bunnies/web/public/js', :output => 'lib/frenzy_bunnies/web/public/js', :all_on_start => true
