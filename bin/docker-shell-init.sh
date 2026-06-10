# Loaded by: make bash
# All Ruby/Bundler commands run inside the container — no local bundle install.

prepare_test_db() {
  RACK_ENV=test DATABASE_NAME=geolocation_api_test bundle exec rake db:create db:migrate 2>/dev/null || true
}

alias test-db='prepare_test_db'
alias rspec-test='prepare_test_db && RACK_ENV=test DATABASE_NAME=geolocation_api_test IPSTACK_ACCESS_KEY=test bundle exec rspec'
alias coverage-test='prepare_test_db && COVERAGE=true RACK_ENV=test DATABASE_NAME=geolocation_api_test IPSTACK_ACCESS_KEY=test bundle exec rspec'
alias db-seed='bundle exec rake db:seed'
alias db-migrate='bundle exec rake db:migrate'
alias console='bundle exec irb -r ./config/boot'

cat <<'MSG'

Geolocation API — Docker shell (gems already installed)
  rspec-test       run the test suite
  coverage-test    run tests with SimpleCov
  db-seed          re-run seeds
  db-migrate       run pending migrations
  bundle exec ...  any other rake/rspec command

MSG
