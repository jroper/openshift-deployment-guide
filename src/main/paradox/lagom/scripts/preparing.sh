
#create-application-secret
oc create secret generic shopping-cart-application-secret --from-literal=secret="$(openssl rand -base64 48)"
#create-application-secret