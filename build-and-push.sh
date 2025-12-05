#!/bin/bash


# PiggyMetrics 微服务镜像构建和推送脚本
# 将所有服务镜像构建并推送到ECR仓库的latest版本

set -e  # 遇到错误立即退出

# ECR仓库配置（请根据实际情况修改）
ECR_REGISTRY="409237390679.dkr.ecr.us-east-1.amazonaws.com"
REPO_PREFIX="piggymetrics"

# 服务列表（从pom.xml的modules中获取）
SERVICES=(
    "config"
#    "monitoring"
#    "registry"
    "gateway"
#    "auth-service"
#    "account-service"
#    "statistics-service"
#    "notification-service"
#    "turbine-stream-service"
)

# 颜色输出函数
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查AWS CLI是否安装
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI未安装，请先安装AWS CLI"
        exit 1
    fi
}

# 检查Docker是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
}

# 登录ECR
login_to_ecr() {
    log_info "登录到ECR仓库..."
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "${ECR_REGISTRY}"
    if [ $? -eq 0 ]; then
        log_success "ECR登录成功"
    else
        log_error "ECR登录失败"
        exit 1
    fi
}


# 构建Maven项目
build_maven() {
    log_info "开始构建Maven项目..."
    mvn clean package -DskipTests
    if [ $? -eq 0 ]; then
        log_success "Maven构建成功"
    else
        log_error "Maven构建失败"
        exit 1
    fi
}

# 获取git commit ID（缩写前7位）
get_git_commit_id() {
    local commit_id=$(git rev-parse --short HEAD 2>/dev/null)
    if [ -z "$commit_id" ]; then
        log_warning "无法获取git commit ID，使用'test'作为默认值"
        echo "test"
    else
        echo "$commit_id"
    fi
}

# 构建Docker镜像
build_docker_image() {
    local service=$1
    local commit_id=$(get_git_commit_id)
    local image_name_latest="${ECR_REGISTRY}/${REPO_PREFIX}/${service}:latest"
    local image_name_commit="${ECR_REGISTRY}/${REPO_PREFIX}/${service}:${commit_id}"

    log_info "构建 ${service} 镜像..."
    log_info "Commit ID: ${commit_id}"

    cd "${service}"
    # 构建镜像并添加两个标签
    docker build -t "${image_name_latest}" -t "${image_name_commit}" .
    if [ $? -eq 0 ]; then
        log_success "${service} 镜像构建成功（标签: latest, ${commit_id}）"
    else
        log_error "${service} 镜像构建失败"
        exit 1
    fi
    cd ..
}

# 推送Docker镜像到ECR
push_docker_image() {
    local service=$1
    local commit_id=$(get_git_commit_id)
    local image_name_latest="${ECR_REGISTRY}/${REPO_PREFIX}/${service}:latest"
    local image_name_commit="${ECR_REGISTRY}/${REPO_PREFIX}/${service}:${commit_id}"

    log_info "推送 ${service} 镜像到ECR..."
    
    # 推送latest标签
    docker push "${image_name_latest}"
    if [ $? -eq 0 ]; then
        log_success "${service} latest标签推送成功"
    else
        log_error "${service} latest标签推送失败"
        exit 1
    fi
    
    # 推送commit ID标签
    docker push "${image_name_commit}"
    if [ $? -eq 0 ]; then
        log_success "${service} ${commit_id}标签推送成功"
    else
        log_error "${service} ${commit_id}标签推送失败"
        exit 1
    fi
}



# 主函数
main() {
    log_info "开始PiggyMetrics镜像构建和推送流程"

    # 前置检查
    check_aws_cli
    check_docker

    # 登录ECR
    login_to_ecr

    # 构建Maven项目
    build_maven

    # 逐个构建和推送服务镜像
    for service in "${SERVICES[@]}"; do
        log_info "=== 处理服务: ${service} ==="

        # 构建Docker镜像
        build_docker_image "${service}"

        # 推送镜像到ECR
        push_docker_image "${service}"

        log_success "${service} 处理完成"
        echo
    done

    log_success "所有服务镜像构建和推送完成！"

    # 显示镜像列表
    local commit_id=$(get_git_commit_id)
    log_info "已推送的镜像列表（Commit ID: ${commit_id}）："
    for service in "${SERVICES[@]}"; do
        echo "  - ${ECR_REGISTRY}/${REPO_PREFIX}/${service}:latest"
        echo "  - ${ECR_REGISTRY}/${REPO_PREFIX}/${service}:${commit_id}"
    done
}

# 执行主函数
main "$@"