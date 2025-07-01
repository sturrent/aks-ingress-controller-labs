# aks-ingress-app-routing

 This bicep template is to deploy an AKS cluster with the App routing add-on, and some workloads for troubleshooting ingress controller related issues.

Go to the directory, and run:

```bash
az deployment sub create --name <DEPLOYMENT_NAME> -l <LOCATION> --template-file main.bicep
```

Note: Currently all files are referencing canadacentral location, but it can be change using params.

```bash
az deployment sub create --name aks-egress-lab -l southcentralus --template-file main.bicep --parameters location='southcentralus'
```
