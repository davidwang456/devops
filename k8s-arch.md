# Kubernetes 架构及内部原理详解

本篇文档详细介绍 Kubernetes 的整体架构及其核心组件的内部原理，并为每个组件附带详细的代码来源说明，便于深入理解和源码追踪。

---

## 一、Kubernetes 总体架构

Kubernetes 采用分布式、去中心化的架构，主要由以下核心组件组成：

- kube-apiserver
- kube-controller-manager
- kube-scheduler
- kubelet
- kube-proxy
- etcd（分布式存储，非K8s自身实现）

各组件之间通过 API 进行通信，协同完成容器编排、调度、管理等功能。

---

## 二、核心组件详解及源码位置

### 1. kube-apiserver

**作用**：集群的 API 网关，所有资源操作的唯一入口，负责认证、授权、准入控制、API 处理、数据持久化等。

**主要源码位置**：
- 入口：`cmd/kube-apiserver/`
- 主要实现：`pkg/kubeapiserver/`
- API 定义：`pkg/apis/`、`api/`

**关键源码说明**：
- [cmd/kube-apiserver/apiserver.go](cmd/kube-apiserver/apiserver.go)：apiserver 启动入口。
- [pkg/kubeapiserver/server.go](pkg/kubeapiserver/)：apiserver 核心逻辑，包括认证、授权、准入、存储等。
- [pkg/kubeapiserver/options/](pkg/kubeapiserver/options/)：apiserver 各种启动参数和配置。
- [pkg/kubeapiserver/authenticator/](pkg/kubeapiserver/authenticator/)：认证实现。
- [pkg/kubeapiserver/authorizer/](pkg/kubeapiserver/authorizer/)：授权实现。

**内部原理简述**：
1. 启动时加载配置，初始化认证、授权、准入、存储等模块。
2. 监听 HTTP/HTTPS 请求，所有请求统一进入 RESTful API 处理流程。
3. 经过认证、授权、准入控制后，操作 etcd 存储资源对象。
4. 通过 watch 机制为各组件提供资源变更通知。

---

### 2. kube-controller-manager

**作用**：集群控制器的运行总管，负责各种资源对象的自动化控制循环（如副本、节点、命名空间、Job等）。

**主要源码位置**：
- 入口：`cmd/kube-controller-manager/`
- 控制器实现：`pkg/controller/`

**关键源码说明**：
- [cmd/kube-controller-manager/controller-manager.go](cmd/kube-controller-manager/): 启动入口。
- [pkg/controller/](pkg/controller/): 各类控制器实现（如deployment、replicaset、job、namespace等）。
- [pkg/controller/controller_utils.go](pkg/controller/controller_utils.go): 控制器通用工具函数。

**内部原理简述**：
1. 启动时注册所有内置控制器。
2. 每个控制器通过 informer/watch 机制监听资源变化。
3. 控制循环不断对比期望状态和实际状态，驱动集群向期望状态收敛。

---

### 3. kube-scheduler

**作用**：负责为新创建的 Pod 选择合适的节点。

**主要源码位置**：
- 入口：`cmd/kube-scheduler/`
- 实现：`pkg/scheduler/`

**关键源码说明**：
- [cmd/kube-scheduler/scheduler.go](cmd/kube-scheduler/): 启动入口。
- [pkg/scheduler/scheduler.go](pkg/scheduler/scheduler.go): scheduler 核心调度逻辑。
- [pkg/scheduler/schedule_one.go](pkg/scheduler/schedule_one.go): 单个 Pod 的调度实现。
- [pkg/scheduler/framework/](pkg/scheduler/framework/): 调度框架插件机制。

**内部原理简述**：
1. 监听未调度的 Pod。
2. 通过调度算法和插件筛选、打分节点，选择最优节点。
3. 通过 apiserver 更新 Pod 的 Node 绑定。

---

### 4. kubelet

**作用**：每个节点上的 agent，负责 Pod 的具体创建、运行、监控和上报。

**主要源码位置**：
- 入口：`cmd/kubelet/`
- 实现：`pkg/kubelet/`

