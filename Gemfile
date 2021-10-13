source :rubygems

gem "veil", git: "https://github.com/chef/chef_secrets", branch: "main"
gemspec

# TODO: remove when we drop ruby 2.6
if Gem.ruby_version.to_s.start_with?("2.6")
  # 17.0 requires ruby 2.7+
  gem "chef", "< 17"
end

group :development do
  gem "rspec"
  gem "rake"
  gem "simplecov"
end
