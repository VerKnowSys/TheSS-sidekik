require "hussar/version"

require "json"
require "fileutils"
require "hashie"

require "hussar/base"
require "hussar/inner"
require "hussar/addon"
require "hussar/service"
require "hussar/generator"
require "hussar/shell"
require "hussar/cron"
require "hussar/dependencies"
require "hussar/ports"
require "hussar/app"
require "hussar/template"
require "hussar/tasks"
require "hussar/hooks"
require "hussar/export"

include Hussar::DSL

# Load addons
require "hussar/addons/mysql"
require "hussar/addons/redis"
require "hussar/addons/elasticsearch"
require "hussar/addons/logstash"
require "hussar/addons/memcached"
require "hussar/addons/mongodb"
require "hussar/addons/postgresql"
require "hussar/addons/nginx"
require "hussar/addons/thin"
require "hussar/addons/puma"
require "hussar/addons/sidekiq"
require "hussar/addons/hipchat"

# Load templates
require "hussar/templates/rack"
require "hussar/templates/rails3"
