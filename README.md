# Firewall Interactive Lab: Hybrid Ops Engine (Sysadmin Edition)

A high-intensity, terminal-native interactive evaluation engine designed to build deep, production-grade mental models for **Stateful Packet Inspection (SPI)**, **Linux Netfilter pipelines**, and **RouterOS firewall architectures**.

Built specifically to eliminate theoretical bloat, this lab uses active incident scenarios, immediate feedback loops, and dynamic operational escalations to rapidly train network and systems engineers.

---

## Architecture & Curriculum

The lab contains **67 technical modules** split into three rigorous operational phases, plus **5 Critical Security Escalations**:

* **Phase 1: Architectural & Operational Modules (1–42)**  
  Core protocol triage, connection tracking state management (`NEW`, `ESTABLISHED`, `RELATED`, `INVALID`), chain boundaries (`INPUT` vs `FORWARD` vs `OUTPUT`), NAT mechanics (Source NAT/Masquerade, Destination NAT, Hairpin NAT), PMTU blackhole mitigation, and stateless pre-routing drop logic.
* **Phase 2: CLI Code Review & Bug Hunting (43–57)**  
  Root-cause analysis of misconfigured RouterOS and Netfilter command strings, targeting interface inversions, missing matchers, syntax scope errors, and filter chain ordering flaws.
* **Phase 3: Command Vault Syntax Assembly (58–67)**  
  Modular construction of enterprise-grade security policies (e.g., dynamic brute-force address-lists, MSS clamping, FastTrack bypass, and policy-based routing).
* **Critical Security Escalations (5 Stages)**  
  Multi-vector, multi-stream perimeter triage events testing real-time packet-flow decisions under pressure.

---

## Key Features

* **Zero-Gamification Terminal Interface:** Clean, ANSI-colored sysadmin telemetry using industry-standard operational nomenclature.
* **Packet Flow Simulator:** Built-in ASCII tracer rendering real-time packet traversal across filter chains and routing gateways.
* **Non-Linear Shuffling:** Modules are randomized using a Fisher-Yates shuffle at the start of every run to prevent muscle-memory answers.
* **Checkpoint & Rollback Architecture:**
  * **Checkpoint 1 (Stage 21):** Unlocked upon clearing Escalation #2.
  * **Checkpoint 2 (Stage 41):** Unlocked upon clearing Escalation #4.
  * **Soft Resets:** System integrity failures roll back to the active checkpoint, restoring the exact metric baseline and reshuffling remaining modules.
  * **Hard Reset:** Total failure prior to Stage 21 wipes session metrics back to Stage 1.
* **On-Demand Intel Dossier:** In-line field manual accessible with `H`, bound to an active 8-second emergency countdown timer.

---

## Grading Engine

The final evaluation is calculated against a strict baseline metric (Grade: 0–100):

```text
Final Grade = 100 - (Mistakes × 2.5) - (Timeouts × 4.0) + Streak Bonus
```

* **Wrong Decision:** `-2.5 pts`
* **Timer Expiration:** `-4.0 pts`
* **Max Streak Recovery:** `+1 pt` per 5 consecutive correct decisions (capped at `+6 pts`).

---

## Prerequisites & Installation

* **Operating System:** Linux, macOS, or Windows via WSL2.
* **Shell:** GNU Bash (v4.0+ recommended).

Clone the repository and make the execution script runnable:

```bash
git clone https://github.com/<your-username>/firewall-interactive-lab.git
cd firewall-interactive-lab
chmod +x run-lab.sh
```

---

## Usage

Launch the engine directly in your terminal:

```bash
./run-lab.sh
```

* Use numeric keys `1`, `2`, `3` to make immediate triage decisions.
* Press `H` when available to access the targeted protocol dossier (initiates an 10-second countdown).
* Press `Ctrl+C` at any time to abort the session.