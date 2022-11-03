# exchange-concourse-resource

## About

A custom [Concourse](https://concourse-ci.org/) Resource Type for [Anypoint Exchange](https://www.mulesoft.com/exchange/).

Resources represent all external inputs to and outputs of jobs in the pipeline. Concourse comes with a few "core" resource types (e.g. git and s3), the rest are developed and supported by the Concourse [Community](https://resource-types.concourse-ci.org/).

Concourse Resource Types are implemented by a Docker container image with 3 scripts:

1. `/opt/resource/check` for checking for new versions of the resource
2. `/opt/resource/in` for pulling a version of the resource down
3. `/opt/resource/out` for idempotently pushing a version up

See [Resource Types](https://concourse-ci.org/resource-types.html) for additional information.

## Description

This Concourse Resource Type can be used for **get** & **put** operations of Mule Application assets in Anypoint Exchange. Application assets are identified using [Maven Coordinates](https://maven.apache.org/pom.html#Maven_Coordinates):

1. **G**roup Id (= Platform Organization Id)
2. **A**rtifact Id
3. **V**ersion

### `Check` Operation

The **check** operation checks the Exchange repository for new(er) versions of the application asset.

* **Sample Payload**
    ```
    {
        "source": {
            "artifact_id": "mule4-workerinfo",
            "client_id": "[CLIENT ID]",
            "client_secret": "[CLIENT SECRET]",
            "group_id": "[ANYPOINT ORG ID]",
            "uri": "anypoint.mulesoft.com"
        },
        "version": {
            "ref": "1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c"
        }
    }
    ```

* **Sample Response**
    ```
    [
        {
            "ref": "1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c"
        }
    ]
    ```

* **Sample Output**
    ```
    Exchange Concourse Resource 'check' settings
    - Using URI: anypoint.mulesoft.com
    - Using CLIENT_ID: [CLIENT ID]
    - Using CLIENT_SECRET: [CLIENT SECRET]
    - Using GROUP_ID: [ANYPOINT GROUP ID]
    - Using ARTIFACT_ID: mule4-workerinfo

    get_token_for_connected_app
    in - client_id: [CLIENT ID]
    in - client_secret: [CLIENT SECRET]
    post - endpoint: https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token
    out - token: [OAUTH TOKEN]

    check_application_asset_from_exchange
    in - group_id: [ANYPOINT GROUP ID]
    in - artifact_id: mule4-workerinfo
    get - endpoint: https://anypoint.mulesoft.com/exchange/api/v2/assets/8cc90329 ... 5db10edc3257/mule4-workerinfo/asset
    out - response: [
    {
        "ref": "1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c"
    }
    ]
    ```

### `In` Operation

The **in** operation checks the Exchange repository for existing application assets.

* **Sample Payload**
    ```
    {
        "source": {
            "artifact_id": "mule4-workerinfo",
            "client_id": "[CLIENT ID]",
            "client_secret": "[CLIENT SECRET]",
            "group_id": "[ANYPOINT GROUP ID]",
            "uri": "anypoint.mulesoft.com"
        },
        "version": {
            "ref": "1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c"
        }
    }
    ```

* **Sample Response**
    ```
    {
        "version": {
            "ref": "1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c"
        },
        "metadata": [
            {
                "name": "group_id",
                "value": "[ANYPOINT GROUP ID]"
            },
            {
                "name": "artifact_id",
                "value": "mule4-workerinfo"
            }
        ]
    }
    ```

* **Sample Output**
    ```
    Exchange Concourse Resource 'in' settings
    - Using URI: anypoint.mulesoft.com
    - Using CLIENT_ID: [CLIENT ID]
    - Using CLIENT_SECRET: [CLIENT SECRET]
    - Using GROUP_ID: [GROUP ID]
    - Using ARTIFACT_ID: mule4-workerinfo

    get_token_for_connected_app
    in - client_id: [CLIENT ID]
    in - client_secret: [CLIENT SECRET]
    post - endpoint: https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token
    out - token: [OAUTH TOKEN]

    fetch_application_asset_version_in_exchange
    in - group_id: [ANYPOINT GROUP ID]
    in - artifact_id: mule4-workerinfo
    get - endpoint: https://anypoint.mulesoft.com/exchange/api/v2/assets/8cc90329 ... 5db10edc3257/mule4-workerinfo/asset
    out - response: {   "version": { "ref": "1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c" },   "metadata": [     { "name": "group_id", "value": "[ANYPOINT GROUP ID]"},     { "name": "artifact_id", "value": "mule4-workerinfo" }   ] }
    ```

### `Out` Operation

The **out** operation publishes the application asset to the Exchange repository.

* **Sample Payload**
    ```
    {
        "source": {
            "artifact_id": "mule4-workerinfo",
            "client_id": "[CLIENT ID]",
            "client_secret": "[CLIENT SECRET]",
            "group_id": "[ANYPOINT GROUP ID]",
            "uri": "anypoint.mulesoft.com"
        }
    }
    ```

* **Sample Response**
    ```
    {
        "version": {
            "ref": "1.0.2-rc.1-mule4-workerinfo"
        },
        "metadata": [
            {
                "name": "group_id",
                "value": "[ANYPOINT GROUP ID]"
            },
            {
                "name": "artifact_id",
                "value": "mule4-workerinfo"
            }
        ]
    }
    ```

* **Sample Output**
    ```
    Exchange Concourse Resource 'out' settings
    - Using URI: anypoint.mulesoft.com
    - Using CLIENT_ID: [CLIENT ID]
    - Using CLIENT_SECRET: [CLIENT SECRET]
    - Using GROUP_ID: [ANYPOINT GROUP ID]
    - Using ARTIFACT_ID: mule4-workerinfo
    - Using VERSION: 1.0.2-rc.1
    - Using REVISION: 4198581b5c7804800ece1cc716eb939b9e017b8c

    get_token_for_connected_app
    in - client_id: [CLIENT ID]
    in - client_secret: [CLIENT SECRET]
    post - endpoint: https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token
    out - token: [OAUTH TOKEN]

    _publish_application_pom_to_exchange
    in - group_id: [ANYPOINT GROUP ID]
    in - artifact_id: mule4-workerinfo
    in - version: 1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c
    put - endpoint: https://maven.anypoint.mulesoft.com/api/v1/organizations/8cc90329 ... 5db10edc3257/maven/[ANYPOINT GROUP ID]/mule4-workerinfo/1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c/mule4-workerinfo-1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c.pom
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    100   694    0     0  100   694      0    462  0:00:01  0:00:01 --:--:--   462

    _publish_application_jar_to_exchange
    in - group_id: 8cc90329 ... 5db10edc3257
    in - artifact_id: mule4-workerinfo
    in - version: 1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c
    in - binary: /tmp/build/put/build-and-test-output/mule4-workerinfo-1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c-mule-application.jar
    put - endpoint: https://maven.anypoint.mulesoft.com/api/v1/organizations/8cc90329 ... 5db10edc3257/maven/8cc90329 ... 5db10edc3257/mule4-workerinfo/1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c/mule4-workerinfo-1.0.2-rc.1-4198581b5c7804800ece1cc716eb939b9e017b8c-mule-application.jar
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    100 60.8M    0     0  100 60.8M      0  2135k  0:00:29  0:00:29 --:--:-- 1394k
    ```

## Usage

## Docker Steps

### Docker Registry (Optional)

Docker images are typically uploaded to a central artifact repository. The following steps are optional and describe how to setup a **local** Docker registry and how to push the Anypoint Exchange Resource image to this **local** registry.

#### Create Certificate

The local Docker registry can be accessed by external processes via HTTP/TLS, a self-signed certificate / key pair can be used, e.g.:

```
$ openssl req -x509 -nodes -new -keyout domain.key -out domain.crt -days 365 -config san.cnf
```

```
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = NL
ST = NH
L = The Hague
O = MuleSoft
OU = Integration
CN = docker.registry.com
[v3_req]
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = docker.registry.com
```

**Note**: SAN/DNS + NO passphrase required

#### Start the Docker Registry

The `run` command can be used to start the local Docker registry + HTTP/TLS listen process based on the previously created certificate / key pair:

```
$ docker run -d \
  --restart=always \
  --name registry \
  -v "$(pwd)"/certs:/certs \
  -e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -p 10443:443 \
  registry:2
```

**Note**: the above example binds host port **10443** to container port 443, this can be any unused port of the host system

#### Update '/etc/hosts'

Add an entry for `docker.registry.com`, e.g.:

```
localhost   docker.registry.com
```

### Docker Image (Manual)

#### Create Docker Image

Execute the Docker build command to build the Docker image, e.g.:

```
$ docker build -t exchange-concourse-resource . --no-cache
```

#### Tag Docker Image

The Docker image must be 'tagged' using the (local) Docker registry reference (e.g. `docker.registry.com:10443`), e.g.: 

```
$ docker tag exchange-concourse-resource docker.registry.com:10443/exchange-concourse-resource
```

#### Push Image to (Local) Docker Registry

Push the Docker image to the (local) Docker registry, e.g.:

```
$ docker push docker.registry.com:10443/exchange-concourse-resource
```

### Docker Image (Concourse)

See [ci](ci/) for 
building and publishing this custom Concourse Resource Type image to a Docker repository using a Concourse pipeline.

## Example Pipelines

See [mule-concourse-pipeline-example](https://github.com/mulesoft-catalyst/mule-concourse-pipeline-example/) for 
pipeline examples for **Mule 4** applications.



