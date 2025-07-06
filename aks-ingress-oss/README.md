# aks-ingress-oss

 This bicep template is to deploy an AKS cluster with OSS ingress-nginx, and some workloads for troubleshooting ingress controller related issues.

Go to the directory, and run:

```bash
az deployment sub create --name <DEPLOYMENT_NAME> -l <LOCATION> --template-file main.bicep
```

Note: Currently all files are referencing canadacentral location, but it can be change using params.

```bash
az deployment sub create --name aks-ingress-oss -l southcentralus --template-file main.bicep --parameters location='southcentralus'
```
