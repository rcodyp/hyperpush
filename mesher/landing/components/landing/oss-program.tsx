"use client"

import { motion } from "framer-motion"
import { Button } from "@/components/ui/button"
import { ArrowRight, Github, Check } from "lucide-react"

const benefits = [
  "Full Pro tier features for 6 months",
  "AI root-cause analysis & error grouping",
  "Solana program error tracking",
  "100K events/month",
  "Private + public dashboards",
  "Priority support",
]

export function OSSProgram() {
  return (
    <section className="relative py-24 border-y border-border overflow-hidden">
      {/* Subtle accent glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[300px] bg-accent/5 rounded-full blur-[100px] pointer-events-none" />

      <div className="relative z-10 max-w-7xl mx-auto px-6">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
          {/* Left — copy */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
          >
            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full border border-accent/20 bg-accent/5 text-xs font-mono text-accent uppercase tracking-wider mb-6">
              <span>✦</span>
              Limited spots
            </div>
            <h2 className="text-3xl md:text-4xl font-bold tracking-tight mb-4 text-balance">
              OSS Launch Program
            </h2>
            <p className="text-lg text-muted-foreground mb-4 text-pretty">
              The first <strong className="text-foreground">10 qualifying open-source projects</strong> get 
              the full Pro tier free for 6 months — no credit card, no strings.
            </p>
            <p className="text-muted-foreground mb-8 text-pretty">
              We're building hyperpush for the open-source community. If your project is public on GitHub 
              and actively maintained, you qualify. Apply and get set up in minutes.
            </p>
            <div className="flex flex-col sm:flex-row gap-3">
              <Button size="lg" className="h-11 px-6 gap-2">
                Join Waitlist
                <ArrowRight className="w-4 h-4" />
              </Button>
              <Button size="lg" variant="outline" className="h-11 px-6 gap-2">
                <Github className="w-4 h-4" />
                See Requirements
              </Button>
            </div>
          </motion.div>

          {/* Right — what you get */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="rounded-xl border border-accent/20 bg-card/50 backdrop-blur-sm p-6 sm:p-8"
          >
            <p className="text-sm font-mono text-accent uppercase tracking-wider mb-1">What you get</p>
            <p className="text-2xl font-bold mb-6">
              $0 <span className="text-base font-normal text-muted-foreground">for 6 months</span>
              <span className="ml-3 text-base font-normal text-muted-foreground line-through">$174 value</span>
            </p>
            <ul className="space-y-3">
              {benefits.map((benefit) => (
                <li key={benefit} className="flex items-start gap-3">
                  <Check className="w-4 h-4 text-accent mt-0.5 shrink-0" />
                  <span className="text-sm text-muted-foreground">{benefit}</span>
                </li>
              ))}
            </ul>
            <div className="mt-6 pt-6 border-t border-border">
              <div className="flex items-center justify-between gap-2">
                <p className="text-sm text-muted-foreground shrink-0">Spots remaining</p>
                <div className="flex items-center gap-2">
                  <div className="hidden sm:flex gap-1">
                    {Array.from({ length: 10 }).map((_, i) => (
                      <div
                        key={i}
                        className="w-2 h-2 rounded-full bg-accent/30"
                      />
                    ))}
                  </div>
                  <span className="text-sm font-mono text-accent">10 / 10</span>
                </div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}
