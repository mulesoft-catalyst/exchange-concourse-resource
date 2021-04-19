#!/usr/bin/env bash

RESPONSE=$(mktemp /tmp/exchange-concourse-resource-response.XXXXXX)

get_token_for_user() {
    local username="$1"
    local password="$2"
    local endpoint="https://${3}/accounts/login"

    printf "get_token_for_user\n"
    printf "   in - username: ${username}\n"
    printf "   in - password: ****************\n"
    printf " post - endpoint: ${endpoint}\n"
    
    local body="{ 
        \"username\": \"${username}\",
        \"password\": \"${password}\"
    }"
    local status=$(curl --location --request POST "${endpoint}" \
        --output ${RESPONSE} --silent --write-out "%{http_code}" \
        --header "Content-Type: application/json" \
        --data-raw "${body}")
    if [ ${status} != '200' ]; then
        printf "  err - ${status}: $(cat $RESPONSE)\n"
        exit 1
    else
        ACCESS_TOKEN=$(cat $RESPONSE | jq -r '.access_token')
        printf "  out - token: ${ACCESS_TOKEN}\n"
        export ACCESS_TOKEN 
    fi
}

get_token_for_connected_app() {
    local client_id="$1"
    local client_secret="$2"
    local endpoint="https://${3}/accounts/api/v2/oauth2/token"

    printf "get_token_for_connected_app\n"
    printf "   in - client_id: ${client_id}\n"
    printf "   in - client_secret: ****************\n"
    printf " post - endpoint: ${endpoint}\n"
    
    local body="{ 
        \"client_id\": \"${client_id}\",
        \"client_secret\": \"${client_secret}\",
        \"grant_type\": \"client_credentials\"
    }"
    local status=$(curl --location --request POST "${endpoint}" \
        --output ${RESPONSE} --silent --write-out "%{http_code}" \
        --header "Content-Type: application/json" \
        --data-raw "${body}")
    if [ ${status} != '200' ]; then
        printf "  err - ${status}: $(cat $RESPONSE)\n"
        exit 1
    else
        ACCESS_TOKEN=$(cat $RESPONSE | jq -r '.access_token')
        printf "  out - token: ${ACCESS_TOKEN}\n"
        export ACCESS_TOKEN
    fi
}

_publish_application_jar_to_exchange() {
    local group_id="${2}"
    local artifact_id="${3}"
    local version="${4}"
    local binary="${5}"
    local endpoint="https://maven.${1}/api/v1/organizations/${group_id}/maven/${group_id}/${artifact_id}/${version}/${artifact_id}-${version}-mule-application.jar"

    printf "_publish_application_jar_to_exchange\n"
    printf "   in - group_id: ${group_id}\n"
    printf "   in - artifact_id: ${artifact_id}\n"
    printf "   in - version: ${version}\n"
    printf "   in - binary: ${binary}\n"
    printf "  put - endpoint: ${endpoint}\n"

    local body=${binary}
    local status=$(curl --location --request PUT "${endpoint}" \
        --output ${RESPONSE} --write-out "%{http_code}" \
        --header "Authorization: bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/java-archive" \
        --data-binary "@${body}")
    if [ ${status} != '200' ]; then
        printf "  err - ${status}: $(cat $RESPONSE)\n"
        exit 1
    fi
}

_publish_application_pom_to_exchange() {
    local group_id="${2}"
    local artifact_id="${3}"
    local version="${4}"
    local endpoint="https://maven.${1}/api/v1/organizations/${group_id}/maven/${group_id}/${artifact_id}/${version}/${artifact_id}-${version}.pom"

    printf "_publish_application_pom_to_exchange\n"
    printf "   in - group_id: ${group_id}\n"
    printf "   in - artifact_id: ${artifact_id}\n"
    printf "   in - version: ${version}\n"
    printf "  put - endpoint: ${endpoint}\n"

    local body="<?xml version=\"1.0\" encoding=\"UTF-8\"?> \
        <project xmlns=\"http://maven.apache.org/POM/4.0.0\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd\"> \
            <modelVersion>4.0.0</modelVersion> \
            <groupId>${group_id}</groupId> \
            <artifactId>${artifact_id}</artifactId> \
            <version>${version}</version> \
            <name>${artifact_id}</name> \
            <properties> \
                <type>app</type> \
                <name>${artifact_id}</name> \
            </properties> \
        </project>"
    local status=$(curl --location --request PUT "${endpoint}" \
        --output ${RESPONSE} --write-out "%{http_code}" \
        --header "Authorization: bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: text/xml" \
        --data-raw "${body}")
    if [ ${status} != '200' ]; then
        printf "  err - ${status}: $(cat $RESPONSE)\n"
        exit 1
    fi
}

