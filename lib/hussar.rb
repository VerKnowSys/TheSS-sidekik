require "hussar/version"

require "json"
require "fileutils"
require "hashie"

require "hussar/base"
require "hussar/inner"
require "hussar/addon"
require "hussar/shell"
require "hussar/cron"
require "hussar/dependencies"
require "hussar/ports"

# Load addons
include Hussar::DSL

require "hussar/addons/mysql"
require "hussar/addons/redis"
require "hussar/addons/elasticsearch"
require "hussar/addons/logstash"
require "hussar/addons/memcached"
require "hussar/addons/mongodb"
require "hussar/addons/postgresql"
require "hussar/addons/nginx"
