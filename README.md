# CI/CD Platform з Jenkins + Argo CD + Terraform

## Опис проєкту

Цей проєкт реалізує повний CI/CD процес для Django застосунку з використанням:

- **Terraform** для управління інфраструктурою
- **Jenkins** для Continuous Integration (збірка та публікація Docker образів)
- **Argo CD** для Continuous Deployment (GitOps підхід)
- **Kubernetes (EKS)** як платформа оркестрації
- **Helm** для управління конфігураціями Kubernetes

## Архітектура системи

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Developer │────│     Git     │────│   Jenkins   │────│     ECR     │
│   (commit)  │    │ Repository  │    │ (CI/Build)  │    │ (Registry)  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                           │                                      │
                           │                                      │
                           ▼                                      ▼
                   ┌─────────────┐                        ┌─────────────┐
                   │   Argo CD   │◄───────────────────────│ Kubernetes  │
                   │  (GitOps)   │                        │    (EKS)    │
                   └─────────────┘                        └─────────────┘
```

## Структура проєкту

```
cicd-project/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів
├── outputs.tf               # Загальні виводи ресурсів
├── kubernetes-secrets.yaml  # Секрети для Jenkins (AWS credentials)
│
├── modules/                 # Каталог з усіма модулями
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ecr/                 # Модуль для ECR
│   │   ├── ecr.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── eks/                 # Модуль для Kubernetes кластера
│   │   ├── eks.tf
│   │   ├── aws_ebs_csi_driver.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── jenkins/             # Модуль для Jenkins
│   │   ├── jenkins.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── values.yaml
│   │   └── outputs.tf
│   │
│   └── argo_cd/             # Модуль для Argo CD
│       ├── argo_cd.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── values.yaml
│       ├── outputs.tf
│       └── charts/          # Helm chart для Argo CD Applications
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── application.yaml
│               └── repository.yaml
│
├── charts/                  # Django Helm Chart
│   └── django-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── configmap.yaml
│           ├── hpa.yaml
│           └── _helpers.tpl
│
└── README.md               # Документація проєкту
```

## Створювана інфраструктура

### AWS Ресурси

- **EKS Cluster** з версією Kubernetes 1.28
- **EC2 Node Group** з інстансами t3.medium (2-6 нод)
- **VPC** з публічними та приватними підмережами
- **ECR Repository** для Docker образів
- **S3 Bucket** для Terraform state
- **DynamoDB Table** для state locking
- **IAM Roles** та політики для всіх сервісів
- **EBS CSI Driver** для persistent volumes

### Kubernetes Ресурси

- **Jenkins** з Kaniko для збірки Docker образів
- **Argo CD** для GitOps деплойменту
- **Django Application** з автоматичним масштабуванням
- **LoadBalancer Services** для зовнішнього доступу
- **Persistent Volumes** для Jenkins data

## Передумови

### Встановлені інструменти:

1. **AWS CLI** з налаштованими credentials
2. **Terraform** (версія >= 1.0)
3. **kubectl** для роботи з Kubernetes
4. **Helm 3** для розгортання charts
5. **Git** для роботи з репозиторіями

### AWS Permissions:

- EKS повні права
- EC2 повні права
- IAM створення ролей
- S3 та DynamoDB права
- ECR повні права

## Покрокове розгортання

### Крок 1: Підготовка AWS Credentials

```bash
# Налаштуйте AWS CLI
aws configure

# Отримайте ваш AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"
```

### Крок 2: Підготовка секретів

```bash
# Кодування AWS credentials в base64
echo -n "YOUR_AWS_ACCESS_KEY_ID" | base64
echo -n "YOUR_AWS_SECRET_ACCESS_KEY" | base64

# Створіть GitHub Personal Access Token і закодуйте
echo -n "YOUR_GITHUB_TOKEN" | base64
```

Оновіть файл `kubernetes-secrets.yaml` з вашими закодованими значеннями:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: jenkins
type: Opaque
data:
  aws-access-key-id: <BASE64_ENCODED_ACCESS_KEY>
  aws-secret-access-key: <BASE64_ENCODED_SECRET_KEY>
---
apiVersion: v1
kind: Secret
metadata:
  name: github-token
  namespace: jenkins
type: Opaque
data:
  token: <BASE64_ENCODED_GITHUB_TOKEN>
```

### Крок 3: Розгортання інфраструктури

```bash
# Ініціалізація Terraform
terraform init

# Перегляд планованих змін
terraform plan

# Розгортання інфраструктури (15-20 хвилин)
terraform apply
```

### Крок 4: Налаштування kubectl

```bash
# Налаштування доступу до EKS кластера
aws eks update-kubeconfig --region eu-north-1 --name lesson-7-eks-cluster

# Перевірка підключення
kubectl get nodes
kubectl get namespaces
```

### Крок 5: Застосування секретів

```bash
# Застосування AWS credentials та GitHub token
kubectl apply -f kubernetes-secrets.yaml

# Перевірка створення секретів
kubectl get secrets -n jenkins
```

### Крок 6: Доступ до сервісів

```bash
# Отримання URLs та паролів
terraform output deployment_instructions

# Отримання паролів окремо
terraform output jenkins_admin_password
terraform output argocd_admin_password
```

## Налаштування CI/CD Pipeline

### 1. Налаштування Jenkins

1. **Доступ до Jenkins UI:**

   ```bash
   # Отримати URL Jenkins
   terraform output jenkins_url
   ```

2. **Логін в Jenkins:**

   - Username: `admin`
   - Password: `terraform output jenkins_admin_password`

3. **Створення Pipeline Job:**

   - New Item → Pipeline
   - Pipeline script from SCM
   - Git Repository: `https://github.com/denys-log/my-microservice-project`
   - Branch: `lesson-4`
   - Script Path: `Jenkinsfile`

