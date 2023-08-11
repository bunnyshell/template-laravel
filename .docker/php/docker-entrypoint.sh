#!/bin/sh

set -e

workdir=$(pwd);

# run pre-release scripts
if [ "${RUN_CACHE_CONFIG:-false}" = "true" ]; then
    echo "caching config"
    cd $workdir && php artisan config:cache;

else
  echo "RUN_CACHE_CONFIG set to false, skipping artisan config:cache"
fi


# run warmup scripts (cache with new env variables)

# run pre-release scripts
if [ "${RUN_WARMUP:-false}" = "true" ]; then
    echo "caching config"
    cd $workdir && php artisan config:cache;

    echo "caching routes"
    cd $workdir && php artisan route:cache;

    echo "caching views"
    cd $workdir && php artisan view:cache;

    echo "caching events"
    cd $workdir && php artisan event:cache;

    echo "caching packages"
    cd $workdir && php artisan package:discover;

    echo "caching bootstrap"
    cd $workdir && php artisan optimize;

    # run warmup scripts (cache with new env variables)
    echo "caching config"
    cd $workdir && php artisan config:cache;

else
  echo "RUN_WARMUP set to false, skipping RUN_WARMUP scripts"
fi



# wait for DB to be ready
timeout 3m sh -c 'until php artisan db:monitor > /dev/null 2>&1; do echo "Waiting for database connection..." && sleep 5; done'
if [ $? -ne 0 ]; then
  echo "timed out while waiting for database to be ready"
  exit 1
fi

# run migrations
if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
  echo "running migrations ..."
  cd $workdir && php artisan migrate;
else
  echo "RUN_MIGRATIONS set to false, skipping migrations"
fi


# run seeding
if [ "${RUN_SEEDING:-false}" = "true" ]; then
  echo "seeding the database ..."
  cd $workdir && php artisan db:seed;
else
  echo "RUN_SEEDING set to false, skipping seeding scripts"
fi


# execute the CMD
exec /usr/local/bin/docker-php-entrypoint "$@"
