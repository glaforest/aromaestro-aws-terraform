# ============================================================
# Organizations SCPs
# ============================================================

module "organizations" {
  source          = "../../modules/organizations"
  allowed_regions = ["ca-central-1"]
}

# ============================================================
# Budgets
# ============================================================

module "budgets" {
  source       = "../../modules/budgets"
  project      = var.project
  budget_limit = "350"
  alert_email  = var.alert_email
}
