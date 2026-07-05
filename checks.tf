# check blocks run after every plan and apply and emit a warning (without blocking) when an
# invariant is violated. They are the place to enforce module-wide consistency.

# The module does nothing without at least one hub.
check "has_hubs" {
  assert {
    condition     = length(var.ai_foundry_hubs) > 0
    error_message = "No ai_foundry_hubs were supplied, so this module creates nothing."
  }
}

# The secure baseline is no public endpoint on the hub; warn when it is opened up.
check "public_access_disabled" {
  assert {
    condition = alltrue([
      for h in values(var.ai_foundry_hubs) : h.public_network_access == "Disabled"
    ])
    error_message = "An AI Foundry hub has public_network_access = Enabled. Prefer Disabled with a private endpoint, or managed_network isolation."
  }
}
