rm -f Makefile.compose.mk Makefile.k8s.mk
rm -f k8s-tools.yml
(ls ${KUBECONFIG} > /dev/null || touch ${KUBECONFIG})  \
&& (cp ../k8s-tools.yml . ) \
&& (cp ../Makefile.*.mk .)