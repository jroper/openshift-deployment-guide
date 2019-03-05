
if oc get secret shopping-cart-application-secret &> /dev/null
then
    echo "Shopping cart application secret already created"
else
    #create-application-secret
    oc create secret generic shopping-cart-application-secret --from-literal=secret="$(openssl rand -base64 48)"
    #create-application-secret
fi