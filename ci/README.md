# exchange-concourse-resource-pipeline

## About

This pipeline has a single job:

1. **build-and-publish-image**

for building and publishing the Docker image containing this custom Concourse Resource Type [exchange-concourse-resource](../README.md).

## Description

### Resources

|No.|Name|Type|Description
|---|---|---|---
|1|**exchange-concourse-resource**|git|Reference to this git repository
|3|**version-resource**|semver|Semver versioning support (git driver)
|4|**docker-image-resource**|docker-image|Docker image resource

### Job Plan - Resources - "build-and-publish-image"

|No.|Step|Description
|---|---|---
|1|**get**: source-code-resource|Get source code to build from git repository
|2|**get**: version-resource|Get version to build using Semver
|3|**put**: docker-image-resource|Build and publish the Docker image to a Docker registry

### Groups
No.|Group|Jobs
|---|---|---
|1|**build-and-publish**|1. build-and-publish-image
|2|**version-management**|1. increase-major-version<br>2. increase-minor-version<br>3. increase-patch-version

## Usage

1. Create a **credentials.yml** file based on the **credentials-template.yml** file, e.g.:

      The **Source** properties refer to Docker iamge to build and publish, e.g.:

      ```
      source-code-resource-private-key: |
            -----BEGIN OPENSSH PRIVATE KEY-----
            -----END OPENSSH PRIVATE KEY-----
      ```

      The **Docker** properties refer to a Docker registry used for Docker image publication (`push`) and verification (`pull`), e.g.:

      ```
      docker-registry-ca-certs:
      - |
            -----BEGIN CERTIFICATE-----
            -----END CERTIFICATE-----
      ```

### Properties

1. Create a **properties.yml** file based on the **properties-template.yml** file, and update the following property sections:

      The **Source** properties refer to Docker iamge to build and publish, e.g.:

      ```
      source-code-resource-uri: git@github.com:example-org/exchange-concourse-resource.git
      source-code-resource-branch: main
      ```

      The **Docker** properties refer to a Docker registry used for Docker image publication (`push`) and verification (`pull`), e.g.:

      ```
      docker-domain: docker.registry.com:10443
      docker-registry-uri: docker.registry.com:10443/exchange-concourse-resource
      ```

### Concourse

1. Create/update pipeline, e.g.:
      ```
      $ fly -t anypoint sp -p exchange-concourse-resource-image -c pipeline.yml -l properties.yml -l credentials.yml
      ```

      The **build-and-publish** group:

      ![Concourse UI - exchange-concourse-resource-image](images/pipeline-a.png)

2. Unpause pipeline, e.g.:
      ```
      $ fly -t anypoint up -p exchange-concourse-resource-image
      ```

3. [ **Optional** ] - Trigger job, e.g.:
      ```
      $ fly -t anypoint tj -j exchange-concourse-resource-image/build-and-publish-image
      ```

4. [ **Optional** ] - Watch job, e.g.:
      ```
      $ fly -t anypoint watch -j exchange-concourse-resource-image/build-and-publish-image
      ```

5. [ **Optional** ] - Destroy pipeline, e.g.:
      ```  
      $ fly -t anypoint dp -p exchange-concourse-resource-image 
      ```