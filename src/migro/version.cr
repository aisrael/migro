module Migro
  VERSION = {{ `cat ./shard.yml|grep ^version:|awk '{print $2}'`.stringify }}
end
