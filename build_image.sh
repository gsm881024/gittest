#!/bin/bash
set -e

# openshift login
oc login https://xxxxxxxxxx:6443 -u xxxxxxxxx -p xxxxxxxxxx

# change project awards-core or awards-dmz
oc project awards-core

# image registry login
podman login -u xxxxxxxxxxx -p $(oc whoami -t) default-route-openshift-image-registry.apps.ocp.xxx.com --tls-verify=false

#######启动带参数#########

if [ -n "$1" ]; then
    SRV_NAME=$1
else
    echo "error：service name is null！"
    exit 1
fi

if [ -n "$2" ]; then
    PKG_FILE=$2
else
    echo "error：service package is null！"
    exit 1
fi

#######判断jar包是否存在########

if [ -f $PKG_FILE ]
then
    echo "$PKG_FILE开始构建......"
else
    echo "$PKG_FILE不存在，请检查"
    exit 1
fi
 
#######构建镜像#########

REGISTRY=${REGISTRY:-"default-route-openshift-image-registry.apps.ocp.cctv.com/"}
PROJECT=${PROJECT:-"awards-core/"}
TAG=${TAG:-`date +%Y%m%d%H%M%S`}
IMAGE=${IMAGE:-"${SRV_NAME}-build"}

echo ${REGISTRY}${PROJECT}${IMAGE}:${TAG}
cp Dockerfile-${SRV_NAME}  Dockerfile
podman build -t ${REGISTRY}${PROJECT}${IMAGE}:${TAG} --build-arg PKG_FILE=$PKG_FILE .

if [ $? -ne 0 ]; then
    echo "构建失败。"
    exit 1
else
    echo "构建成功。"
fi

#######上传镜像#########

podman push ${REGISTRY}${PROJECT}${IMAGE}:${TAG} --tls-verify=false

if [ $? -ne 0 ]; then
   echo "上传镜像仓库失败。"
   exit 1
else
   echo "上传镜像仓库成功。"
fi

#######部署应用########
cp cps-award.core.template.yaml template/cps-award.core.template.yaml.${TAG}
sed -i "s#image-registry.openshift-image-registry.svc:5000/awards-core/${IMAGE}.*#image-registry.openshift-image-registry.svc:5000/awards-core/${IMAGE}:${TAG}#g"  cps-award.core.template.yaml

oc apply -f cps-award.core.template.yaml

oc process cps-openshift-template |oc apply -f -

if [ $? -ne 0 ]; then
   echo "部署失败!!"
   exit 1
else
   echo "部署成功!!"
fi
sdffffffffffffffffffffffffffffffffff
