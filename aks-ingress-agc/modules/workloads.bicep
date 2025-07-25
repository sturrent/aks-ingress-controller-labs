@secure()
param kubeConfig string

param AGC_SUBNET_ID string

extension kubernetes with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource appsDeployment_rabbitmq 'apps/Deployment@v1' = {
  metadata: {
    name: 'rabbitmq'
    namespace: 'aks-store'
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: 'rabbitmq'
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'rabbitmq'
        }
      }
      spec: {
        nodeSelector: {
          'kubernetes.io/os': 'linux'
        }
        containers: [
          {
            name: 'rabbitmq'
            image: 'mcr.microsoft.com/mirror/docker/library/rabbitmq:3.10-management-alpine'
            ports: [
              {
                containerPort: 5672
                name: 'rabbitmq-amqp'
              }
              {
                containerPort: 15672
                name: 'rabbitmq-http'
              }
            ]
            env: [
              {
                name: 'RABBITMQ_DEFAULT_USER'
                value: 'username'
              }
              {
                name: 'RABBITMQ_DEFAULT_PASS'
                value: 'password'
              }
            ]
            resources: {
              requests: {
                cpu: '10m'
                memory: '128Mi'
              }
              limits: {
                cpu: '250m'
                memory: '256Mi'
              }
            }
            volumeMounts: [
              {
                name: 'rabbitmq-enabled-plugins'
                mountPath: '/etc/rabbitmq/enabled_plugins'
                subPath: 'enabled_plugins'
              }
            ]
          }
        ]
        volumes: [
          {
            name: 'rabbitmq-enabled-plugins'
            configMap: {
              name: 'rabbitmq-enabled-plugins'
              items: [
                {
                  key: 'rabbitmq_enabled_plugins'
                  path: 'enabled_plugins'
                }
              ]
            }
          }
        ]
      }
    }
  }
}

resource coreConfigMap_rabbitmqEnabledPlugins 'core/ConfigMap@v1' = {
  data: {
    rabbitmq_enabled_plugins: '[rabbitmq_management,rabbitmq_prometheus,rabbitmq_amqp1_0].\n'
  }
  metadata: {
    name: 'rabbitmq-enabled-plugins'
    namespace: 'aks-store'
  }
}

resource appsDeployment_orderService 'apps/Deployment@v1' = {
  metadata: {
    name: 'order-service'
    namespace: 'aks-store'
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: 'order-service'
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'order-service'
        }
      }
      spec: {
        nodeSelector: {
          'kubernetes.io/os': 'linux'
        }
        containers: [
          {
            name: 'order-service'
            image: 'ghcr.io/azure-samples/aks-store-demo/order-service:latest'
            ports: [
              {
                containerPort: 3000
              }
            ]
            env: [
              {
                name: 'ORDER_QUEUE_HOSTNAME'
                value: 'rabbitmq'
              }
              {
                name: 'ORDER_QUEUE_PORT'
                value: '5672'
              }
              {
                name: 'ORDER_QUEUE_USERNAME'
                value: 'username'
              }
              {
                name: 'ORDER_QUEUE_PASSWORD'
                value: 'password'
              }
              {
                name: 'ORDER_QUEUE_NAME'
                value: 'orders'
              }
              {
                name: 'FASTIFY_ADDRESS'
                value: '0.0.0.0'
              }
            ]
            resources: {
              requests: {
                cpu: '1m'
                memory: '50Mi'
              }
              limits: {
                cpu: '75m'
                memory: '128Mi'
              }
            }
          }
        ]
        initContainers: [
          {
            name: 'wait-for-rabbitmq'
            image: 'busybox'
            command: [
              'sh'
              '-c'
              'until nc -zv rabbitmq 5672; do echo waiting for rabbitmq; sleep 2; done;'
            ]
            resources: {
              requests: {
                cpu: '1m'
                memory: '50Mi'
              }
              limits: {
                cpu: '75m'
                memory: '128Mi'
              }
            }
          }
        ]
      }
    }
  }
}

