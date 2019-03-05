#!/bin/bash

# Test script for automatically verifying the Lightbend OpenShift guide against any of the Lagom shopping cart apps.
# It should be run from the shopping cart example application directory.

set -e

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PARADOX_DIR="$THIS_SCRIPT_DIR/../src/main/paradox"

SETUP_POSTGRES=1
# Also means log in as admin to do it and install Kafka
INSTALL_STRIMZI=1
INSTALL_KAFKA=1
INSTALL_KAFKA_REQUIRES_ADMIN=1
KAFKA_NODES=1

INSTALL_SHOPPING_CART=1
INSTALL_INVENTORY=1

RUN_TESTS=1

SBT=1
DOCKER_REPO_URL=minishift
NAMESPACE=myproject

. $THIS_SCRIPT_DIR/util.sh

while [ $# -gt 0 ];
do
    case "$1" in
        "-skip-postgres")
            SETUP_POSTGRES=0
            ;;
        "-skip-strimzi")
            INSTALL_STRIMZI=0
            ;;
        "-skip-kafka")
            INSTALL_KAFKA=0
            ;;
        "-skip-shopping-cart")
            INSTALL_SHOPPING_CART=0
            ;;
        "-skip-inventory")
            INSTALL_INVENTORY=0
            ;;
        "-skip-tests")
            RUN_TESTS=0
            ;;
        "-maven")
            SBT=0
            ;;
        "-sbt")
            SBT=1
            ;;
        "-docker")
            shift
            DOCKER_REPO_URL=$1
            ;;
        "-minishift")
            shift
            DOCKER_REPO_URL=minishift
            ;;
        "-centralpark")
            INSTALL_STRIMZI=0
            INSTALL_KAFKA_REQUIRES_ADMIN=0
            DOCKER_REPO_URL=docker-registry-default.centralpark.lightbend.com
            ;;
        "-kafka-nodes")
            shift
            KAFKA_NODES=$1
            ;;
        "-install-kafka-without-admin")
            shift
            INSTALL_KAFKA_REQUIRES_ADMIN=0
            ;;
        "-namespace")
            shift
            NAMESPACE="$1"
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage:"
            echo "$0 [OPTIONS]"
            echo
            echo "Supported options:"
            echo "-skip-postgres            - Don't setup PostgreSQL"
            echo "-skip-strimzi             - Don't install Strimzi"
            echo "-skip-kafka               - Don't install a Kafka instance"
            echo "-kafka-nodes <nodes>      - Either one or three, defaults to one"
            echo "-install-kafka-without-admin - Do not login as admin user to install Kafka"
            echo "-skip-shopping-cart       - Don't install the shopping cart service"
            echo "-skip-inventory           - Don't install the inventory service"
            echo "-maven                    - Use Maven"
            echo "-sbt                      - Use sbt (default)"
            echo "-docker <url>             - Use the docker registry at <url>"
            echo "-centralpark              - Run using centralpark configuration"
            echo "-namespace <namespace>    - Use the given namespace instead of myproject"
            echo "-skip-tests               - Don't run the tests"
            exit 1
            ;;
    esac
    shift
done

if [ $SETUP_POSTGRES == 1 ]
then
    . $PARADOX_DIR/includes/scripts/postgresql.sh
fi

. $PARADOX_DIR/includes/scripts/kafka.sh

if [ $INSTALL_SHOPPING_CART == 1 ]
then
    . $PARADOX_DIR/lagom/scripts/preparing.sh
fi

. $PARADOX_DIR/includes/scripts/building.sh


. $PARADOX_DIR/lagom/scripts/deploying.sh