**关键源码说明**：
- [cmd/kubelet/kubelet.go](cmd/kubelet/): 启动入口。
- [pkg/kubelet/kubelet.go](pkg/kubelet/kubelet.go): kubelet 核心逻辑。
- [pkg/kubelet/pod_workers.go](pkg/kubelet/pod_workers.go): Pod 生命周期管理。
- [pkg/kubelet/kuberuntime/](pkg/kubelet/kuberuntime/): 容器运行时接口。

**内部原理简述**：
1. 监听 apiserver 下发的 Pod 任务。
2. 调用 CRI 容器运行时接口创建、管理容器。
3. 定期上报节点和 Pod 状态。
4. 管理本地存储、网络、健康检查等。

---

### 5. kube-proxy

**作用**：负责为 Service 提供集群内部的服务发现和负载均衡。

**主要源码位置**：
- 入口：`cmd/kube-proxy/`
- 实现：`pkg/proxy/`

**关键源码说明**：
- [cmd/kube-proxy/proxy.go](cmd/kube-proxy/): 启动入口。
- [pkg/proxy/](pkg/proxy/): 核心代理逻辑。
- [pkg/proxy/iptables/](pkg/proxy/iptables/): iptables 模式实现。
- [pkg/proxy/ipvs/](pkg/proxy/ipvs/): ipvs 模式实现。

**内部原理简述**：
1. 监听 Service、Endpoint 资源变化。
2. 动态维护本地 iptables/ipvs 规则，实现流量转发和负载均衡。

---

## 三、源码阅读建议

- 建议从各组件的 `cmd/` 目录下入口文件入手，结合 `pkg/` 目录下的实现细节，逐步深入。
- 关注 informer、controller、scheduler framework、kubelet pod worker、proxy backend 等关键模块。

---

如需更详细的源码解析，可根据上述路径深入阅读相关代码。

---

## 四、通过Namespace方式部署Kubernetes以服务100个开发团队

### 1. 资源需求

#### 1.1 硬件选择
- **虚拟机 vs 物理机**：推荐使用物理机部署Kubernetes集群，以确保更高的性能和稳定性。如果预算有限，也可以选择高性能的虚拟机。
- **Master节点**：至少3台物理机，每台配置建议如下：
  - CPU: 16核以上
  - 内存: 64GB以上
  - 存储: 500GB SSD
  - 网络: 万兆网卡
- **Worker节点**：根据实际负载需求，建议至少10台物理机，每台配置建议如下：
  - CPU: 32核以上
  - 内存: 128GB以上
  - 存储: 1TB SSD
  - 网络: 万兆网卡

#### 1.2 软件需求
- **操作系统**：推荐使用Ubuntu 20.04 LTS或CentOS 8
- **容器运行时**：Docker 20.10+或Containerd 1.5+
- **网络插件**：Calico或Flannel
- **存储插件**：Ceph或NFS

### 2. 部署步骤

#### 2.1 环境准备
1. **安装Docker或Containerd**：
   - 在Ubuntu上安装Docker：
     ```bash
     sudo apt-get update
     sudo apt-get install -y docker.io
     sudo systemctl enable docker
     sudo systemctl start docker
     ```
   - 在CentOS上安装Docker：
     ```bash
     sudo yum install -y yum-utils
     sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
     sudo yum install -y docker-ce
     sudo systemctl enable docker
     sudo systemctl start docker
     ```

2. **安装kubeadm、kubelet和kubectl**：
   - 在Ubuntu上安装：
     ```bash
     sudo apt-get update
     sudo apt-get install -y apt-transport-https ca-certificates curl
     curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
     echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
     sudo apt-get update
     sudo apt-get install -y kubelet kubeadm kubectl
     ```
   - 在CentOS上安装：
     ```bash
     sudo yum install -y kubelet kubeadm kubectl
     ```

3. **配置网络插件**：
   - 安装Calico：
     ```bash
     kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
     ```

#### 2.2 初始化Master节点
1. **使用kubeadm初始化Master节点**：
   ```bash
   sudo kubeadm init --pod-network-cidr=192.168.0.0/16
   ```

2. **配置kubectl**：
   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

3. **安装网络插件**：
   - 确保Calico已安装并运行。
在Kubernetes中，网络插件（如Calico、Flannel等）扮演着至关重要的角色，主要用于实现以下功能：