resource appsDeployment_productService 'apps/Deployment@v1' = {
  metadata: {
    name: 'product-service'
    namespace: 'aks-store'
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: 'product-service'
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'product-service'
        }
      }
      spec: {
        nodeSelector: {
          'kubernetes.io/os': 'linux'
        }
        containers: [
          {
            name: 'product-service'
            image: 'ghcr.io/azure-samples/aks-store-demo/product-service:latest'
            ports: [
              {
                containerPort: 3002
              }
            ]
            resources: {
              requests: {
                cpu: '1m'
                memory: '1Mi'
              }
              limits: {
                cpu: '2m'
                memory: '20Mi'
              }
            }
          }
        ]
      }
    }
  }
}

resource appsDeployment_storeFront 'apps/Deployment@v1' = {
  metadata: {
    name: 'store-front'
    namespace: 'aks-store'
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: 'store-front'
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'store-front'
        }
      }
      spec: {
        nodeSelector: {
          'kubernetes.io/os': 'linux'
        }
        containers: [
          {
            name: 'store-front'
            image: 'ghcr.io/azure-samples/aks-store-demo/store-front:latest'
            ports: [
              {
                containerPort: 8080
                name: 'store-front'
              }
            ]
            env: [
              {
                name: 'VUE_APP_ORDER_SERVICE_URL'
                value: 'http://order-service:3000/'
              }
              {
                name: 'VUE_APP_PRODUCT_SERVICE_URL'
                value: 'http://product-service:3002/'
              }
            ]
            resources: {
              requests: {
                cpu: '1m'
                memory: '200Mi'
              }
              limits: {
                cpu: '1'
                memory: '512Mi'
              }
            }
          }
        ]
      }
    }
  }
}

resource coreService_rabbitmq 'core/Service@v1' = {
  metadata: {
    name: 'rabbitmq'
    namespace: 'aks-store'
  }
  spec: {
    selector: {
      app: 'rabbitmq'
    }
    ports: [
      {
        name: 'rabbitmq-amqp'
        port: 5672
        targetPort: 5672
      }
      {
        name: 'rabbitmq-http'
        port: 15672
        targetPort: 15672
      }
    ]
    type: 'ClusterIP'
  }
}

resource coreService_orderService 'core/Service@v1' = {
  metadata: {
    name: 'order-service'
    namespace: 'aks-store'
  }
  spec: {
    type: 'ClusterIP'
    ports: [
      {
        name: 'http'
        port: 3000
        targetPort: 3000
      }
    ]
    selector: {
      app: 'order-service'
    }
  }
}

resource coreService_productService 'core/Service@v1' = {
  metadata: {
    name: 'product-service'
    namespace: 'aks-store'
  }
  spec: {
    type: 'ClusterIP'
    ports: [
      {
        name: 'http'
        port: 3002
        targetPort: 3002
      }
    ]
    selector: {
      app: 'product-service'
    }
  }
}

resource coreService_storeFront 'core/Service@v1' = {
  metadata: {
    name: 'store-front'
    namespace: 'aks-store'
  }
  spec: {
    ports: [
      {
        port: 80
        targetPort: 8080
      }
    ]
    selector: {
      app: 'store-front'
    }
  }
}

resource albNetworkingAzureIoApplicationLoadBalancer_albTest 'alb.networking.azure.io/ApplicationLoadBalancer@v1' = {
  metadata: {
    name: 'alb-test'
    namespace: 'alb-test-infra'
  }
  spec: {
    associations: [
      '${AGC_SUBNET_ID}'
    ]
  }
}

resource networkingK8sIoIngress_storeFront 'networking.k8s.io/Ingress@v1' = {
  metadata: {
    name: 'store-front'
    namespace: 'aks-store'
    annotations: {
      'alb.networking.azure.io/alb-name': 'alb-test'
      'alb.networking.azure.io/alb-namespace': 'alb-test-infra'
    }
  }
  spec: {
    ingressClassName: 'azure-alb-external'
    rules: [
      {
        http: {
          paths: [
            {
              backend: {
                service: {
                  name: 'store-front'
                  port: {
                    number: 80
                  }
                }
              }
              path: '/home'
              pathType: 'Prefix'
            }
          ]
        }
      }
    ]
  }
}
