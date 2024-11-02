#!/bin/bash

# A simple deployment script for Laravel applications


##########################
# Configuration
##########################

WORKDIR=$HOME/public



##########################
# Main 
##########################

cd $WORKDIR

# Fetch the latest changes from the remote repository
git fetch

# Check if there are any new changes
if [ $(git rev-parse HEAD) != $(git rev-parse @{u}) ]; then
    # Pull the new changes
    echo "Pulling changes.."
    git pull
    # Enable maintenance mode
    php artisan down

    # Install dependencies
    echo "Installing dependencies.."
    composer install --no-interaction --no-dev --prefer-dist --ignore-platform-reqs
    npm install

    # Migrate database
    echo "Migrating database.."
    php artisan migrate --force

    # Regenerate cache
    echo "Clearing cache.."
    php artisan optimize:clear
    php artisan optimize

    # Build frontend assets
    echo "Building frontend assets.."
    npm run build

    # Restart queue worker
    echo "Restarting queue worker.."
    supervisorctl restart all

    # Start the application again
    echo "Disabling maintenance mode.."
    php artisan up

    echo "Deployment completed successfully!"
else
    echo "No changes found"
fi