1. **Pod间通信**：网络插件负责为每个Pod分配唯一的IP地址，并确保Pod之间可以通过这些IP地址进行通信。这对于微服务架构尤为重要，因为不同的服务通常运行在不同的Pod中。

2. **跨节点通信**：当Pod分布在不同节点上时，网络插件负责处理跨节点的网络流量，确保Pod之间的通信不受节点限制。

3. **网络策略**：网络插件支持定义网络策略，允许管理员控制Pod之间的流量。例如，可以限制某些Pod只能与特定的其他Pod通信，增强安全性。

4. **负载均衡**：网络插件可以与Kubernetes的Service资源结合，实现负载均衡，确保流量能够均匀分布到多个Pod上。

5. **故障恢复**：网络插件通常具备故障恢复机制，能够在节点或Pod故障时自动调整网络配置，确保服务的连续性。

通过选择合适的网络插件，管理员可以根据集群的需求和规模，灵活配置网络环境，提升Kubernetes集群的可用性和安全性。 

#### 2.3 加入Worker节点
1. **在Master节点上获取加入命令**：
   ```bash
   kubeadm token create --print-join-command
   ```

2. **在Worker节点上执行加入命令**：
   - 将上一步获取的命令在Worker节点上执行。

#### 2.4 配置Namespace
1. **为每个开发团队创建独立的Namespace**：
   ```bash
   kubectl create namespace <team-name>
   ```

2. **配置资源配额和限制**：
   - 创建资源配额文件 `quota.yaml`：
     ```yaml
     apiVersion: v1
     kind: ResourceQuota
     metadata:
       name: compute-resources
       namespace: <team-name>
     spec:
       hard:
         requests.cpu: "4"
         requests.memory: 4Gi
         limits.cpu: "8"
         limits.memory: 8Gi
     ```
   - 应用资源配额：
     ```bash
     kubectl apply -f quota.yaml
     ```

3. **设置RBAC权限**：
   - 创建角色和角色绑定文件 `rbac.yaml`：
     ```yaml
     apiVersion: rbac.authorization.k8s.io/v1
     kind: Role
     metadata:
       namespace: <team-name>
       name: pod-reader
     rules:
     - apiGroups: [""]
       resources: ["pods"]
       verbs: ["get", "watch", "list"]
     ---
     apiVersion: rbac.authorization.k8s.io/v1
     kind: RoleBinding
     metadata:
       name: read-pods
       namespace: <team-name>
     subjects:
     - kind: User
       name: <user-name>
       apiGroup: rbac.authorization.k8s.io
     roleRef:
       kind: Role
       name: pod-reader
       apiGroup: rbac.authorization.k8s.io
     ```
   - 应用RBAC配置：
     ```bash
     kubectl apply -f rbac.yaml
     ```

#### 2.5 监控和日志
1. **部署Prometheus和Grafana进行监控**：
   - 使用Helm安装Prometheus和Grafana：
     ```bash
     helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
     helm install prometheus prometheus-community/kube-prometheus-stack
     ```

2. **部署ELK或Loki进行日志管理**：
   - 使用Helm安装ELK：
     ```bash
     helm repo add elastic https://helm.elastic.co
     helm install elasticsearch elastic/elasticsearch
     helm install kibana elastic/kibana
     helm install filebeat elastic/filebeat
     ```

#### 2.6 测试和验证
1. **部署测试应用**：
   - 创建一个简单的Deployment：
     ```yaml
     apiVersion: apps/v1
     kind: Deployment
     metadata:
       name: nginx-deployment
       namespace: <team-name>
     spec:
       replicas: 2
       selector:
         matchLabels:
           app: nginx
       template:
         metadata:
           labels:
             app: nginx
         spec:
           containers:
           - name: nginx
             image: nginx:latest
     ```
   - 应用Deployment：
     ```bash
     kubectl apply -f nginx-deployment.yaml
     ```

2. **验证资源隔离和权限控制**：
   - 使用kubectl命令检查Pod状态和资源使用情况。

### 3. 维护和扩展
- 定期更新Kubernetes版本
- 监控集群资源使用情况
- 根据需求扩展Worker节点 

---
