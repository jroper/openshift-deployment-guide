#!/bin/bash

set -e

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

runTest() {
    NAME=$1
    shift
    REPO=$1
    shift
    mkdir $NAME
    git clone $REPO $NAME
    cd $NAME
    sed -i "s/myproject/$NAME/" deploy/shopping-cart.yaml
    oc new-project $NAME
    $THIS_SCRIPT_DIR/testLagomShoppingCart.sh -namespace $NAME $@
    oc delete project $NAME
}

# Minishift
runTest shopping-cart-scala https://github.com/lagom/shopping-cart-scala.git
runTest shopping-cart-java-sbt https://github.com/lagom/shopping-cart-java.git
runTest shopping-cart-java-maven https://github.com/lagom/shopping-cart-java.git -maven
