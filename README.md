## Опис проєкту

Цей проєкт демонструє розгортання Django застосунку в Kubernetes кластері на AWS за допомогою Terraform та Helm. Проєкт включає створення EKS кластера, ECR репозиторію для Docker образів, та повний Helm chart для автоматичного масштабування застосунку.

## Структура проєкту

```
lesson-7/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf               # Загальні виводи ресурсів
│
├── modules/                 # Каталог з усіма модулями
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf            # Створення S3-бакета
│   │   ├── dynamodb.tf      # Створення DynamoDB
│   │   ├── variables.tf     # Змінні для S3
│   │   └── outputs.tf       # Виведення інформації про S3 та DynamoDB
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf           # Створення VPC, підмереж, Internet Gateway
│   │   ├── routes.tf        # Налаштування маршрутизації
│   │   ├── variables.tf     # Змінні для VPC
│   │   └── outputs.tf       # Виведення інформації про VPC
│   │
│   ├── ecr/                 # Модуль для ECR
│   │   ├── ecr.tf           # Створення ECR репозиторію
│   │   ├── variables.tf     # Змінні для ECR
│   │   └── outputs.tf       # Виведення URL репозиторію ECR
│   │
│   └── eks/                 # Модуль для Kubernetes кластера
│       ├── eks.tf           # Створення EKS кластера та node groups
│       ├── variables.tf     # Змінні для EKS
│       └── outputs.tf       # Виведення інформації про кластер
│
├── charts/                  # Helm charts
│   └── django-app/
│       ├── templates/
│       │   ├── deployment.yaml    # Розгортання Django застосунку
│       │   ├── service.yaml       # LoadBalancer сервіс
│       │   ├── configmap.yaml     # Конфігурація застосунку
│       │   ├── hpa.yaml           # Автоматичне масштабування
│       │   └── _helpers.tpl       # Допоміжні шаблони Helm
│       ├── Chart.yaml             # Метадані Helm chart
│       └── values.yaml            # Конфігураційні значення
│
└── README.md                # Документація проєкту
```

## Створена інфраструктура

### AWS Ресурси
- **EKS Кластер** з версією Kubernetes 1.28
- **EC2 Node Group** з інстансами t3.medium (2-6 нод)
- **VPC** з публічними та приватними підмережами
- **ECR Репозиторій** для Docker образів Django
- **S3 бакет** для зберігання Terraform state
- **DynamoDB таблиця** для блокування state
- **IAM ролі** та політики для EKS

### Kubernetes Ресурси
- **Deployment** з Django застосунком
- **LoadBalancer Service** для зовнішнього доступу
- **ConfigMap** зі змінними середовища
- **HorizontalPodAutoscaler** для автоматичного масштабування

## Передумови

Для роботи з проєктом потрібно встановити:

1. **AWS CLI** з налаштованими credentials
2. **Terraform** (версія >= 1.0)
3. **kubectl** для роботи з Kubernetes
4. **Helm 3** для розгортання charts
5. **Docker** для збірки образів

## Команди для розгортання

### 1. Підготовка інфраструктури

```bash
# Ініціалізація Terraform
terraform init

# Перегляд планованих змін
terraform plan

# Створення інфраструктури
terraform apply
```

### 2. Налаштування kubectl

```bash
# Налаштування доступу до EKS кластера
aws eks update-kubeconfig --region eu-north-1 --name lesson-7-eks-cluster

# Перевірка підключення
kubectl get nodes
```

### 3. Підготовка Docker образу

```bash
# Перехід до Django проєкту (гілка lesson-4)
git checkout lesson-4

# Збірка образу без кешу
docker build --no-cache -t lesson-7-django-app .

# Аутентифікація в ECR
aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.eu-north-1.amazonaws.com

# Тегування образу
docker tag lesson-7-django-app:latest ACCOUNT_ID.dkr.ecr.eu-north-1.amazonaws.com/lesson-7-django-app:latest

# Завантаження в ECR
docker push ACCOUNT_ID.dkr.ecr.eu-north-1.amazonaws.com/lesson-7-django-app:latest
```

### 4. Розгортання застосунку через Helm

```bash
# Повернення до гілки lesson-7
git checkout lesson-7
cd lesson-7

# Встановлення Helm chart
helm install django-app ./charts/django-app

# Перевірка статусу
helm status django-app
kubectl get all
```

### 5. Доступ до застосунку

```bash
# Отримання зовнішнього IP LoadBalancer
kubectl get service django-app

# Очікування доки LoadBalancer отримає зовнішній IP (2-5 хвилин)
kubectl get service django-app -w

# Тестування застосунку
curl http://EXTERNAL-IP/health/
```


## Очищення ресурсів

**ВАЖЛИВО**: Для уникнення непередбачуваних витрат завжди видаляйте ресурси після тестування.

```bash
# Видалення Helm релізу
helm uninstall django-app

# Видалення Terraform інфраструктури
terraform destroy
```


**Примітка**: Цей проєкт створений в навчальних цілях. Для production використання рекомендується додаткове налаштування безпеки та моніторингу.