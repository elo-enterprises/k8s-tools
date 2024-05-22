Bonus
Context Management for Host Shells
We've talked about container shells, but project-based manipulation of *host* shells can also be useful.
If your project requires several environment variables (say `KUBECONFIG` & `CLUSTER_NAME`), you can drop into a host shell *starting* from the Makefile using `make shell` and you'll have access to those variables, or a subset of those variables, without jamming stuff into your bashrc.  It's not just a convenience, but it's also *safer* than potentially mixing up your dev/prod KUBECONFIGs =)

```Makefile
# myproject/Makefile (Make sure you have real tabs, not spaces!)

bash:
	@# Full shell, inheriting the parent environment (including `export`s from this Makefile)
  env bash -l

ibash:
  @# An isolated shell, no environment passed through.
	env -i bash -l

pbash:
  @# Passing a partial environment, only the $USER var
	env -i `env|grep USER` bash -l
```

Now if you want to ensure that you've switched context as appropriate, you can run `make bash` from your project root.

-------------------------------------------------------------
