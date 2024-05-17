rm -f Makefile.compose.mk
rm -f k8s-tools.yml
(ls ${KUBECONFIG} || touch ${KUBECONFIG})  \
&& (cp ../docker-compose.yml k8s-tools.yml ) \
&& (cp ../Makefile.*.mk .)
