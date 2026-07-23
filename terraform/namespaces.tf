resource "kubernetes_namespace" "platform" {
  metadata {
    name = "platform"
    labels = {
      managed-by = "terraform"
    }
  }
}

resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
    labels = {
      managed-by = "terraform"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      managed-by = "terraform"
    }
  }
}

resource "kubernetes_namespace" "security" {
  metadata {
    name = "security"
    labels = {
      managed-by = "terraform"
    }
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      managed-by = "terraform"
    }
  }
}