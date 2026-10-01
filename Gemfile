source "https://rubygems.org"

gem "fastlane"

# json 2.8+ fails to build its native extension against the Ruby 3.2 headers here
# (duplicate static declarations of rb_hash_bulk_insert / rb_str_to_interned_str).
gem "json", "~> 2.7.0"