4. **Налаштування Credentials:**
   - Manage Jenkins → Credentials
   - Додайте GitHub token з ID: `github-token`

### 2. Налаштування Argo CD

1. **Доступ до Argo CD UI:**

   ```bash
   # Отримати URL Argo CD
   terraform output argocd_server_url
   ```

2. **Логін в Argo CD:**

   - Username: `admin`
   - Password: `terraform output argocd_admin_password`

3. **Перевірка Applications:**
   - Argo CD автоматично створить Application для Django
   - Перевірте статус синхронізації

## Процес CI/CD

### Continuous Integration (Jenkins)

1. **Тригер:** Push в гілку `lesson-4`
2. **Збірка:** Kaniko збирає Docker образ з Django кодом
3. **Публікація:** Образ публікується в ECR з тегом build number
4. **Оновлення:** Jenkins оновлює `values.yaml` в гілці `cicd-project`
5. **Commit:** Зміни комітяться назад в Git репозиторій

### Continuous Deployment (Argo CD)

1. **Моніторинг:** Argo CD стежить за змінами в `cicd-project` гілці
2. **Синхронізація:** Автоматично застосовує зміни в Kubernetes
3. **Деплой:** Новий Docker образ розгортається в кластері
4. **Масштабування:** HPA автоматично масштабує поди при навантаженні

## Моніторинг та логування

### Перевірка статусу

```bash
# Jenkins pods
kubectl get pods -n jenkins

# Argo CD pods
kubectl get pods -n argocd

# Django application
kubectl get pods -n django-app

# Services та їх external IPs
kubectl get services --all-namespaces
```

### Логи

```bash
# Jenkins logs
kubectl logs -f deployment/jenkins -n jenkins

# Argo CD logs
kubectl logs -f deployment/argocd-server -n argocd

# Django application logs
kubectl logs -f deployment/django-app -n django-app
```

### Метрики

```bash
# Node metrics
kubectl top nodes

# Pod metrics
kubectl top pods --all-namespaces

# HPA status
kubectl get hpa -n django-app
```

## Автоматичне масштабування

Django застосунок налаштований з HorizontalPodAutoscaler:

- **Мінімум подів:** 2
- **Максимум подів:** 6
- **Поріг CPU:** 70%
- **Метрики:** CPU utilization

```bash
# Моніторинг автомасштабування
kubectl describe hpa django-app -n django-app
watch kubectl get hpa -n django-app
```

## Безпека

### Реалізовані заходи:

- **RBAC:** Роль-базований контроль доступу для всіх сервісів
- **Service Accounts:** Окремі service accounts для Jenkins та Argo CD
- **Secrets Management:** AWS credentials та GitHub tokens в Kubernetes secrets
- **Network Policies:** Ізоляція мережевого трафіку
- **Image Scanning:** ECR автоматично сканує образи на вразливості

### Рекомендації для production:

- Використовуйте AWS Secrets Manager замість Kubernetes secrets
- Налаштуйте Vault для управління секретами
- Увімкніть Pod Security Standards
- Налаштуйте Network Policies для строгої ізоляції
- Використовуйте private ECR endpoints

## Вартість ресурсів

### Приблизна вартість (за годину):

- **EKS Control Plane:** $0.10
- **EC2 t3.medium (2 nodes):** $0.08
- **NAT Gateways (3):** $0.135
- **LoadBalancers (3):** $0.068
- **EBS Volumes:** $0.01

**Загальна вартість:** ~$0.40/година або ~$288/місяць

### Оптимізація витрат:

- Використовуйте Spot Instances для worker nodes
- Налаштуйте Cluster Autoscaler
- Використовуйте один NAT Gateway для dev середовища
- Налаштуйте automatic shutdown для dev кластерів

## Troubleshooting

### Поширені проблеми:

#### Jenkins не може збудувати образ

```bash
# Перевірити права Kaniko
kubectl describe pod -l app=jenkins -n jenkins
kubectl logs -f pod/jenkins-kaniko-xxx -n jenkins
```

#### Argo CD не синхронізує зміни

```bash
# Перевірити статус application
kubectl get applications -n argocd
kubectl describe application django-app -n argocd

# Перевірити логи Argo CD
kubectl logs -f deployment/argocd-application-controller -n argocd
```

#### Django поди не запускаються

```bash
# Перевірити статус подів
kubectl get pods -n django-app
kubectl describe pod django-app-xxx -n django-app

# Перевірити образ в ECR
aws ecr describe-images --repository-name lesson-7-django-app --region eu-north-1
```

#### LoadBalancer не отримує external IP

```bash
# Перевірити service
kubectl describe service jenkins -n jenkins
kubectl describe service argocd-server -n argocd

# Перевірити AWS Load Balancers в консолі
```

### Відновлення після помилок:

#### Очищення та перезапуск

```bash
# Перезапуск Jenkins
kubectl rollout restart deployment/jenkins -n jenkins

# Перезапуск Argo CD
kubectl rollout restart deployment/argocd-server -n argocd

# Повне пересинхронізування в Argo CD
kubectl patch application django-app -n argocd --type merge --patch='{"operation":{"initiatedBy":{"automated":true}}}'
```

## Очищення ресурсів

**ВАЖЛИВО:** Для уникнення непередбачуваних витрат завжди видаляйте ресурси після тестування.

```bash
# Видалення Helm releases
helm uninstall jenkins -n jenkins
helm uninstall argocd -n argocd
helm uninstall django-app -n django-app

# Видалення Terraform інфраструктури
terraform destroy

# Підтвердження видалення в AWS Console
# Перевірити: EKS, EC2, LoadBalancers, NAT Gateways
```
