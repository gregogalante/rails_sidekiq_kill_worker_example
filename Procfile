web: bundle exec rails s -e $RAILS_ENV
worker: bundle exec sidekiq -C config/sidekiq.yml -e $RAILS_ENV
scheduler: IS_SCHEDULER=true bundle exec sidekiq -C config/sidekiq.yml -q scheduled -e $RAILS_ENV
