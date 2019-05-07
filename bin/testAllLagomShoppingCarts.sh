#!/bin/bash

set -e

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

runTest() {
    NAME=$1
    shift
    REPO=$1
    shift
    PROJECT=$1
    shift
    mkdir $NAME
    git clone $REPO $NAME
    cd $NAME
    cd $PROJECT
    sed -i "s/myproject/$NAME/" deploy/shopping-cart.yaml
    oc new-project $NAME
    $THIS_SCRIPT_DIR/testLagomShoppingCart.sh -namespace $NAME $@
    oc delete project $NAME
}

# Minishift
runTest shopping-cart-scala https://github.com/lagom/lagom-samples.git shopping-cart/shopping-cart-scala
runTest shopping-cart-java-sbt https://github.com/lagom/lagom-samples.git shopping-cart/shopping-cart-java
runTest shopping-cart-java-maven https://github.com/lagom/lagom-samples.git shopping-cart/shopping-cart-java -maven
