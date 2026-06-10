#!/bin/sh
set -e

echo "Preparing PostgreSQL database..."
bundle exec rake db:create db:migrate

if [ "${RACK_ENV:-development}" = "development" ]; then
  bundle exec rake db:seed
fi

echo "Starting application..."
exec "$@"