_download_application_asset_from_exchange() {
    local group_id="${3}"
    local artifact_id="${4}"
    local version="${5}"
    local endpoint="${1}"
    local packaging="${2}"
    
    printf "   _download_application_asset_from_exchange\n"
    printf "      in - group_id: ${group_id}\n"
    printf "      in - artifact_id: ${artifact_id}\n"
    printf "      in - version: ${version}\n"
    printf "      in - packaging: ${packaging}\n"
    printf "     get - endpoint: ${endpoint}\n"

    local filename=${artifact_id}-${version}.${packaging}
    local status=$(curl --write-out " - %{http_code}\n"  --location --request GET "${endpoint}" \
        --output ${filename} --silent --write-out "%{http_code}" \
        --header "Authorization: bearer ${ACCESS_TOKEN}")
    if [ ${status} != '200' ]; then
        printf "     err - ${status}: $(cat $RESPONSE)\n"
        exit 1
    else
        printf "     out - ${filename} (file)\n"
    fi
}

publish_application_asset_to_exchange() {
    _publish_application_pom_to_exchange $1 $2 $3 $4 && \
    printf "\n" &&  \
    _publish_application_jar_to_exchange $1 $2 $3 $4 $5 
}

application_asset_exists_in_exchange() {
    local group_id="${2}"
    local artifact_id="${3}"
    local version="${4}"
    local endpoint="https://${1}/graph/api/v1/graphql"

    printf "application_asset_exists_in_exchange\n"
    printf "   in - group_id: ${group_id}\n"
    printf "   in - artifact_id: ${artifact_id}\n"
    printf "   in - version: ${version}\n"
    printf " post - endpoint: ${endpoint}\n"

    local body="{ \
        \"query\": \"{ \
            assets ( \
                asset: { \
                    groupId: \\\"${group_id}\\\", \
                    assetId: \\\"${artifact_id}\\\", \
                    version: \\\"${version}\\\" \
                } \
            ) \
            {organizationId groupId assetId version} \
        }\" \
    }"
    local status=$(curl --location --request POST "${endpoint}" \
        --output ${RESPONSE} --silent --write-out "%{http_code}" \
        --header "Authorization: bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data-raw "${body}")
    if [ ${status} != '200' ]; then
        printf "  err - ${status}: $(cat $RESPONSE)\n"
        exit 1
    else
        local count=$(cat $RESPONSE | jq -r '.data | length')
        if [ ${count} -ge "1" ]; then
            export EXISTS=true
        else
            export EXISTS=false
        fi
        printf "  out - exists: ${EXISTS}\n"
    fi
}

retrieve_application_asset_from_exchange() {
    local group_id="${2}"
    local artifact_id="${3}"
    local version="${4}"
    local endpoint="https://${1}/exchange/api/v2/assets/${group_id}/${artifact_id}/asset"

    printf "retrieve_application_asset_from_exchange\n"
    printf "   in - group_id: ${group_id}\n"
    printf "   in - artifact_id: ${artifact_id}\n"
    printf "   in - version: ${version}\n"
    printf " post - endpoint: ${endpoint}\n"

    local body="{ \
        \"query\": \"{ \
            assets ( \
                asset: { \
                    groupId: \\\"${group_id}\\\", \
                    assetId: \\\"${artifact_id}\\\", \
                    version: \\\"${version}\\\" \
                } \
            ) \
            {organizationId groupId assetId version} \
        }\" \
    }"
    local status=$(curl --location --request GET "${endpoint}" \
        --output ${RESPONSE} --silent --write-out "%{http_code}" \
        --header "Authorization: bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data-raw "${body}")
    if [ ${status} != '200' ]; then
        printf "  err - ${status}: $(cat $RESPONSE)\n"
        exit 1
    else
        local versionfound=$(cat $RESPONSE | jq -r '.version')
        local match=false
        if [ "${version}" != "${versionfound}" ]; then
            local assetversion=${versionfound}
            for k in $(jq '.versions | keys | .[]' ${RESPONSE}); do 
                assetversion=$(jq -r ".versions[$k]" ${RESPONSE});
                if [ "${version}" == "${assetversion}" ]; then
                    match=true
                    break
                fi
            done   
        else
            match=true
        fi

        if [ ${match} == true ]; then
            printf "  out - match: yes\n"
            for k in $(jq '.files | keys | .[]' ${RESPONSE}); do
                local value=$(jq -r ".files[$k]" ${RESPONSE});
                local downloadurl=$(jq -r '.downloadURL' <<< "$value");
                if [ ${version} != ${versionfound} ]; then
                    downloadurl=$(echo ${downloadurl/$versionfound/$version})
                fi
                local packaging=$(jq -r '.packaging' <<< "$value");
                printf "  out - packaging: ${packaging}\n"
                printf "  out - download url: ${url}\n"
                _download_application_asset_from_exchange "${downloadurl}" "${packaging}" "${group_id}" "${artifact_id}" "${version}"
            done 
        else
            printf "  out - match: => no\n"
        fi
    fi
}

check_application_asset_versions_in_exchange() {
    local group_id="${2}"
    local artifact_id="${3}"
    local endpoint="https://${1}/exchange/api/v2/assets/${group_id}/${artifact_id}/asset"

    printf "check_application_asset_from_exchange\n"
    printf "   in - group_id: ${group_id}\n"
    printf "   in - artifact_id: ${artifact_id}\n"
    printf "  get - endpoint: ${endpoint}\n"

    local body="{ \
        \"query\": \"{ \
            assets ( \
                asset: { \
                    groupId: \\\"${group_id}\\\", \
                    assetId: \\\"${artifact_id}\\\" \
                } \
            ) \
            {organizationId groupId assetId version} \
        }\" \
    }"
    local status=$(curl --location --request GET "${endpoint}" \
        --output ${RESPONSE} --silent --write-out "%{http_code}" \
        --header "Authorization: bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data-raw "${body}")
    if [ ${status} != '200' ]; then
        printf "  err - ${status}: $(cat $RESPONSE)\n"
        exit 1
    else
        local versionfound=$(cat $RESPONSE | jq -r '.version')
        VERSIONS=("${versionfound}")
        local assetversion=""
        for k in $(jq '.versions | keys | .[]' ${RESPONSE}); do 
            assetversion=$(jq -r ".versions[$k]" ${RESPONSE});
            VERSIONS=(${VERSIONS[@]} "${assetversion}")
        done   
        export VERSIONS
    fi
}

fetch_application_asset_version_in_exchange() {
    local group_id="${2}"
    local artifact_id="${3}"
    local endpoint="https://${1}/exchange/api/v2/assets/${group_id}/${artifact_id}/asset"

    printf "fetch_application_asset_version_in_exchange\n"
    printf "   in - group_id: ${group_id}\n"
    printf "   in - artifact_id: ${artifact_id}\n"
    printf "  get - endpoint: ${endpoint}\n"

    local body="{ \
        \"query\": \"{ \
            assets ( \
                asset: { \
                    groupId: \\\"${group_id}\\\", \
                    assetId: \\\"${artifact_id}\\\" \
                } \
            ) \
            {organizationId groupId assetId version} \
        }\" \
    }"
    local status=$(curl --location --request GET "${endpoint}" \
        --output ${RESPONSE} --silent --write-out "%{http_code}" \
        --header "Authorization: bearer ${ACCESS_TOKEN}" \
        --header "Content-Type: application/json" \
        --data-raw "${body}")
    if [ ${status} != '200' ]; then
        printf "  err - ${status}: $(cat $RESPONSE)\n"
        exit 1
    else
        VERSION=("$(cat $RESPONSE | jq -r '.version')")
        export VERSION
    fi
}