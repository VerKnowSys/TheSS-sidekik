require "sidekik/version"

require "json"
require "fileutils"
require "hashie"

require "sidekik/base"
require "sidekik/inner"
require "sidekik/addon"
require "sidekik/service"
require "sidekik/generator"
require "sidekik/shell"
require "sidekik/cron"
require "sidekik/dependencies"
require "sidekik/ports"
require "sidekik/app"
require "sidekik/template"
require "sidekik/tasks"
require "sidekik/hooks"
require "sidekik/export"

include Sidekik::DSL

# Load addons
require "sidekik/addons/mysql"
require "sidekik/addons/redis"
require "sidekik/addons/elasticsearch"
require "sidekik/addons/logstash"
require "sidekik/addons/memcached"
require "sidekik/addons/mongodb"
require "sidekik/addons/postgresql"
require "sidekik/addons/nginx"
require "sidekik/addons/thin"
require "sidekik/addons/puma"
require "sidekik/addons/sidekiq"
require "sidekik/addons/hipchat"

# Load templates
require "sidekik/templates/rack"
require "sidekik/templates/rails3"
