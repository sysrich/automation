#!/bin/bash
set -euo pipefail

# Downloads the sles12-velum-development image built on IBS
# Args: full path of build-velum-image.sh - Used to compute the path to the download script
# Returns the absolute path to the tarball
# FIXME: this always downloads the image from HEAD. That's because we are
# not building this image on the other branches.
function download_velum_development_image() {
  #TODO: ensure the name of the image downloaded is returned. The wrong image name
  # might be returned if multiple tarballs are into the directory
  $1/../../misc-tools/download_image.py --docker-image-name sles12-velum-development $(realpath $1/../../downloads) velum-development channel://devel
  echo $(realpath $1/../../downloads/sles12-velum-development.*.tar.xz)
}

# docker load of the velum-development image tarball
# Args: full path to the tarball
function load_velum_development_image() {
  docker rmi sles12/velum-development:0.0 || : 2> /dev/null
  docker rmi sles12/velum:development || : 2> /dev/null
  docker load -i $1
}

function build_fresh_image() {
  echo "Building velum image with all the required gems"
  # Reuse the gems already vendored into the devel image if possible.
  # This will pull only the development gems and the ones changed on master.
  # This greatly reduces the creation time of the image
  local CONTAINER_BUILD=`docker run -v $VELUM_DIR:/srv/velum-latest -d sles12/velum-development:0.0 \
                    bash -c "
                      cd /srv/velum-latest && \
                      mkdir -p /var/lib/velum && \
                      cp -r /srv/velum/vendor/bundle/ruby /var/lib/velum/ && \
                      bundle config --local frozen 0 && \
                      bundle config --local build.nokogiri --use-system-libraries && \
                      bundle install --binstubs=/usr/local/bin --deployment --path=/var/lib/velum && \
                      cp Gemfile.lock /var/lib/velum/ && \
                      wget -q https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 -P /opt && \
                      tar -xjf /opt/phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /opt && \
                      mv /opt/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin && \
                      rm -rf /opt/phantomjs-2.1.1-linux-x86_64"`
  docker logs -f $CONTAINER_BUILD
  docker commit $CONTAINER_BUILD sles12/velum:development_wip
  docker rm $CONTAINER_BUILD
}

function patch_schema() {
  # The only reason for the existence of this patch is a very nasty hack that needs to be removed
  # as soon as possible.
  #
  # It is very closely tied to this patch existence:
  # https://github.com/kubic-project/velum/blob/master/packaging/suse/patches/1_set_default_salt_events_alter_time_column_value.rpm.patch
  #
  # The problem
  #
  # We are patching the production schema. But we are mounting the development source code from the
  # host. So, when we run `bin/init`, the schema that gets loaded is the one on the developers machine,
  # that of course doesn't contain this patch. Without this patch, the salt-master fails to register
  # events on the database, due to a missing default value on `alter_time` column.
  #
  # The schema salt requires is: https://docs.saltstack.com/en/latest/ref/returners/all/salt.returners.mysql.html
  #
  # CREATE TABLE `salt_events` (
  # `id` BIGINT NOT NULL AUTO_INCREMENT,
  # `tag` varchar(255) NOT NULL,
  # `data` mediumtext NOT NULL,
  # `alter_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  # `master_id` varchar(255) NOT NULL,
  # PRIMARY KEY (`id`),
  # KEY `tag` (`tag`)
  # ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
  #
  # We are handling this table as if it was another Rails managed table, so it's in the Rails schema.
  #
  # So far, so good. The main problem is that Rails 4 does not support functions as default values.
  # This means that if we patch the development environment, after running a migration, or running
  # `db:schema:dump`, Rails won't recover this default value, and the schema it writes will be wrong.
  # The good news is that this is fixed in Rails 5.
  #
  # Without this patch, salt-master refuses to create new salt events, with the error:
  #
  # [ERROR ] Could not store events - returner 'mysql.event_return' raised exception:
  #          (1364, "Field 'alter_time' doesn't have a default value")
  #
  # The solution
  #
  # Use the production container that has the production schema (patched). Copy it on `/var/lib/velum`,
  # since we will mount our source code in `/srv/velum` and the original `/srv/velum/db/schema.rb`
  # won't be available, and then infect `bin/init` script to run `db:schema:load` with the
  # `/var/lib/velum/schema.rb` schema if it exists; otherwise run a `db:load` without specifying the
  # schema (that will take `/srv/velum/db/schema.rb` by default), so we don't break the default
  # behavior.
  #
  # Commit the sles12/velum:development image again, as if nothing ever happened.

  echo "Patching schema of velum image"
  local CONTAINER_BUILD=`docker run -d sles12/velum:development_wip cp /srv/velum/db/schema.rb /var/lib/velum`
  docker logs -f $CONTAINER_BUILD
  docker commit $CONTAINER_BUILD sles12/velum:development_wip
  docker rm $CONTAINER_BUILD
}

# Set special environment variables needed to find the gems we vendored
# into a different location
# Creates also the sles/velum:latest image
function set_env_variables() {
  echo "Adding special env variables into the final image"

  local TMP_DIR=`mktemp -d`
  cat << EOF > $TMP_DIR/Dockerfile
FROM sles12/velum:development_wip
ENV BUNDLE_FROZEN 1
ENV BUNDLE_PATH /var/lib/velum
ENV BUNDLE_DISABLE_SHARED_GEMS 1
EOF
  docker build -t sles12/velum:development $TMP_DIR

  # this image is now useless - it can be untagged
  docker rmi sles12/velum:development_wip

  rm -rf $TMP_DIR
}

function save_image() {
  rm -f velum-resources/velum-development.tar
  docker save sles12/velum:development -o velum-resources/velum-development.tar
  chmod 644 velum-resources/velum-development.tar
  echo "Velum image saved to velum-resources/velum-development.tar"
}


# Parse args
USE_CACHE=0

while getopts ":c" opt; do
  case $opt in
    c)
      USE_CACHE=1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done
shift $(expr $OPTIND - 1 )

VELUM_DIR=$1
if [ ! -d "$VELUM_DIR" ]; then
  echo "Velum directory $VELUM_DIR does not exist"
  exit 1
fi

if [[ $USE_CACHE -eq 1 && -f $(dirname $0)/../velum-resources/velum-development.tar ]]; then
  echo "Using prebuilt image"
  exit 0
fi

echo "Downloading latest build of the velum development image"
TARBALL=$(download_velum_development_image $(dirname $0))
load_velum_development_image $TARBALL

build_fresh_image

# FIXME: remove this once we upgrade to Rails 5
patch_schema

set_env_variables

save_image
