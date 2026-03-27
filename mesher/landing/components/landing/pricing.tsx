"use client"

import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { Check } from "lucide-react"

const tiers = [
  {
    name: "Open Source",
    price: "Free",
    description: "Full error tracking with token economics and a public bug board. Free forever for any project.",
    features: [
      "10K events/month",
      "Mesh, JS/TS, Rust, Python & Node SDKs",
      "Project token launch",
      "Public bug board listing",
      "Community bounties",
      "Alerts & stack traces",
      "GitHub PR verification",
    ],
    cta: "Join Waitlist",
    popular: false,
  },
  {
    name: "Pro",
    price: "$29",
    period: "/month",
    description: "AI-powered analysis, Solana program errors, private dashboards, and more volume for growing teams.",
    features: [
      "100K events/month",
      "AI root-cause analysis",
      "AI error grouping & fix suggestions",
      "Solana program error tracking",
      "Solana transaction deep-dive",
      "Private + public dashboards",
      "Advanced alerts & integrations",
      "Custom bounty amounts",
      "Priority support",
    ],
    cta: "Join Waitlist",
    popular: true,
    promo: "First 10 OSS projects get 6 months free",
    tokenUnlock: "$1M market cap",
    tokenUnlockDetail: "Maintain a $1M token market cap and Pro is free forever",
  },
  {
    name: "Pro+",
    price: "$100",
    period: "/month",
    description: "Everything in Pro with higher limits, extended retention, and team-scale volume.",
    features: [
      "1M events/month",
      "All Pro features included",
      "90-day data retention",
      "Unlimited team members",
      "Unlimited projects",
      "Custom bounty rules & automation",
      "Dedicated support channel",
    ],
    cta: "Join Waitlist",
    popular: false,
    tokenUnlock: "$10M market cap",
    tokenUnlockDetail: "Maintain a $10M token market cap and Pro+ is free forever",
  },
]

export function Pricing() {
  return (
    <section id="pricing" className="relative py-32 border-t border-border">
      <div className="max-w-7xl mx-auto px-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center max-w-2xl mx-auto mb-16"
        >
          <p className="text-sm font-mono text-accent mb-4 uppercase tracking-wider">Pricing</p>
          <h2 className="text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight mb-6 text-balance">
            Free to start.
            <br />
            <span className="text-muted-foreground">Scale when you need to.</span>
          </h2>
          <p className="text-lg text-muted-foreground text-pretty">
            Core error tracking, token economics, and the bug board are free forever. 
            Upgrade for AI-powered analysis, Solana program errors, and higher limits.
          </p>
          <p className="text-sm text-muted-foreground/70 mt-4">
            Or unlock paid tiers for free — maintain your project token's market cap and never pay a dime.
          </p>
        </motion.div>

        <div className="grid lg:grid-cols-3 gap-px bg-border rounded-xl overflow-hidden">
          {tiers.map((tier, index) => (
            <motion.div
              key={tier.name}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              className={`relative p-6 sm:p-8 md:p-10 ${
                tier.popular 
                  ? "bg-card border-t-2 border-t-accent" 
                  : "bg-background"
              }`}
            >
              {tier.popular && (
                <span className="absolute top-4 right-4 text-xs font-mono text-accent bg-accent/10 px-2 py-1 rounded">
                  Popular
                </span>
              )}
              
              <div className="mb-8">
                <h3 className="text-xl font-semibold mb-2">{tier.name}</h3>
                <div className="flex items-baseline gap-1 mb-3">
                  <span className="text-4xl font-bold">{tier.price}</span>
                  {tier.period && (
                    <span className="text-muted-foreground">{tier.period}</span>
                  )}
                </div>
                <p className="text-sm text-muted-foreground">{tier.description}</p>
                {tier.promo && (
                  <div className="mt-4 flex items-center gap-2 px-3 py-2 rounded-lg border border-accent/20 bg-accent/5">
                    <span className="text-accent text-xs">✦</span>
                    <span className="text-xs text-accent font-medium">{tier.promo}</span>
                  </div>
                )}
                {tier.tokenUnlock && (
                  <div className="mt-3 flex items-center gap-2 px-3 py-2 rounded-lg border border-border bg-muted/30">
                    <span className="text-xs">🪙</span>
                    <span className="text-xs text-muted-foreground">
                      <strong className="text-foreground">{tier.tokenUnlock}</strong> → free forever
                    </span>
                  </div>
                )}
              </div>

              <ul className="space-y-3 mb-8">
                {tier.features.map((feature) => (
                  <li key={feature} className="flex items-start gap-3 text-sm">
                    <Check className="w-4 h-4 text-accent mt-0.5 shrink-0" />
                    <span className="text-muted-foreground">{feature}</span>
                  </li>
                ))}
              </ul>

              <Button 
                className="w-full" 
                variant={tier.popular ? "default" : "outline"}
              >
                {tier.cta}
              </Button>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
