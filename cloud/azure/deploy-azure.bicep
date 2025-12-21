@description('Location for all resources')
param location string = resourceGroup().location

@description('Sekha Controller Image Tag')
param imageTag string = 'latest'

@description('Database Admin Password')
@secure()
param dbPassword string

// Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'sekhacr${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: 'sekha-db-${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_B2s'
    tier: 'Burstable'
  }
  properties: {
    version: '16'
    administratorLogin: 'sekhaadmin'
    administratorLoginPassword: dbPassword
    storage: {
      storageSizeGB: 32
    }
  }
}

resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-03-01-preview' = {
  parent: postgresServer
  name: 'sekha'
}

// Azure Container Instances - Controller
resource sekhaController 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: 'sekha-controller'
  location: location
  properties: {
    containers: [
      {
        name: 'controller'
        properties: {
          image: 'ghcr.io/sekha-ai/sekha-controller:${imageTag}'
          ports: [
            {
              port: 8080
              protocol: 'TCP'
            }
          ]
          environmentVariables: [
            {
              name: 'RUST_LOG'
              value: 'info'
            }
            {
              name: 'DATABASE_URL'
              secureValue: 'postgresql://sekhaadmin:${dbPassword}@${postgresServer.properties.fullyQualifiedDomainName}:5432/sekha'
            }
            {
              name: 'VECTOR_DB_URL'
              value: 'http://${chromaContainer.properties.ipAddress.ip}:8000'
            }
          ]
          resources: {
            requests: {
              cpu: 2
              memoryInGB: 4
            }
          }
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Always'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: 8080
          protocol: 'TCP'
        }
      ]
      dnsNameLabel: 'sekha-${uniqueString(resourceGroup().id)}'
    }
  }
}

// Azure Container Instances - ChromaDB
resource chromaContainer 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: 'sekha-chroma'
  location: location
  properties: {
    containers: [
      {
        name: 'chroma'
        properties: {
          image: 'chromadb/chroma:latest'
          ports: [
            {
              port: 8000
              protocol: 'TCP'
            }
          ]
          environmentVariables: [
            {
              name: 'IS_PERSISTENT'
              value: 'TRUE'
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Always'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: 8000
          protocol: 'TCP'
        }
      ]
    }
  }
}

// Azure Cache for Redis
resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: 'sekha-redis-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: {
      name: 'Basic'
      family: 'C'
      capacity: 0
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    redisVersion: '7'
  }
}

output controllerUrl string = 'http://${sekhaController.properties.ipAddress.fqdn}:8080'
output databaseHost string = postgresServer.properties.fullyQualifiedDomainName
output redisHost string = redisCache.properties.hostName
