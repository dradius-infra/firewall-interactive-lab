#!/usr/bin/env bash

# ==============================================================================
# FIREWALL INTERACTIVE LAB
# 67 Modules (42 Architecture + 15 Bug Hunting + 10 Command Vaults)
# Critical Security Escalations | Checkpoints | System Grade (0-100)
# ==============================================================================

BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

C_BLUE='\033[38;5;39m'
C_CYAN='\033[38;5;51m'
C_GREEN='\033[38;5;48m'
C_RED='\033[38;5;196m'
C_YELLOW='\033[38;5;220m'
C_ORANGE='\033[38;5;208m'
C_PURPLE='\033[38;5;141m'
C_WHITE='\033[38;5;255m'

BG_ACCEPT='\033[48;5;22m\033[38;5;15m'
BG_DROP='\033[48;5;52m\033[38;5;15m'
BG_WARN='\033[48;5;130m\033[38;5;15m'
BG_ESCALATION='\033[48;5;53m\033[38;5;15m'
BG_META='\033[48;5;236m\033[38;5;255m'

INTEGRITY=3
MAX_INTEGRITY=3
USER_INPUT=""
STREAK=0
MAX_STREAK=0
MISTAKES_COUNT=0
TIMEOUTS_COUNT=0
CURRENT_CHECKPOINT=1
SESSION_START_TIME=$(date +%s)

# Checkpoint Snapshots for Soft Reset
CKPT_MISTAKES=0
CKPT_TIMEOUTS=0
CKPT_MAX_STREAK=0
CKPT_START_TIME=$SESSION_START_TIME

render_header() {
    local lvl_num="$1"
    local lvl_title="$2"
    local mode="${3:-INCIDENT RESPONSE}"
    clear
    echo -e "${C_PURPLE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${C_PURPLE}║${NC}    ${BOLD}${C_CYAN}FIREWALL INTERACTIVE LAB${NC} ── ${C_YELLOW}MODULE $lvl_num/67${NC}"
    
    local ib1="${DIM}░${NC}" local ib2="${DIM}░${NC}" local ib3="${DIM}░${NC}"
    [ "$INTEGRITY" -ge 1 ] && ib1="${C_GREEN}█${NC}"
    [ "$INTEGRITY" -ge 2 ] && ib2="${C_GREEN}█${NC}"
    [ "$INTEGRITY" -ge 3 ] && ib3="${C_GREEN}█${NC}"

    echo -e "${C_PURPLE}║${NC}    INTEGRITY: [ $ib1 $ib2 $ib3 ] ($INTEGRITY/3)  MODE: ${BOLD}${C_GREEN}$mode${NC}  STREAK: ${C_YELLOW}$STREAK (MAX: $MAX_STREAK)${NC}"
    echo -e "${C_PURPLE}╠════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${C_PURPLE}║${NC}    OBJECTIVE: ${BOLD}${C_WHITE}$lvl_title${NC}"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}\n"
}

render_tracer() {
    local src="$1"
    local chain="$2"
    local dst="$3"
    local action="$4"

    echo -e "${BOLD}${C_BLUE}─── [PACKET FLOW SIMULATION] ────────────────────────────────────────────────${NC}"
    sleep 0.08
    echo -e "  [SOURCE]      : ${BOLD}${C_CYAN}$src${NC}"
    echo -e "                    │"
    echo -e "                    ▼"
    echo -e "  [FILTER GATE] : ${BOLD}${C_PURPLE}►► ROUTER GATEWAY [ CHAIN: $chain ] ◄◄${NC}"
    
    if [ "$action" == "ACCEPT" ]; then
        echo -e "                    │ ${C_GREEN}✔ ACCESS GRANTED (ROUTED)${NC}"
        echo -e "                    ▼"
        echo -e "  [DESTINATION] : ${BOLD}${C_GREEN}$dst${NC}"
    else
        echo -e "                    ${C_RED}✖ ACCESS DENIED (SILENT BLACKHOLE)${NC}"
        echo -e "                    ▼"
        echo -e "                  ${DIM}[PACKET DROPPED & PURGED]${NC}"
    fi
    echo -e "${BOLD}${C_BLUE}─────────────────────────────────────────────────────────────────────────────${NC}\n"
}

show_contextual_dossier() {
    local category="$1"
    echo -e "\n${C_PURPLE}╔════ TARGETED INTEL DOSSIER (FIELD MANUAL) ═════════════════════════════════╗${NC}"
    case "$category" in
        "CORE")
            echo -e "║ ${BOLD}${C_YELLOW}UDP 53${NC}    ${C_CYAN}[DNS]${NC}     : Phonebook (Translates domain names to IPs).          ║"
            echo -e "║ ${BOLD}${C_YELLOW}UDP 67/68${NC}${C_CYAN}[DHCP]${NC}     : ID Office (Auto-assigns IP/Gateway configs on boot).   ║"
            echo -e "║ ${BOLD}${C_YELLOW}UDP 123${NC}   ${C_CYAN}[NTP]${NC}     : Wall Clock (Syncs time, essential for TLS valid certs).║"
            echo -e "║ ${BOLD}${C_YELLOW}ICMP${NC}      ${C_CYAN}[Ping]${NC}     : Sonar Radar (Host reachability & echo diagnostics).    ║"
            ;;
        "WEB_APP")
            echo -e "║ ${BOLD}${C_YELLOW}TCP 80${NC}    ${C_CYAN}[HTTP]${NC}     : Cleartext Web (Unencrypted legacy web transport).      ║"
            echo -e "║ ${BOLD}${C_YELLOW}TCP 443${NC}   ${C_CYAN}[HTTPS]${NC}    : Secure Web (TLS encrypted web data, banking, search).  ║"
            echo -e "║ ${BOLD}${C_YELLOW}TCP 445${NC}   ${C_CYAN}[SMB]${NC}      : Shared Drives (Windows network shares - Ransomware risk)║"
            echo -e "║ ${BOLD}${C_YELLOW}TCP 3389${NC}  ${C_CYAN}[RDP]${NC}      : Remote Desktop (Windows GUI control - Extreme WAN risk)║"
            ;;
        "ADMIN_VPN")
            echo -e "║ ${BOLD}${C_YELLOW}TCP 22${NC}    ${C_CYAN}[SSH]${NC}      : Master Key (Remote terminal shell administration).     ║"
            echo -e "║ ${BOLD}${C_YELLOW}TCP 8291${NC}  ${C_CYAN}[WinBox]${NC}   : MikroTik RouterOS GUI management protocol.             ║"
            echo -e "║ ${BOLD}${C_YELLOW}TCP 8006${NC}  ${C_CYAN}[Proxmox]${NC}  : Hypervisor GUI (Virtual Machine & cluster dashboard).  ║"
            echo -e "║ ${BOLD}${C_YELLOW}UDP 51820${NC}${C_CYAN}[WireGuard]${NC}: Crypto Tunnel (Secure VPN tunnel endpoint).          ║"
            ;;
        "OPS_LOGS")
            echo -e "║ ${BOLD}${C_YELLOW}UDP 514${NC}   ${C_CYAN}[Syslog]${NC}   : Flight Recorder (Sends event logs to SIEM server).     ║"
            echo -e "║ ${BOLD}${C_YELLOW}UDP 161${NC}   ${C_CYAN}[SNMP]${NC}     : Telemetry Agent (Device monitoring & bandwidth polling)║"
            echo -e "║ ${BOLD}${C_YELLOW}UDP 5353${NC}  ${C_CYAN}[mDNS]${NC}     : Local Gossip (Apple AirPlay/Chromecast local discovery)║"
            echo -e "║ ${BOLD}${C_YELLOW}ICMP 3/4${NC}  ${C_CYAN}[PMTU]${NC}     : MTU Radar (Fragmentation Needed notification).         ║"
            ;;
        "NAT_FLAGS")
            echo -e "║ ${BOLD}${C_YELLOW}src-nat / Masq${NC}     : Outbound disguise (Many private LAN IPs -> 1 WAN IP).  ║"
            echo -e "║ ${BOLD}${C_YELLOW}dst-nat (P-Fwd)${NC}    : Inbound redirect (WAN IP:Port -> Internal Server:Port).║"
            echo -e "║ ${BOLD}${C_YELLOW}Hairpin NAT${NC}        : Loopback NAT (LAN hosts reaching local server by WAN IP)║"
            echo -e "║ ${BOLD}${C_YELLOW}SYN / RST Flags${NC}    : SYN initiates NEW handshake; RST kills connection.     ║"
            ;;
        "CCNA_CONCEPTS")
            echo -e "║ ${BOLD}${C_YELLOW}First-Match Rule${NC}   : Firewalls evaluate TOP-to-BOTTOM and stop on 1st match.║"
            echo -e "║ ${BOLD}${C_YELLOW}Zero-Trust Drops${NC}   : Default Drop always belongs at the END of chains.      ║"
            echo -e "║ ${BOLD}${C_YELLOW}Martians (RFC1918)${NC}: Private IPs arriving on WAN = Spoofed attack packets.  ║"
            echo -e "║ ${BOLD}${C_YELLOW}State: RELATED${NC}     : Associated traffic (e.g., ICMP error to TCP session).  ║"
            ;;
        "ADVANCED_OPS")
            echo -e "║ ${BOLD}${C_YELLOW}Mangle Table${NC}        : Packet modifier (Routing marks, QoS priority, TTL).    ║"
            echo -e "║ ${BOLD}${C_YELLOW}RAW Table${NC}          : Stateless bypass (Drops packets BEFORE Conntrack/RAM). ║"
            echo -e "║ ${BOLD}${C_YELLOW}MSS Clamping${NC}       : Fixes tunnel packet fragmentation (Change MSS -> PMTU).║"
            echo -e "║ ${BOLD}${C_YELLOW}Address-Lists${NC}      : Dynamic blacklists for Port Knocking & Fail2ban rules. ║"
            ;;
        "CLI_SYNTAX")
            echo -e "║ ${BOLD}${C_YELLOW}RouterOS CLI${NC}       : /ip firewall filter add chain=[...] action=[...]        ║"
            echo -e "║ ${BOLD}${C_YELLOW}Key Matchers${NC}       : in-interface, src-address, connection-state, protocol. ║"
            echo -e "║ ${BOLD}${C_YELLOW}Key Actions${NC}        : accept, drop, reject, fasttrack-connection, jump.      ║"
            echo -e "║ ${BOLD}${C_YELLOW}Block Matching${NC}     : Combine matching criteria + action blocks accurately.  ║"
            ;;
    esac
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BG_WARN} ⚠ INTEL ACCESSED: 8 SECONDS EMERGENCY TIMER RUNNING! ⚠ ${NC}\n"
}

ask_with_timer_or_manual() {
    local prompt_text="$1"
    local valid_regex="$2"
    local category="$3"
    USER_INPUT=""

    while true; do
        read -rp "$prompt_text" USER_INPUT
        if [[ "$USER_INPUT" =~ ^[hH]$ ]]; then
            show_contextual_dossier "$category"
            
            local input_received=false
            local timeout_val=8
            
            for ((sec=timeout_val; sec>0; sec--)); do
                local bar=""
                for ((b=1; b<=timeout_val; b++)); do
                    if [ "$b" -le "$sec" ]; then
                        bar+="${C_GREEN}█${NC}"
                    else
                        bar+="${DIM}░${NC}"
                    fi
                done

                printf "\r\033[K[ %b ] %ds remaining | Selection: " "$bar" "$sec"
                
                read -t 1 timer_ans
                if [ -n "$timer_ans" ]; then
                    input_received=true
                    USER_INPUT="$timer_ans"
                    echo ""
                    break
                fi
            done

            if [ "$input_received" = false ]; then
                echo -e "\n\n${BG_DROP} ⏰ TIME EXPIRED! BUFFER OVERFLOW! (-1 INTEGRITY) ${NC}\n"
                INTEGRITY=$((INTEGRITY - 1))
                TIMEOUTS_COUNT=$((TIMEOUTS_COUNT + 1))
                STREAK=0
                return 99
            else
                if [[ "$USER_INPUT" =~ $valid_regex ]]; then
                    return 0
                fi
            fi
        elif [[ "$USER_INPUT" =~ $valid_regex ]]; then
            return 0
        else
            echo -e "${C_RED}Invalid entry. Enter a valid option or [H] for Intel.${NC}"
        fi
    done
}

update_streak_success() {
    STREAK=$((STREAK + 1))
    [ "$STREAK" -gt "$MAX_STREAK" ] && MAX_STREAK="$STREAK"
}

update_streak_failure() {
    STREAK=0
    MISTAKES_COUNT=$((MISTAKES_COUNT + 1))
}

# ==============================================================================
# PHASE 1: 42 ARCHITECTURAL & OPERATIONAL MODULES
# ==============================================================================

module_1() {
    local lvl="$1"; while true; do render_header "$lvl" "DNS Name Resolution Failure"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Host: ${C_CYAN}10.10.20.10${NC} ──► Target: ${C_YELLOW}archlinux.org${NC} [FAILED: Name Not Resolved]"
    echo -e "  Diagnostic: Pinging raw IP ${C_GREEN}1.1.1.1${NC} returns ${C_GREEN}0% packet loss${NC} (Web works by IP).\n"
    echo -e "${BOLD}DECISION: Which service is blocked in FORWARD?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} UDP 67  (DHCP)"
    echo -e "  ${C_YELLOW}► [2]${NC} UDP 53  (DNS Phonebook)"
    echo -e "  ${C_YELLOW}► [3]${NC} TCP 22  (SSH Remote Shell)"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CORE"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "2" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! RESOLUTION RESTORED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Raw IP traffic passes, confirming routing and NAT are fine. The domain-to-IP resolution fails because ${BOLD}DNS (UDP 53)${NC} is dropped in FORWARD.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_2() {
    local lvl="$1"; while true; do render_header "$lvl" "IoT Lateral Movement Isolation"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Source: ${C_RED}Smart TV (IoT VLAN 30)${NC} ──► Target: ${C_CYAN}Workstation (LAN VLAN 20)${NC}"
    echo -e "  Service: ${BOLD}TCP Port 445 (SMB Windows Shares)${NC} | Connection State: ${C_ORANGE}NEW${NC}\n"
    echo -e "${BOLD}DECISION: Which Chain and State must trigger the DROP rule?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} FORWARD chain with state=NEW"
    echo -e "  ${C_YELLOW}► [2]${NC} INPUT chain with state=ESTABLISHED"
    echo -e "  ${C_YELLOW}► [3]${NC} OUTPUT chain with state=RELATED"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "WEB_APP"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! QUARANTINE APPLIED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Inter-subnet traffic crosses the ${BOLD}FORWARD${NC} chain. Blocking state ${BOLD}NEW${NC} stops untrusted devices from initiating scans, while keeping return traffic intact.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_3() {
    local lvl="$1"; while true; do render_header "$lvl" "Clock Desync & TLS Validation Failure"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Router Clock: ${C_RED}Jan 1, 1970 00:00${NC} ──► All HTTPS sites throw ${C_RED}SEC_ERROR_EXPIRED_CERT${NC}"
    echo -e "  Action Required: Synchronize system clock with external server ${C_CYAN}pool.ntp.org${NC}.\n"
    echo -e "${BOLD}DECISION: What service and chain must be opened?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} UDP 123 (NTP) on INPUT & OUTPUT"
    echo -e "  ${C_YELLOW}► [2]${NC} TCP 80 (HTTP) on FORWARD"
    echo -e "  ${C_YELLOW}► [3]${NC} UDP 53 (DNS) on PREROUTING"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CORE"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! TIME SYNCHRONIZED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} TLS validation requires an accurate real-world clock. The router host synchronizes its own internal clock using ${BOLD}NTP (UDP 123)${NC} via INPUT and OUTPUT.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_4() {
    local lvl="$1"; while true; do render_header "$lvl" "WAN Administrative Shell Siege"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Source: ${C_RED}WAN Attacker (198.51.100.24)${NC} ──► Target: ${C_YELLOW}Router Gateway (203.0.113.1)${NC}"
    echo -e "  Service: ${BOLD}TCP Port 22 (SSH Shell)${NC} | Packet Volume: ${C_RED}450 pkts/sec${NC}\n"
    echo -e "${BOLD}DECISION: What chain must drop this traffic?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} FORWARD"
    echo -e "  ${C_YELLOW}► [2]${NC} INPUT"
    echo -e "  ${C_YELLOW}► [3]${NC} OUTPUT"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADMIN_VPN"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "2" ]; then update_streak_success; render_tracer "WAN IP" "INPUT" "Router Port 22" "DROP"
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! MANAGEMENT SHELL PROTECTED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Packets terminating directly at the router itself traverse the ${BOLD}INPUT${NC} chain. Dropping public WAN hits to port 22 on INPUT stops brute-force attacks.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_5() {
    local lvl="$1"; while true; do render_header "$lvl" "Private IP Outbound Translation"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  LAN Subnet: ${C_CYAN}10.10.20.0/24${NC} ──► WAN Gateway ──► ISP Drop (RFC 1918 Unroutable)"
    echo -e "  Symptom: Packets reach WAN interface but internet routers discard them instantly.\n"
    echo -e "${BOLD}DECISION: What NAT function rewrites private IPs to WAN IP?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} dst-nat redirect"
    echo -e "  ${C_YELLOW}► [2]${NC} src-nat / Masquerade"
    echo -e "  ${C_YELLOW}► [3]${NC} Netflow accounting"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "NAT_FLAGS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "2" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! OUTBOUND NAT ACTIVE ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} RFC 1918 private IPs are non-routable on the public internet. ${BOLD}src-nat / Masquerade${NC} substitutes the router's public WAN IP as the packet source.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_6() {
    local lvl="$1"; while true; do render_header "$lvl" "Port Forwarding Inbound Publishing"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Client: ${C_CYAN}Public Web User${NC} ──► Router WAN: ${C_YELLOW}203.0.113.1:443${NC}"
    echo -e "  Requirement: Forward packet to internal server ${C_GREEN}10.10.40.15:443${NC}.\n"
    echo -e "${BOLD}DECISION: Which NAT chain handles this inbound translation?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} src-nat"
    echo -e "  ${C_YELLOW}► [2]${NC} dst-nat"
    echo -e "  ${C_YELLOW}► [3]${NC} postrouting"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "NAT_FLAGS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "2" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! PORT FORWARD ROUTED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Incoming traffic hits the public WAN address. ${BOLD}dst-nat (Destination NAT)${NC} rewrites the destination IP to the private internal server before filter evaluation.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_7() {
    local lvl="$1"; while true; do render_header "$lvl" "Hypervisor Dashboard Isolation"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Source: ${C_RED}Guest Wi-Fi (10.10.50.15)${NC} ──► Target: ${C_YELLOW}Proxmox VE (10.10.10.4:8006)${NC}"
    echo -e "  Status: Untrusted guest initiates direct connection to server control plane.\n"
    echo -e "${BOLD}DECISION: What action must the FORWARD chain take?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} ACCEPT"
    echo -e "  ${C_YELLOW}► [2]${NC} DROP"
    echo -e "  ${C_YELLOW}► [3]${NC} FASTTRACK"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADMIN_VPN"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "2" ]; then update_streak_success; render_tracer "Guest IP" "FORWARD" "Proxmox:8006" "DROP"
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! MANAGEMENT ISOLATED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Hypervisor GUIs and API endpoints must never be reachable from untrusted guest or IoT segments on the ${BOLD}FORWARD${NC} chain.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_8() {
    local lvl="$1"; while true; do render_header "$lvl" "WireGuard Crypto-Handshake Ingress"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Source: ${C_CYAN}Admin Mobile (Cellular WAN)${NC} ──► Target: ${C_YELLOW}Router WAN (UDP 51820)${NC}"
    echo -e "  Action: WireGuard crypto tunnel initialization.\n"
    echo -e "${BOLD}DECISION: Which firewall chain must accept this handshake?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} FORWARD"
    echo -e "  ${C_YELLOW}► [2]${NC} INPUT"
    echo -e "  ${C_YELLOW}► [3]${NC} PREROUTING"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADMIN_VPN"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "2" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! VPN HANDSHAKE ACCEPTED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The router itself runs the WireGuard service and terminates the encrypted tunnel. The initial crypto-handshake terminates at the router on the ${BOLD}INPUT${NC} chain.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_9() {
    local lvl="$1"; while true; do render_header "$lvl" "Local Client DHCP Starvation"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Client: ${C_YELLOW}New PC Boots Up${NC} ──► Receives APIPA ${C_RED}169.254.x.x${NC}"
    echo -e "  Reason: Broadcast request ${C_CYAN}0.0.0.0:68 -> 255.255.255.255:67${NC} is dropped by gateway.\n"
    echo -e "${BOLD}DECISION: What service and chain must be opened?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} UDP 67 on INPUT"
    echo -e "  ${C_YELLOW}► [2]${NC} UDP 53 on FORWARD"
    echo -e "  ${C_YELLOW}► [3]${NC} TCP 80 on INPUT"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CORE"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! DHCP SERVICE RESTORED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} When the router runs the DHCP server, client broadcast discovery packets (${BOLD}UDP 67${NC}) target the router directly, requiring an open rule on ${BOLD}INPUT${NC}.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_10() {
    local lvl="$1"; while true; do render_header "$lvl" "Corrupted TCP Flag Evasion (XMAS)"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Packet Flags: ${C_RED}[FIN + PSH + URG]${NC} ──► Classification: ${C_ORANGE}State=INVALID${NC}"
    echo -e "  Context: Attacker attempts to bypass stateful filters with out-of-order flags.\n"
    echo -e "${BOLD}DECISION: Where must the 'Drop Invalid' rule live?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Bottom of firewall rules"
    echo -e "  ${C_YELLOW}► [2]${NC} Top of firewall rules (after Established)"
    echo -e "  ${C_YELLOW}► [3]${NC} In NAT table"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "2" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! EARLY INVALID DROPS ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Dropping ${BOLD}INVALID${NC} packets at the very top prevents malformed scanning frames from consuming CPU cycles in subsequent whitelist rules.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_11() {
    local lvl="$1"; while true; do render_header "$lvl" "First-Match Rule Ordering"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Rule #1: ${C_RED}DROP ALL FORWARD${NC}"
    echo -e "  Rule #2: ${C_GREEN}ACCEPT LAN -> WAN (HTTP/HTTPS)${NC}"
    echo -e "  Symptom: All user browsing is dead across the whole company.\n"
    echo -e "${BOLD}DECISION: What causes this failure?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} First-Match Principle: Rule 1 matches first and terminates evaluation"
    echo -e "  ${C_YELLOW}► [2]${NC} Web traffic requires UDP"
    echo -e "  ${C_YELLOW}► [3]${NC} Rule 2 needs INPUT chain"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! EVALUATION HALTED AT RULE 1 ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Firewalls evaluate sequentially top-to-bottom. The ${BOLD}First-Match Principle${NC} ensures that a broad Drop All rule at line 1 prevents Rule 2 from ever being reached.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_12() {
    local lvl="$1"; while true; do render_header "$lvl" "Loopback Reflection (Hairpin NAT)"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  LAN Host: ${C_CYAN}10.10.20.10${NC} ──► Resolves ${C_YELLOW}mybiz.com${NC} to WAN IP ${C_YELLOW}203.0.113.1${NC}"
    echo -e "  Symptom: External users access site fine; internal office users get connection timeout.\n"
    echo -e "${BOLD}DECISION: What firewall architecture fixes internal WAN IP access?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Hairpin NAT (NAT Loopback)"
    echo -e "  ${C_YELLOW}► [2]${NC} Double Masquerade"
    echo -e "  ${C_YELLOW}► [3]${NC} Proxy ARP"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "NAT_FLAGS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! HAIRPIN NAT ACTIVE ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} ${BOLD}Hairpin NAT${NC} rewrites both source and destination addresses for LAN hosts accessing an internal server via the router's public WAN IP, preventing asymmetric drops.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_13() {
    local lvl="$1"; while true; do render_header "$lvl" "Spoofed Martian IP Ingress"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Interface: ${C_RED}ether1 (Public WAN)${NC} ──► Ingress Source IP: ${C_YELLOW}192.168.1.50${NC}"
    echo -e "  Context: Packet claiming to be private RFC 1918 enters from public internet wire.\n"
    echo -e "${BOLD}DECISION: How must this packet be treated?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Accept"
    echo -e "  ${C_YELLOW}► [2]${NC} Drop immediately as Martian / Spoofed"
    echo -e "  ${C_YELLOW}► [3]${NC} Route to internal LAN"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "2" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! MARTIAN DROPPED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Private RFC 1918 addresses can never legitimately originate from public WAN links. Any such packet arriving from WAN is spoofed and must be dropped as a ${BOLD}Martian packet${NC}.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_14() {
    local lvl="$1"; while true; do render_header "$lvl" "Kernel FastPath Offloading"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Router Load: ${C_RED}CPU @ 100%${NC} during multi-gigabit continuous downloads."
    echo -e "  Conntrack State: All streams are already established and verified.\n"
    echo -e "${BOLD}DECISION: What feature offloads packet inspection to bypass kernel overhead?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} FastTrack / FastPath"
    echo -e "  ${C_YELLOW}► [2]${NC} Drop SYN"
    echo -e "  ${C_YELLOW}► [3]${NC} Increase timeout"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! FASTTRACK ENGAGED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Re-evaluating established packets through firewall rules consumes CPU. ${BOLD}FastTrack${NC} bypasses detailed kernel inspection for already-approved sessions, running them at line rate.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_15() {
    local lvl="$1"; while true; do render_header "$lvl" "Path MTU Discovery Blackhole"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Firewall Policy: Total block of ALL ICMP traffic on WAN."
    echo -e "  Symptom: Small web pages load; large data transfers hang indefinitely.\n"
    echo -e "${BOLD}DECISION: Why is blanket ICMP blocking destructive?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Drops ICMP Type 3 Code 4 (Fragmentation Needed), breaking PMTU"
    echo -e "  ${C_YELLOW}► [2]${NC} Disables DNS queries"
    echo -e "  ${C_YELLOW}► [3]${NC} Shuts down web servers"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "OPS_LOGS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! PMTU SIGNALING RESTORED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} When an oversized frame hits an MTU bottleneck, routers return ${BOLD}ICMP Type 3 Code 4${NC}. Blocking all ICMP causes a PMTU blackhole: clients never learn to shrink packets and stall.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_16() {
    local lvl="$1"; while true; do render_header "$lvl" "Raw RDP WAN Border Exposure"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Config Check: Router port forwards public WAN Port ${C_RED}3389${NC} directly to PC."
    echo -e "  Target: Windows Remote Desktop Protocol (RDP).\n"
    echo -e "${BOLD}DECISION: What is the security verdict?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Recommended practice"
    echo -e "  ${C_YELLOW}► [2]${NC} Extreme risk: RDP brute-forces dominate WAN scans -> DROP / Use VPN"
    echo -e "  ${C_YELLOW}► [3]${NC} Safe if using complex password"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "WEB_APP"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "2" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! PERIMETER SECURED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Exposing raw ${BOLD}RDP (Port 3389)${NC} directly to the public internet leaves internal desktops vulnerable to rapid automated exploits and credential stuffing. Always use a VPN.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_17() {
    local lvl="$1"; while true; do render_header "$lvl" "SNMP Telemetry Reconnaissance"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Source: Public WAN Scanner ──► Target: Router UDP Port ${C_RED}161${NC}"
    echo -e "  Payload: SNMP query requesting device system descriptions and interface tables.\n"
    echo -e "${BOLD}DECISION: What chain must drop this query?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} INPUT"
    echo -e "  ${C_YELLOW}► [2]${NC} FORWARD"
    echo -e "  ${C_YELLOW}► [3]${NC} OUTPUT"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "OPS_LOGS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! INPUT CHAIN DROP APPLIED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} SNMP queries on ${BOLD}UDP 161${NC} interrogate the router's local telemetry. Because the packet targets the router host itself, it must be filtered and dropped on the ${BOLD}INPUT${NC} chain.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_18() {
    local lvl="$1"; while true; do render_header "$lvl" "mDNS Discovery Containment"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Traffic: Multicast broadcast to ${C_YELLOW}224.0.0.251${NC} across entire corporate network."
    echo -e "  Service: Smart device auto-discovery (AirPlay / Chromecast).\n"
    echo -e "${BOLD}DECISION: What port does mDNS operate on?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} UDP 5353"
    echo -e "  ${C_YELLOW}► [2]${NC} DHCP Relay"
    echo -e "  ${C_YELLOW}► [3]${NC} BGP Peering"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "OPS_LOGS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! MDNS ISOLATED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Multicast DNS uses ${BOLD}UDP 5353${NC}. Filtering it across inter-VLAN boundaries blocks broadcast storms and isolates smart IoT device discovery from corporate workstations.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_19() {
    local lvl="$1"; while true; do render_header "$lvl" "TCP Half-Open SYN Flood Defense"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Attack Vector: ${C_RED}50,000 SYN packets/sec${NC} with fake IPs. No ACKs arrive."
    echo -e "  Threat: Memory table exhaustion for half-open TCP connections.\n"
    echo -e "${BOLD}DECISION: How does the firewall counter TCP half-open socket starvation?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} SYN Cookies / TCP Rate Limiting"
    echo -e "  ${C_YELLOW}► [2]${NC} Accept established"
    echo -e "  ${C_YELLOW}► [3]${NC} Disable FastTrack"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "NAT_FLAGS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! SYN COOKIES PREVENT EXHAUSTION ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} ${BOLD}SYN Cookies${NC} encode socket state parameters inside the TCP sequence number, deferring memory allocation until the client actually validates with a legitimate final ACK.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_20() {
    local lvl="$1"; while true; do render_header "$lvl" "TCP Abrupt Reset Teardown"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Packet Event: Client terminates crashed session immediately."
    echo -e "  Action: Instruct recipient socket to flush buffers and tear down connection.\n"
    echo -e "${BOLD}DECISION: Which TCP flag forces immediate socket termination?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} RST (Reset)"
    echo -e "  ${C_YELLOW}► [2]${NC} SYN (Synchronize)"
    echo -e "  ${C_YELLOW}► [3]${NC} PSH (Push)"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "NAT_FLAGS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! RST FLAG DESTROYS SESSION ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Unlike a graceful 4-way FIN closure, the ${BOLD}RST (Reset)${NC} flag abruptly terminates the connection socket and frees memory immediately.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_21() {
    local lvl="$1"; while true; do render_header "$lvl" "Conntrack Classification: RELATED"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Event: Host sends HTTP traffic; WAN gateway replies with ICMP Dest Unreachable."
    echo -e "  Status: Firewall permits packet despite no explicit inbound rule for that ICMP port.\n"
    echo -e "${BOLD}DECISION: Why does the stateful filter allow this error packet?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Classified as RELATED"
    echo -e "  ${C_YELLOW}► [2]${NC} ICMP is uninspected"
    echo -e "  ${C_YELLOW}► [3]${NC} Treated as NEW"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! RELATED TRAFFIC PERMITTED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} State ${BOLD}RELATED${NC} identifies traffic that is directly spawned by an active, approved session (such as ICMP error messages or dynamic FTP data channels).\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_22() {
    local lvl="$1"; while true; do render_header "$lvl" "Router Host Self-Originating Traffic"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Event: Administrator executes ${C_YELLOW}/ping 8.8.8.8${NC} directly on router CLI."
    echo -e "  Origin: Packet source IP belongs to router interface itself.\n"
    echo -e "${BOLD}DECISION: Which chain filters packets originating FROM the router host?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} OUTPUT"
    echo -e "  ${C_YELLOW}► [2]${NC} INPUT"
    echo -e "  ${C_YELLOW}► [3]${NC} FORWARD"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! OUTPUT CHAIN APPLIED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Outbound traffic created by processes running on the router host itself (like CLI diagnostics or internal DNS queries) traverses the ${BOLD}OUTPUT${NC} chain.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_23() {
    local lvl="$1"; while true; do render_header "$lvl" "TCP 3-Way Handshake Conntrack Transition"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Sequence: ${C_CYAN}SYN${NC} ──► ${C_YELLOW}SYN-ACK${NC} ──► ${C_GREEN}ACK${NC}"
    echo -e "  Question: At which exact step does state transition to ESTABLISHED?\n"
    echo -e "${BOLD}DECISION: Which packet marks the connection ESTABLISHED?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} The final ACK completing the handshake"
    echo -e "  ${C_YELLOW}► [2]${NC} The initial SYN packet"
    echo -e "  ${C_YELLOW}► [3]${NC} Before the first packet is sent"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "NAT_FLAGS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! CONNECTION FULLY ESTABLISHED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The initial SYN is state NEW. Once the receiving host returns SYN-ACK and the initiator replies with the ${BOLD}final ACK${NC}, Conntrack officially marks the state ${BOLD}ESTABLISHED${NC}.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_24() {
    local lvl="$1"; while true; do render_header "$lvl" "Rogue Hardcoded DNS Sinkholing"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Device: Smart TV bypasses DHCP DNS and hardcodes queries to ${C_RED}8.8.8.8:53${NC}."
    echo -e "  Goal: Intercept and silently force queries to internal Pi-hole ${C_GREEN}10.10.10.5${NC}.\n"
    echo -e "${BOLD}DECISION: How to transparently force DNS to internal resolver?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} dst-nat redirect UDP 53 to 10.10.10.5"
    echo -e "  ${C_YELLOW}► [2]${NC} FastTrack all traffic"
    echo -e "  ${C_YELLOW}► [3]${NC} Block Port 443"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "NAT_FLAGS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! TRANSPARENT SINKHOLE ACTIVE ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} A ${BOLD}dst-nat redirect${NC} catches outbound UDP 53 traffic in transit and silently rewrites the target IP to your local sinkhole, transparently capturing rogue hardcoded queries.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_25() {
    local lvl="$1"; while true; do render_header "$lvl" "Zero-Trust Perimeter Posture"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Review: Admin added 15 specific ACCEPT rules for required services."
    echo -e "  Defect: No ending termination rule exists in filter tables.\n"
    echo -e "${BOLD}DECISION: What is the mandatory Zero-Trust baseline rule?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Explicit DROP ALL at the end of INPUT and FORWARD chains"
    echo -e "  ${C_YELLOW}► [2]${NC} Permit everything else"
    echo -e "  ${C_YELLOW}► [3]${NC} Disable logs"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! ZERO-TRUST BASELINE SECURED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} A proper Zero-Trust perimeter explicitly ends with a ${BOLD}DROP ALL${NC} rule at the bottom of INPUT and FORWARD chains so unapproved packets cannot slip through.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_26() {
    local lvl="$1"; while true; do render_header "$lvl" "Dual-Port Protocols & ALGs (FTP)"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Service: Legacy FTP connects to Port 21 (Control), but passive data channels hang."
    echo -e "  Symptom: Dynamic high ports negotiated in payload fail to pass firewall.\n"
    echo -e "${BOLD}DECISION: What engine component tracks dynamic payload-negotiated ports?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Conntrack Helper / ALG classifying traffic as RELATED"
    echo -e "  ${C_YELLOW}► [2]${NC} Masquerade"
    echo -e "  ${C_YELLOW}► [3]${NC} Drop Invalid"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! DYNAMIC ALG HELPER ENGAGED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Protocols like FTP negotiate dynamic data ports inside the payload. An ${BOLD}ALG (Application Layer Gateway) Helper${NC} reads this and dynamically allows the new ports as ${BOLD}RELATED${NC}.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_27() {
    local lvl="$1"; while true; do render_header "$lvl" "Internal Boundary: DROP vs REJECT"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Symptom: Internal user applications freeze for 30s before reporting blocked port."
    echo -e "  Cause: Firewall drops packet silently without notifying the client socket.\n"
    echo -e "${BOLD}DECISION: Why use REJECT instead of DROP on internal LAN interfaces?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} REJECT returns TCP RST / ICMP Unreachable for instant application failover"
    echo -e "  ${C_YELLOW}► [2]${NC} Encrypts traffic"
    echo -e "  ${C_YELLOW}► [3]${NC} Saves CPU"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! CLEAN INSTANT TIMEOUT ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Silent DROP forces internal applications to wait for retransmission timers to expire. ${BOLD}REJECT${NC} sends back an immediate TCP RST, letting internal apps fail fast and cleanly.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_28() {
    local lvl="$1"; while true; do render_header "$lvl" "Policy Routing via Packet Marking"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Architecture: Multi-WAN. Video streaming must use WAN1; Bulk torrents use WAN2."
    echo -e "  Requirement: Tag packets before standard routing table decisions occur.\n"
    echo -e "${BOLD}DECISION: Which table applies routing marks?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Mangle Table (Action: mark-routing)"
    echo -e "  ${C_YELLOW}► [2]${NC} NAT Table"
    echo -e "  ${C_YELLOW}► [3]${NC} Filter Table"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! POLICY ROUTING TAGGED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The ${BOLD}Mangle table${NC} modifies packet headers. Marking packets with a ${BOLD}routing-mark${NC} forces matching traffic through specific custom routing tables rather than the default gateway.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_29() {
    local lvl="$1"; while true; do render_header "$lvl" "VPN Tunnel MTU & MSS Clamping"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Interface: WireGuard / PPPoE VPN Tunnel."
    echo -e "  Symptom: Pings pass cleanly, but large HTTPS websites stall and fail to load.\n"
    echo -e "${BOLD}DECISION: What firewall rule fixes tunnel overhead packet drops?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Change TCP MSS (MSS Clamping) to match PMTU"
    echo -e "  ${C_YELLOW}► [2]${NC} Drop Invalid"
    echo -e "  ${C_YELLOW}► [3]${NC} Enable UPnP"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! MSS CLAMPING RESOLVES STALLS ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Tunnel headers consume bytes from standard 1500 MTU links. ${BOLD}MSS Clamping${NC} rewrites the Maximum Segment Size during TCP negotiation so packets fit without fragmentation.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_30() {
    local lvl="$1"; while true; do render_header "$lvl" "Dynamic Automated Blacklisting"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Threat: Rapid SSH brute-force attacks across rotating public IPs."
    echo -e "  Goal: Automatically ban any source IP after 3 failed login port hits.\n"
    echo -e "${BOLD}DECISION: What router mechanism provides automated temporary bans?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Action: add-src-to-address-list (timeout: 24h) + DROP rule"
    echo -e "  ${C_YELLOW}► [2]${NC} Reboot router"
    echo -e "  ${C_YELLOW}► [3]${NC} Disable SSH"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! DYNAMIC AUTO-BAN ACTIVE ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Using ${BOLD}add-src-to-address-list${NC} with a timeout dynamically records offensive IPs into an active blacklist. A matching drop rule at the top immediately neutralizes subsequent attempts.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_31() {
    local lvl="$1"; while true; do render_header "$lvl" "Stateless Pre-Routing DDoS Defense"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Attack: 10 Gbps UDP flood saturates connection tracking memory."
    echo -e "  Critical: Conntrack RAM exhaustion crashes the router kernel.\n"
    echo -e "${BOLD}DECISION: Where to drop volumetric floods BEFORE Conntrack allocates memory?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} RAW Table (Prerouting stateless drop)"
    echo -e "  ${C_YELLOW}► [2]${NC} Filter Table INPUT"
    echo -e "  ${C_YELLOW}► [3]${NC} Mangle Table"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! STATELESS PRE-CONNTRACK DROP ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The ${BOLD}RAW table${NC} processes packets before connection tracking state allocation. Dropping volumetric floods in RAW protects kernel memory and saves CPU cycles.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_32() {
    local lvl="$1"; while true; do render_header "$lvl" "Stealth Access via Port Knocking"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Objective: Port scanners must see SSH Port 22 as completely closed/filtered."
    echo -e "  Requirement: Unlock port 22 only after secret sequence knocks on dummy ports.\n"
    echo -e "${BOLD}DECISION: What architecture enables hidden port activation?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Port Knocking using staged address-lists"
    echo -e "  ${C_YELLOW}► [2]${NC} UPnP"
    echo -e "  ${C_YELLOW}► [3]${NC} Port Forwarding"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! STEALTH ACCESS ENABLED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} ${BOLD}Port Knocking${NC} keeps management ports hidden behind drop rules until an authorized source sends sequential packets to dummy closed ports within defined timeouts.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_33() {
    local lvl="$1"; while true; do render_header "$lvl" "Stealth TCP NULL Scan Probing"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Packet Analysis: Ingress packet arrives with ${C_RED}TCP Flags: NONE (000000)${NC}."
    echo -e "  Context: Nmap NULL scan trying to elicit RFC 793 RST responses from closed ports.\n"
    echo -e "${BOLD}DECISION: What scan is this and how should the firewall act?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} TCP NULL Scan -> DROP as INVALID"
    echo -e "  ${C_YELLOW}► [2]${NC} Normal web traffic -> ACCEPT"
    echo -e "  ${C_YELLOW}► [3]${NC} VPN keepalive"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "NAT_FLAGS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! NULL SCAN PURGED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Legitimate TCP communications always declare state flags. Packets arriving with zero flags violate protocol standards and are dropped as ${BOLD}INVALID${NC}.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_34() {
    local lvl="$1"; while true; do render_header "$lvl" "Ethernet Frame Header Overhead Math"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Standard Ethernet MTU: ${C_CYAN}1500 bytes${NC}."
    echo -e "  Headers: IPv4 Header = ${C_YELLOW}20 bytes${NC} | TCP Header = ${C_YELLOW}20 bytes${NC}.\n"
    echo -e "${BOLD}DECISION: What is standard default TCP MSS on native Ethernet?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} 1460 bytes (1500 - 40)"
    echo -e "  ${C_YELLOW}► [2]${NC} 1500 bytes"
    echo -e "  ${C_YELLOW}► [3]${NC} 1420 bytes"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! 1460 BYTES MSS ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The Maximum Segment Size equals MTU minus IP and TCP header overhead: 1500 - 20 (IP) - 20 (TCP) = ${BOLD}1460 bytes${NC}.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_35() {
    local lvl="$1"; while true; do render_header "$lvl" "Voice-over-IP Quality of Service (QoS)"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Issue: VoIP phone calls stutter whenever office users download large files."
    echo -e "  Requirement: Prioritize voice UDP packets ahead of bulk TCP data.\n"
    echo -e "${BOLD}DECISION: Which table classifies packets and sets DSCP / Priority tags?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Mangle Table (Action: set-priority / mark-packet)"
    echo -e "  ${C_YELLOW}► [2]${NC} Filter Table"
    echo -e "  ${C_YELLOW}► [3]${NC} RAW Table"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! QOS CLASSIFICATION CONFIGURED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The ${BOLD}Mangle table${NC} tags packets with DSCP bits or priority markers, allowing router traffic queues to process latency-sensitive voice frames before bulk transfers.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_36() {
    local lvl="$1"; while true; do render_header "$lvl" "Stateful Discovery via Bare TCP ACK"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Scanner Tactic: Attacker sends raw TCP ACK packets to ports without a prior SYN."
    echo -e "  Goal: Determine whether firewall is stateful (drops ACK) or stateless (sends RST).\n"
    echo -e "${BOLD}DECISION: Why do attackers use TCP ACK scanning?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} To map firewall statefulness (Stateful firewalls DROP bare ACKs as INVALID)"
    echo -e "  ${C_YELLOW}► [2]${NC} To download files"
    echo -e "  ${C_YELLOW}► [3]${NC} To reboot router"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! STATEFUL PROTECTION VERIFIED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Stateless filters let bare ACKs reach the host, generating an RST. A true ${BOLD}stateful firewall${NC} checks Conntrack tables, identifies the unsolicited ACK, and drops it as INVALID.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_37() {
    local lvl="$1"; while true; do render_header "$lvl" "Linux / RouterOS Packet Flow Pipeline"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Packet Ingress: An untrusted frame hits the network interface wire."
    echo -e "  Architecture Audit: Verify the exact order of table processing.\n"
    echo -e "${BOLD}DECISION: What is the true internal traversal sequence?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} RAW -> Conntrack -> Mangle -> NAT (dst-nat) -> Filter"
    echo -e "  ${C_YELLOW}► [2]${NC} Filter -> NAT -> RAW"
    echo -e "  ${C_YELLOW}► [3]${NC} NAT -> Filter -> RAW"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! EXACT PIPELINE CONFIRMED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Internal netfilter processing order is strictly: ${BOLD}RAW${NC} (stateless) ──► ${BOLD}Conntrack${NC} (state tracking) ──► ${BOLD}Mangle${NC} (marking) ──► ${BOLD}dst-nat${NC} (routing prep) ──► ${BOLD}Filter${NC} (security policy).\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_38() {
    local lvl="$1"; while true; do render_header "$lvl" "Volumetric ICMP Ping Rate Limiting"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Condition: Network needs Ping diagnostic reachability, but attacker sends 15,000 pings/sec."
    echo -e "  Objective: Allow legitimate troubleshooting pings without CPU denial-of-service.\n"
    echo -e "${BOLD}DECISION: How to safely permit ping without denial-of-service risk?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Rate-limit ICMP (e.g., limit=5/s, burst=10) on INPUT"
    echo -e "  ${C_YELLOW}► [2]${NC} Block all ICMP permanently"
    echo -e "  ${C_YELLOW}► [3]${NC} Forward ping to LAN"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CORE"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! RATE-LIMITED DIAGNOSTICS ACTIVE ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Complete ICMP blocking breaks reachability verification. Applying ${BOLD}rate-limiting${NC} preserves diagnostic capability while discarding volumetric flood packets.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_39() {
    local lvl="$1"; while true; do render_header "$lvl" "Connection Tracking Table Saturation"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  System Log: ${C_RED}ip_conntrack: table full, dropping packet${NC}."
    echo -e "  State: P2P crawler opened 100,000 parallel sessions, exhausting firewall state table.\n"
    echo -e "${BOLD}DECISION: What happens globally when Conntrack reaches maximum capacity?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} All NEW connections are dropped globally"
    echo -e "  ${C_YELLOW}► [2]${NC} Only UDP is dropped"
    echo -e "  ${C_YELLOW}► [3]${NC} Router switches to FastTrack"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! CONNTRACK EXHAUSTION MITIGATED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Connection tracking tables occupy fixed RAM buffers. Once full, the kernel refuses all ${BOLD}NEW${NC} sessions globally until slots expire or are cleared.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_40() {
    local lvl="$1"; while true; do render_header "$lvl" "Layer 7 Protocol Evasion vs Raw Ports"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Problem: You blocked TCP Ports 80 and 443 to ban video apps, but users still stream."
    echo -e "  Cause: Modern multi-homed apps rotate dynamic high ports and obfuscate payloads.\n"
    echo -e "${BOLD}DECISION: Why does simple layer 4 port blocking fail against advanced apps?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Apps use dynamic high ports and TLS SNI; requires Layer 7 / DPI inspection"
    echo -e "  ${C_YELLOW}► [2]${NC} DNS ignores firewalls"
    echo -e "  ${C_YELLOW}► [3]${NC} Port 443 cannot be filtered"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "WEB_APP"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! DEEP PACKET INSPECTION REQUIRED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Modern cloud applications bypass simple L4 port checks by rotating destinations and tunneling through arbitrary ports. Identifying them requires ${BOLD}Layer 7 / TLS SNI${NC} inspection.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_41() {
    local lvl="$1"; while true; do render_header "$lvl" "Stateless High-Throughput Bypass (notrack)"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Load: Authoritative DNS server processes 250,000 UDP queries per second."
    echo -e "  Issue: Connection tracking memory allocation causes severe bottleneck.\n"
    echo -e "${BOLD}DECISION: What action in the RAW table exempts safe traffic from Conntrack?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Action: notrack (stateless accept)"
    echo -e "  ${C_YELLOW}► [2]${NC} Action: masquerade"
    echo -e "  ${C_YELLOW}► [3]${NC} Action: log"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! STATLESS BYPASS WORKING ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The ${BOLD}notrack${NC} target in the RAW table exempts matching packets from being tracked in RAM, enabling massive throughput for safe, high-volume UDP services.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_42() {
    local lvl="$1"; while true; do render_header "$lvl" "Enterprise Firewall Filter Rule Hierarchy"
    echo -e "${BG_META} [INCIDENT DATA] ${NC}"
    echo -e "  Architectural Review: Production security policy ordered top to bottom."
    echo -e "  Question: Which sequence represents the industry standard golden rule?\n"
    echo -e "${BOLD}DECISION: What is the optimal top-to-bottom rule structure?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} 1: Established/Related -> 2: Drop Invalid -> 3: Specific Whitelist -> 4: Drop All"
    echo -e "  ${C_YELLOW}► [2]${NC} 1: Drop All -> 2: Accept All"
    echo -e "  ${C_YELLOW}► [3]${NC} Whitelist -> Established -> Drop Invalid"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! ARCHITECTURAL HIERARCHY CONFIRMED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Established/Related handles existing flows fast; Drop Invalid purges corrupt packets early; Whitelist permits needed new ports; Drop All enforces Zero-Trust.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

# ==============================================================================
# PHASE 2: 15 PRACTICAL CLI CODE REVIEW & BUG HUNT MODULES
# ==============================================================================

module_43() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Bug Hunt: Web Server Port Forward"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  ${C_CYAN}/ip firewall filter add chain=input protocol=tcp dst-port=443 action=accept${NC}"
    echo -e "  Intent: Allow internet users to access internal LAN Web Server (10.10.40.15).\n"
    echo -e "${BOLD}QUESTION: Why does this rule fail to allow access to the web server?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Wrong chain! Traffic passing to LAN requires chain=forward, not input"
    echo -e "  ${C_YELLOW}► [2]${NC} HTTPS requires protocol=udp"
    echo -e "  ${C_YELLOW}► [3]${NC} Action must be set to drop"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! CHAIN MISMATCH CAUGHT ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The ${BOLD}input${NC} chain terminates on the router itself. Packets destined for internal LAN hosts traverse the ${BOLD}forward${NC} chain.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_44() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Bug Hunt: IoT Return Traffic Blindness"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  ${C_CYAN}/ip firewall filter add chain=forward src-address=10.10.30.0/24 dst-address=10.10.20.0/24 action=drop${NC}"
    echo -e "  Problem: This drops IoT scans, but now you cannot open security camera feeds from your PC.\n"
    echo -e "${BOLD}QUESTION: What parameter must be added to allow you to initiate viewing?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} connection-state=new"
    echo -e "  ${C_YELLOW}► [2]${NC} protocol=icmp"
    echo -e "  ${C_YELLOW}► [3]${NC} action=reject"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! STATE RESTRICTION SPECIFIED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Without ${BOLD}connection-state=new${NC}, the rule drops return packets as well. Restricting it to 'new' lets cameras reply to sessions initiated from your workstation.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_45() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Rule Ordering: FastTrack Pipeline"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  [A] add chain=forward action=drop"
    echo -e "  [B] add chain=forward connection-state=established,related action=fasttrack-connection"
    echo -e "  [C] add chain=forward connection-state=established,related action=accept\n"
    echo -e "${BOLD}QUESTION: What is the mandatory execution sequence?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} B -> C -> A"
    echo -e "  ${C_YELLOW}► [2]${NC} A -> B -> C"
    echo -e "  ${C_YELLOW}► [3]${NC} C -> A -> B"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! PROPER SEQUENCE VERIFIED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} FastTrack marks packets for line-rate offload (B), followed by an accept for non-offloaded packets (C). The final Drop All rule (A) must sit at the bottom.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_46() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Bug Hunt: Outbound NAT Masquerade"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  ${C_CYAN}/ip firewall nat add chain=srcnat action=masquerade${NC}"
    echo -e "  Problem: Inter-VLAN routing is ruined: packets between internal subnets get masqueraded!\n"
    echo -e "${BOLD}QUESTION: What critical matcher is missing?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} out-interface-list=WAN (or out-interface=ether1)"
    echo -e "  ${C_YELLOW}► [2]${NC} protocol=tcp"
    echo -e "  ${C_YELLOW}► [3]${NC} chain=dstnat"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! OUT-INTERFACE RESTRICTION RESTORED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Masquerade without an ${BOLD}out-interface${NC} matcher rewrites every single routed packet, breaking private subnet visibility.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_47() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Missing Parameter: MSS Clamping Syntax"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  ${C_CYAN}/ip firewall mangle add chain=forward protocol=tcp tcp-flags=syn action=change-mss ...${NC}\n"
    echo -e "${BOLD}QUESTION: Which action parameter dynamically clamps MSS to path MTU?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} new-mss=clamp-to-pmtu"
    echo -e "  ${C_YELLOW}► [2]${NC} new-mss=1500"
    echo -e "  ${C_YELLOW}► [3]${NC} action=drop"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! DYNAMIC CLAMP SET ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Specifying ${BOLD}new-mss=clamp-to-pmtu${NC} causes the router to inspect the interface MTU and rewrite the SYN MSS automatically.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_48() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Bug Hunt: DHCP Snooping Bridge Filter"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  ${C_CYAN}/interface bridge filter add chain=forward mac-protocol=ip ip-protocol=udp src-port=67 action=drop${NC}"
    echo -e "  Problem: Clients cannot receive IP addresses from the legitimate server on ether1!\n"
    echo -e "${BOLD}QUESTION: What matcher is needed to target ONLY untrusted ports?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} in-interface=!ether1 (drop on all ports EXCEPT trusted uplink)"
    echo -e "  ${C_YELLOW}► [2]${NC} dst-port=443"
    echo -e "  ${C_YELLOW}► [3]${NC} chain=input"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! TRUSTED PORT EXEMPTED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Applying an inverted interface matcher (${BOLD}!ether1${NC}) drops rogue DHCP server offers while preserving the legitimate uplink server.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_49() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Rule Ordering: Drop Invalid Position"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  [A] add chain=input protocol=tcp dst-port=22 action=accept"
    echo -e "  [B] add chain=input connection-state=invalid action=drop"
    echo -e "  [C] add chain=input connection-state=established,related action=accept\n"
    echo -e "${BOLD}QUESTION: What is the optimal performance and security sequence?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} C -> B -> A"
    echo -e "  ${C_YELLOW}► [2]${NC} A -> B -> C"
    echo -e "  ${C_YELLOW}► [3]${NC} B -> A -> C"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! HIERARCHY VALIDATED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Established (C) accepts existing flows with minimal CPU overhead; Invalid (B) purges broken packets before service whitelists (A).\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_50() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Bug Hunt: RAW Table Stateless Bypass"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  ${C_CYAN}/ip firewall filter add chain=raw action=notrack ...${NC}"
    echo -e "  Error: CLI rejects command with syntax error!\n"
    echo -e "${BOLD}QUESTION: Why is this command syntactically invalid?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} 'raw' is its own table (/ip firewall raw), not a chain in filter"
    echo -e "  ${C_YELLOW}► [2]${NC} action=notrack only works in Mangle"
    echo -e "  ${C_YELLOW}► [3]${NC} chain must be output"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! TABLE PATH CORRECTED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Netfilter organizes rules into separate tables. In RouterOS, stateless pre-conntrack rules live in ${BOLD}/ip firewall raw${NC}.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_51() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Bug Hunt: ICMP Diagnostic Rate Limit"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  ${C_CYAN}/ip firewall filter add chain=input protocol=icmp limit=5,10:packet action=drop${NC}"
    echo -e "  Problem: All pings now fail, and floods still pass through!\n"
    echo -e "${BOLD}QUESTION: What is inverted in this logic?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Action should be accept for matching packets, followed by drop for the rest"
    echo -e "  ${C_YELLOW}► [2]${NC} Protocol should be tcp"
    echo -e "  ${C_YELLOW}► [3]${NC} Limit only works on forward chain"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! INVERTED LIMIT ACTION FIXED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The token-bucket matcher returns true within limits. Therefore, the rate-limited rule must ${BOLD}accept${NC}, followed by a drop for the excess.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_52() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Missing Parameter: Policy-Based Routing"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  ${C_CYAN}/ip firewall mangle add chain=prerouting src-address=10.10.20.0/24 action=mark-routing new-routing-mark=to_WAN2 ...${NC}\n"
    echo -e "${BOLD}QUESTION: What parameter prevents subsequent mangle rules from overriding this mark?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} passthrough=no"
    echo -e "  ${C_YELLOW}► [2]${NC} terminate=yes"
    echo -e "  ${C_YELLOW}► [3]${NC} halt=true"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! PASSTHROUGH DISABLED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} In Mangle, ${BOLD}passthrough=no${NC} terminates table traversal immediately upon match, protecting the newly set routing mark.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_53() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Rule Ordering: Drop All Placement"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  Rule List: #0: Drop Invalid | #1: Drop All | #2: Accept SSH | #3: Accept DNS\n"
    echo -e "${BOLD}QUESTION: Where must the 'Drop All' rule be moved?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} To position #4 (the very bottom of the chain)"
    echo -e "  ${C_YELLOW}► [2]${NC} To position #0"
    echo -e "  ${C_YELLOW}► [3]${NC} To position #2"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! DROP ALL MOVED TO BOTTOM ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The default Drop All rule must always be evaluated ${BOLD}last${NC} so traffic has a chance to match preceding whitelist rules.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_54() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Bug Hunt: Martian Anti-Spoofing Filter"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  ${C_CYAN}/ip firewall filter add chain=forward src-address=10.0.0.0/8 in-interface=ether2 action=drop${NC}"
    echo -e "  Note: ether2 is your internal LAN interface; ether1 is your WAN interface.\n"
    echo -e "${BOLD}QUESTION: What error breaks LAN traffic?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Wrong interface: It drops legitimate LAN hosts! in-interface must be ether1 (WAN)"
    echo -e "  ${C_YELLOW}► [2]${NC} Chain should be output"
    echo -e "  ${C_YELLOW}► [3]${NC} 10.0.0.0/8 is a public IP block"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! INTERFACE CORRECTED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Martian filtering targets private IPs arriving on ${BOLD}external WAN ports${NC}. Applying it to LAN drops legitimate internal traffic.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_55() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Bug Hunt: Transparent DNS Redirect"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  ${C_CYAN}/ip firewall nat add chain=dstnat protocol=tcp dst-port=53 action=redirect${NC}"
    echo -e "  Problem: Clients continue bypassing the local DNS resolver!\n"
    echo -e "${BOLD}QUESTION: What protocol oversight caused this bypass?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Standard DNS queries use UDP, not TCP! Rule must match protocol=udp"
    echo -e "  ${C_YELLOW}► [2]${NC} Port should be 80"
    echo -e "  ${C_YELLOW}► [3]${NC} Chain should be srcnat"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! UDP PROTOCOL SPECIFIED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Standard client DNS lookups use ${BOLD}UDP 53${NC}. A redirect rule matching only TCP leaves standard queries unintercepted.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_56() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Bug Hunt: LAN Client Host Isolation"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  ${C_CYAN}/ip firewall filter add chain=input src-address=10.10.30.0/24 dst-address=10.10.20.0/24 action=drop${NC}"
    echo -e "  Problem: IoT devices can still communicate with workstations on 10.10.20.0/24!\n"
    echo -e "${BOLD}QUESTION: Why does this rule fail to prevent inter-subnet traffic?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} Inter-subnet traffic traverses FORWARD, not INPUT"
    echo -e "  ${C_YELLOW}► [2]${NC} Action must be set to reject"
    echo -e "  ${C_YELLOW}► [3]${NC} IPs must be public"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! FORWARD CHAIN ENFORCED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Packets moving from one client subnet to another traverse the ${BOLD}forward${NC} chain. The input chain only applies to traffic targeting the router itself.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_57() {
    local lvl="$1"; while true; do render_header "$lvl" "CLI Bug Hunt: Reject Reset Flag Misconfiguration"
    echo -e "${BG_META} [COMMAND CODE REVIEW] ${NC}"
    echo -e "  ${C_CYAN}/ip firewall filter add chain=forward protocol=tcp src-address=10.10.30.0/24 action=reject reject-with=icmp-network-unreachable${NC}"
    echo -e "  Problem: TCP applications wait several seconds instead of failing instantly.\n"
    echo -e "${BOLD}QUESTION: What parameter fixes immediate TCP session teardown?${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} reject-with=tcp-reset"
    echo -e "  ${C_YELLOW}► [2]${NC} reject-with=drop"
    echo -e "  ${C_YELLOW}► [3]${NC} action=accept"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! TCP-RESET RESTORED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Using ${BOLD}reject-with=tcp-reset${NC} transmits an immediate TCP RST flag to the client socket, terminating the app connection without delay.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

# ==============================================================================
# PHASE 3: 10 ACTIVE COMMAND VAULTS (BLOCK COMBINATIONS A-E)
# ==============================================================================

module_58() {
    local lvl="$1"; while true; do render_header "$lvl" "Command Vault: Port Forward Destination NAT" "SYNTAX FORGE"
    echo -e "${BG_META} [OBJECTIVE] Forward WAN Port 80 to internal server 10.10.40.15:80 ${NC}\n"
    echo -e "${C_PURPLE}╔════ COMMAND VAULT (SYNTAX BLOCKS) ═════════════════════════════════════════╗${NC}"
    echo -e "║ ${BOLD}${C_YELLOW}[A]${NC} chain=srcnat out-interface=ether1 action=masquerade                  ║"
    echo -e "║ ${BOLD}${C_YELLOW}[B]${NC} chain=dstnat in-interface=ether1 protocol=tcp dst-port=80               ║"
    echo -e "║ ${BOLD}${C_YELLOW}[C]${NC} action=dst-nat to-addresses=10.10.40.15 to-ports=80                      ║"
    echo -e "║ ${BOLD}${C_YELLOW}[D]${NC} chain=forward dst-address=10.10.40.15 action=accept                      ║"
    echo -e "║ ${BOLD}${C_YELLOW}[E]${NC} action=redirect to-ports=8080                                        ║"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${BOLD}DECISION: Select the 2 correct blocks to assemble this NAT rule:${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} [B] + [C]"
    echo -e "  ${C_YELLOW}► [2]${NC} [A] + [C]"
    echo -e "  ${C_YELLOW}► [3]${NC} [B] + [E]"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! PORT FORWARD SYNTAX ASSEMBLED [B + C] ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Destination NAT uses ${BOLD}chain=dstnat${NC} matching WAN ingress, combined with ${BOLD}action=dst-nat to-addresses=...${NC}.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_59() {
    local lvl="$1"; while true; do render_header "$lvl" "Command Vault: Dynamic Brute-Force Blacklisting" "SYNTAX FORGE"
    echo -e "${BG_META} [OBJECTIVE] Auto-ban attackers hitting SSH Port 22 into list 'ssh_blacklist' for 24h ${NC}\n"
    echo -e "${C_PURPLE}╔════ COMMAND VAULT (SYNTAX BLOCKS) ═════════════════════════════════════════╗${NC}"
    echo -e "║ ${BOLD}${C_YELLOW}[A]${NC} chain=input protocol=tcp dst-port=22                                     ║"
    echo -e "║ ${BOLD}${C_YELLOW}[B]${NC} action=add-src-to-address-list address-list=ssh_blacklist timeout=24h      ║"
    echo -e "║ ${BOLD}${C_YELLOW}[C]${NC} chain=forward protocol=tcp dst-port=22 action=drop                        ║"
    echo -e "║ ${BOLD}${C_YELLOW}[D]${NC} action=add-dst-to-address-list address-list=ssh_blacklist                  ║"
    echo -e "║ ${BOLD}${C_YELLOW}[E]${NC} chain=prerouting action=accept                                        ║"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${BOLD}DECISION: Select the 2 correct blocks to assemble this detection rule:${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} [A] + [B]"
    echo -e "  ${C_YELLOW}► [2]${NC} [C] + [B]"
    echo -e "  ${C_YELLOW}► [3]${NC} [A] + [D]"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! BLACKLIST RULE ASSEMBLED [A + B] ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} SSH hits the router on ${BOLD}chain=input${NC}. Adding the attacker source IP with ${BOLD}add-src-to-address-list${NC} and a 24h timeout automates quarantine.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_60() {
    local lvl="$1"; while true; do render_header "$lvl" "Command Vault: Dropping Dynamic Blacklist Ingress" "SYNTAX FORGE"
    echo -e "${BG_META} [OBJECTIVE] Silently discard all traffic from IPs listed in 'ssh_blacklist' ${NC}\n"
    echo -e "${C_PURPLE}╔════ COMMAND VAULT (SYNTAX BLOCKS) ═════════════════════════════════════════╗${NC}"
    echo -e "║ ${BOLD}${C_YELLOW}[A]${NC} chain=input src-address-list=ssh_blacklist                                 ║"
    echo -e "║ ${BOLD}${C_YELLOW}[B]${NC} action=drop                                                                ║"
    echo -e "║ ${BOLD}${C_YELLOW}[C]${NC} chain=input dst-address-list=ssh_blacklist                                 ║"
    echo -e "║ ${BOLD}${C_YELLOW}[D]${NC} action=reject reject-with=icmp-admin-prohibited                             ║"
    echo -e "║ ${BOLD}${C_YELLOW}[E]${NC} chain=output src-address-list=ssh_blacklist action=accept                  ║"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${BOLD}DECISION: Select the 2 correct blocks to enforce the blacklist drop:${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} [A] + [B]"
    echo -e "  ${C_YELLOW}► [2]${NC} [C] + [B]"
    echo -e "  ${C_YELLOW}► [3]${NC} [A] + [D]"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! BLACKLIST ENFORCEMENT ASSEMBLED [A + B] ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The matcher must target ${BOLD}src-address-list${NC} on input, combined with ${BOLD}action=drop${NC} to drop packets without consuming resources.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_61() {
    local lvl="$1"; while true; do render_header "$lvl" "Command Vault: Outbound Internet NAT Masquerade" "SYNTAX FORGE"
    echo -e "${BG_META} [OBJECTIVE] Disguise all outbound LAN traffic exiting through WAN port ether1 ${NC}\n"
    echo -e "${C_PURPLE}╔════ COMMAND VAULT (SYNTAX BLOCKS) ═════════════════════════════════════════╗${NC}"
    echo -e "║ ${BOLD}${C_YELLOW}[A]${NC} chain=srcnat out-interface=ether1                                         ║"
    echo -e "║ ${BOLD}${C_YELLOW}[B]${NC} action=masquerade                                                         ║"
    echo -e "║ ${BOLD}${C_YELLOW}[C]${NC} chain=dstnat in-interface=ether1 action=masquerade                         ║"
    echo -e "║ ${BOLD}${C_YELLOW}[D]${NC} action=accept                                                             ║"
    echo -e "║ ${BOLD}${C_YELLOW}[E]${NC} chain=forward out-interface=ether1 action=masquerade                       ║"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${BOLD}DECISION: Select the 2 correct blocks to configure outbound NAT:${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} [A] + [B]"
    echo -e "  ${C_YELLOW}► [2]${NC} [C] + [B]"
    echo -e "  ${C_YELLOW}► [3]${NC} [E] + [D]"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "NAT_FLAGS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! MASQUERADE CONFIGURED [A + B] ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Masquerade lives strictly in ${BOLD}chain=srcnat${NC} and must be restricted to ${BOLD}out-interface=ether1${NC}.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_62() {
    local lvl="$1"; while true; do render_header "$lvl" "Command Vault: Tunnel MSS Clamping" "SYNTAX FORGE"
    echo -e "${BG_META} [OBJECTIVE] Auto-clamp TCP SYN MSS on WireGuard/PPPoE to prevent packet drop stalls ${NC}\n"
    echo -e "${C_PURPLE}╔════ COMMAND VAULT (SYNTAX BLOCKS) ═════════════════════════════════════════╗${NC}"
    echo -e "║ ${BOLD}${C_YELLOW}[A]${NC} chain=forward protocol=tcp tcp-flags=syn                                 ║"
    echo -e "║ ${BOLD}${C_YELLOW}[B]${NC} action=change-mss new-mss=clamp-to-pmtu passthrough=yes                  ║"
    echo -e "║ ${BOLD}${C_YELLOW}[C]${NC} chain=input protocol=tcp tcp-flags=syn action=change-mss                ║"
    echo -e "║ ${BOLD}${C_YELLOW}[D]${NC} action=drop                                                                ║"
    echo -e "║ ${BOLD}${C_YELLOW}[E]${NC} action=change-mss new-mss=1500                                           ║"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${BOLD}DECISION: Select the 2 correct blocks from Mangle table:${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} [A] + [B]"
    echo -e "  ${C_YELLOW}► [2]${NC} [C] + [B]"
    echo -e "  ${C_YELLOW}► [3]${NC} [A] + [E]"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! MSS CLAMPING ASSEMBLED [A + B] ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Matching ${BOLD}protocol=tcp tcp-flags=syn${NC} and setting ${BOLD}new-mss=clamp-to-pmtu${NC} resolves MTU fragmentation.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_63() {
    local lvl="$1"; while true; do render_header "$lvl" "Command Vault: Established/Related FastTrack" "SYNTAX FORGE"
    echo -e "${BG_META} [OBJECTIVE] Offload active established & related connections to CPU FastPath ${NC}\n"
    echo -e "${C_PURPLE}╔════ COMMAND VAULT (SYNTAX BLOCKS) ═════════════════════════════════════════╗${NC}"
    echo -e "║ ${BOLD}${C_YELLOW}[A]${NC} chain=forward connection-state=established,related                           ║"
    echo -e "║ ${BOLD}${C_YELLOW}[B]${NC} action=fasttrack-connection                                                ║"
    echo -e "║ ${BOLD}${C_YELLOW}[C]${NC} chain=input connection-state=invalid action=fasttrack-connection             ║"
    echo -e "║ ${BOLD}${C_YELLOW}[D]${NC} action=drop                                                                ║"
    echo -e "║ ${BOLD}${C_YELLOW}[E]${NC} chain=raw connection-state=new action=accept                             ║"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${BOLD}DECISION: Select the 2 correct blocks for FastTrack offloading:${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} [A] + [B]"
    echo -e "  ${C_YELLOW}► [2]${NC} [C] + [B]"
    echo -e "  ${C_YELLOW}► [3]${NC} [A] + [D]"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CLI_SYNTAX"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! FASTTRACK RULE ASSEMBLED [A + B] ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} FastTrack pairs ${BOLD}connection-state=established,related${NC} on the forward chain with ${BOLD}action=fasttrack-connection${NC}.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_64() {
    local lvl="$1"; while true; do render_header "$lvl" "Command Vault: Invalid Packet Drop Barrier" "SYNTAX FORGE"
    echo -e "${BG_META} [OBJECTIVE] Purge malformed, out-of-order, and corrupt packets at top of INPUT ${NC}\n"
    echo -e "${C_PURPLE}╔════ COMMAND VAULT (SYNTAX BLOCKS) ═════════════════════════════════════════╗${NC}"
    echo -e "║ ${BOLD}${C_YELLOW}[A]${NC} chain=input connection-state=invalid                                       ║"
    echo -e "║ ${BOLD}${C_YELLOW}[B]${NC} action=drop                                                                ║"
    echo -e "║ ${BOLD}${C_YELLOW}[C]${NC} chain=output connection-state=invalid action=accept                        ║"
    echo -e "║ ${BOLD}${C_YELLOW}[D]${NC} action=reject reject-with=icmp-port-unreachable                          ║"
    echo -e "║ ${BOLD}${C_YELLOW}[E]${NC} chain=forward connection-state=established action=drop                     ║"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${BOLD}DECISION: Select the 2 correct blocks to purge invalid traffic:${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} [A] + [B]"
    echo -e "  ${C_YELLOW}► [2]${NC} [C] + [B]"
    echo -e "  ${C_YELLOW}► [3]${NC} [A] + [D]"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CCNA_CONCEPTS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! INVALID DROP ASSEMBLED [A + B] ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Matching ${BOLD}connection-state=invalid${NC} with ${BOLD}action=drop${NC} purges corrupt frames before they reach whitelist rules.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_65() {
    local lvl="$1"; while true; do render_header "$lvl" "Command Vault: Stateless RAW Pre-Routing Drop" "SYNTAX FORGE"
    echo -e "${BG_META} [OBJECTIVE] Drop incoming WAN attacks on RAW table to preserve connection memory ${NC}\n"
    echo -e "${C_PURPLE}╔════ COMMAND VAULT (SYNTAX BLOCKS) ═════════════════════════════════════════╗${NC}"
    echo -e "║ ${BOLD}${C_YELLOW}[A]${NC} /ip firewall raw add chain=prerouting in-interface=ether1                  ║"
    echo -e "║ ${BOLD}${C_YELLOW}[B]${NC} src-address-list=ddos_attackers action=drop                                ║"
    echo -e "║ ${BOLD}${C_YELLOW}[C]${NC} /ip firewall filter add chain=input in-interface=ether1                    ║"
    echo -e "║ ${BOLD}${C_YELLOW}[D]${NC} action=accept                                                             ║"
    echo -e "║ ${BOLD}${C_YELLOW}[E]${NC} /ip firewall mangle add chain=postrouting action=drop                      ║"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${BOLD}DECISION: Select the 2 correct blocks for stateless DDoS defense:${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} [A] + [B]"
    echo -e "  ${C_YELLOW}► [2]${NC} [C] + [B]"
    echo -e "  ${C_YELLOW}► [3]${NC} [A] + [D]"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! RAW TABLE DROP ASSEMBLED [A + B] ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The ${BOLD}RAW table (prerouting)${NC} evaluates before Conntrack. Dropping traffic here protects RAM from table exhaustion.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_66() {
    local lvl="$1"; while true; do render_header "$lvl" "Command Vault: ICMP Diagnostic Rate Limiter" "SYNTAX FORGE"
    echo -e "${BG_META} [OBJECTIVE] Permit Ping troubleshooting while capping rate to 5 pkts/sec (burst 10) ${NC}\n"
    echo -e "${C_PURPLE}╔════ COMMAND VAULT (SYNTAX BLOCKS) ═════════════════════════════════════════╗${NC}"
    echo -e "║ ${BOLD}${C_YELLOW}[A]${NC} chain=input protocol=icmp limit=5,10:packet                              ║"
    echo -e "║ ${BOLD}${C_YELLOW}[B]${NC} action=accept                                                             ║"
    echo -e "║ ${BOLD}${C_YELLOW}[C]${NC} action=drop                                                                ║"
    echo -e "║ ${BOLD}${C_YELLOW}[D]${NC} chain=forward protocol=udp limit=5,10:packet                              ║"
    echo -e "║ ${BOLD}${C_YELLOW}[E]${NC} chain=output protocol=icmp action=reject                                    ║"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${BOLD}DECISION: Select the 2 correct blocks for the initial rate-limit acceptance rule:${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} [A] + [B]"
    echo -e "  ${C_YELLOW}► [2]${NC} [A] + [C]"
    echo -e "  ${C_YELLOW}► [3]${NC} [D] + [B]"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "CORE"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! RATE-LIMIT ACCEPT ASSEMBLED [A + B] ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The rule matches packets within the token threshold and applies ${BOLD}action=accept${NC}. A subsequent rule drops excess frames.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

module_67() {
    local lvl="$1"; while true; do render_header "$lvl" "Command Vault: Policy-Based Routing Tagging" "SYNTAX FORGE"
    echo -e "${BG_META} [OBJECTIVE] Mark traffic from 10.10.20.0/24 with 'to_WAN2' and stop further mangle ${NC}\n"
    echo -e "${C_PURPLE}╔════ COMMAND VAULT (SYNTAX BLOCKS) ═════════════════════════════════════════╗${NC}"
    echo -e "║ ${BOLD}${C_YELLOW}[A]${NC} chain=prerouting src-address=10.10.20.0/24                                 ║"
    echo -e "║ ${BOLD}${C_YELLOW}[B]${NC} action=mark-routing new-routing-mark=to_WAN2 passthrough=no              ║"
    echo -e "║ ${BOLD}${C_YELLOW}[C]${NC} action=mark-packet new-packet-mark=to_WAN2 passthrough=yes                ║"
    echo -e "║ ${BOLD}${C_YELLOW}[D]${NC} chain=postrouting dst-address=10.10.20.0/24                                ║"
    echo -e "║ ${BOLD}${C_YELLOW}[E]${NC} action=accept                                                             ║"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${BOLD}DECISION: Select the 2 correct blocks to enforce routing policy:${NC}"
    echo -e "  ${C_YELLOW}► [1]${NC} [A] + [B]"
    echo -e "  ${C_YELLOW}► [2]${NC} [A] + [C]"
    echo -e "  ${C_YELLOW}► [3]${NC} [D] + [B]"
    echo -e "  ${C_PURPLE}► [H] Open Intel Dossier (8s Timer)${NC}\n"
    ask_with_timer_or_manual "Select Option [1-3, H]: " "^[1-3]$" "ADVANCED_OPS"
    [ $? -eq 99 ] && { [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Press [ENTER]..."; continue; }
    if [ "$USER_INPUT" == "1" ]; then update_streak_success
        echo -e "\n${BG_ACCEPT} ✔ CORRECT! POLICY ROUTING ASSEMBLED [A + B] ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} The Mangle rule marks the routing path in ${BOLD}prerouting${NC} and sets ${BOLD}passthrough=no${NC} to prevent later rules from overwriting it.\n"
        read -rp "Press [ENTER] to advance..."; return 0;
    else update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "\n${BG_DROP} ✖ WRONG (-1 INTEGRITY) ${NC}\n"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; fi; done
}

# ==============================================================================
# 5 CRITICAL SECURITY ESCALATIONS
# ==============================================================================

apply_integrity_restore() {
    if [ "$INTEGRITY" -lt "$MAX_INTEGRITY" ]; then
        INTEGRITY=$((INTEGRITY + 1))
        echo -e "${C_GREEN}${BOLD}✔ SYSTEM INTEGRITY RESTORED! Current Level: $INTEGRITY/3 Blocks!${NC}"
    else
        echo -e "${C_GREEN}${BOLD}System Integrity at maximum (3/3)!${NC}"
    fi
}

run_critical_security_escalation_1() {
    local b_num="$1"; while true; do
        render_header "$b_num" "INCIDENT RESPONSE: PERIMETER TRIAGE AUDIT" "CRITICAL SECURITY ESCALATION #1"
        echo -e "${BG_ESCALATION} ⚠ SYSTEM BREACH RISK: CONCURRENT ANOMALIES DETECTED (3 CONCURRENT STREAMS) ⚠ ${NC}\n"
        
        echo -e "${BOLD}[STREAM 1/3]${NC} WAN IP ──► Router Port ${C_RED}8291 (WinBox)${NC} | State: ${C_ORANGE}NEW${NC}"
        read -rp "Decision [1: ACCEPT, 2: DROP]: " a1
        [ "$a1" != "2" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S1! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BOLD}[STREAM 2/3]${NC} Web Server 1.1.1.1:443 ──► Workstation | State: ${C_GREEN}ESTABLISHED${NC}"
        read -rp "Decision [1: ACCEPT, 2: DROP]: " a2
        [ "$a2" != "1" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S2! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BOLD}[STREAM 3/3]${NC} IoT Lamp (VLAN 30) ──► PC Port ${C_RED}445 (SMB)${NC} | State: ${C_ORANGE}NEW${NC}"
        read -rp "Decision [1: ACCEPT, 2: DROP]: " a3
        [ "$a3" != "2" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S3! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BG_ACCEPT} ✔ SCENARIO SECURED: POLICIES VERIFIED #${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} WAN management ports are dropped on INPUT; Established sessions are allowed; unsolicited inter-VLAN SMB is dropped on FORWARD.\n"
        apply_integrity_restore
        update_streak_success; read -rp "Press [ENTER] to continue..."; return 0
    done
}

run_critical_security_escalation_2() {
    local b_num="$1"; while true; do
        render_header "$b_num" "INCIDENT RESPONSE: ZERO-DAY FLOOD CONTAINMENT" "CRITICAL SECURITY ESCALATION #2"
        echo -e "${BG_ESCALATION} ⚠ ADVANCED THREAT DETECTED ⚠ ${NC}\n"
        
        echo -e "${BOLD}[STREAM 1/3]${NC} Spoofed WAN packet with source IP ${C_RED}10.10.10.5${NC} hits WAN port."
        read -rp "Decision [1: ACCEPT, 2: DROP (Martian)]: " b1
        [ "$b1" != "2" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S1! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BOLD}[STREAM 2/3]${NC} Admin Mobile ──► Router UDP Port ${C_CYAN}51820 (WireGuard)${NC} | State: ${C_ORANGE}NEW${NC}"
        read -rp "Decision [1: ACCEPT, 2: DROP]: " b2
        [ "$b2" != "1" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S2! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BOLD}[STREAM 3/3]${NC} Packet arriving with simultaneous ${C_RED}SYN+RST flags${NC}."
        read -rp "Decision [1: ACCEPT, 2: DROP as INVALID]: " b3
        [ "$b3" != "2" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S3! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BG_ACCEPT} ✔ SCENARIO SECURED: POLICIES VERIFIED | CHECKPOINT 1 SAVED (STAGE 21)! ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Martians arriving on WAN must be dropped; WireGuard endpoints require accepted handshakes on INPUT; SYN+RST is an invalid flag combo.\n"
        CURRENT_CHECKPOINT=21
        CKPT_MISTAKES=$MISTAKES_COUNT
        CKPT_TIMEOUTS=$TIMEOUTS_COUNT
        CKPT_MAX_STREAK=$MAX_STREAK
        CKPT_START_TIME=$SESSION_START_TIME
        apply_integrity_restore
        update_streak_success; read -rp "Press [ENTER] to continue..."; return 0
    done
}

run_critical_security_escalation_3() {
    local b_num="$1"; while true; do
        render_header "$b_num" "DATA PIPELINE ESCALATION MITIGATION" "CRITICAL SECURITY ESCALATION #3"
        echo -e "${BG_ESCALATION} ⚠ VOLUMETRIC KERNEL THREAT ⚠ ${NC}\n"
        
        echo -e "${BOLD}[STREAM 1/3]${NC} 1 Gbps UDP Flood hits router. Where to drop it BEFORE Conntrack?"
        read -rp "Decision [1: RAW Table, 2: Filter Table]: " c1
        [ "$c1" != "1" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S1! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BOLD}[STREAM 2/3]${NC} HTTPS stalls on VPN tunnel interface. What fixes PMTU mismatch?"
        read -rp "Decision [1: TCP MSS Clamping, 2: Drop Invalid]: " c2
        [ "$c2" != "1" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S2! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BOLD}[STREAM 3/3]${NC} Brute-force hits Port 22. What structure bans IPs automatically?"
        read -rp "Decision [1: Dynamic Address-List, 2: Static ARP]: " c3
        [ "$c3" != "1" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S3! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BG_ACCEPT} ✔ SCENARIO SECURED: POLICIES VERIFIED ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} RAW table drops protect Conntrack memory; MSS clamping fixes tunnel MTU fragmentation; Address-Lists automate dynamic brute-force bans.\n"
        apply_integrity_restore
        update_streak_success; read -rp "Press [ENTER] to continue..."; return 0
    done
}

run_critical_security_escalation_4() {
    local b_num="$1"; while true; do
        render_header "$b_num" "PERIMETER SCAN RECONNAISSANCE MITIGATION" "CRITICAL SECURITY ESCALATION #4"
        echo -e "${BG_ESCALATION} ⚠ STEALTH RECONNAISSANCE DETECTED ⚠ ${NC}\n"
        
        echo -e "${BOLD}[STREAM 1/3]${NC} TCP probe arrives with zero flags (${C_RED}NULL Scan${NC})."
        read -rp "Decision [1: ACCEPT, 2: DROP as INVALID]: " d1
        [ "$d1" != "2" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S1! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BOLD}[STREAM 2/3]${NC} Internal LAN hosts cannot reach internal web app via public WAN IP."
        read -rp "Decision [1: Enable Hairpin NAT, 2: FastTrack]: " d2
        [ "$d2" != "1" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S2! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BOLD}[STREAM 3/3]${NC} High volume ICMP Echo storm threatens gateway stability."
        read -rp "Decision [1: Rate limit (limit/burst), 2: FastTrack all ICMP]: " d3
        [ "$d3" != "1" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S3! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BG_ACCEPT} ✔ SCENARIO SECURED: POLICIES VERIFIED | CHECKPOINT 2 SAVED (STAGE 41)! ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Flagless packets violate TCP state logic; Hairpin NAT resolves loopback routing; ICMP rate limiting preserves diagnostics while stopping flood DOS.\n"
        CURRENT_CHECKPOINT=41
        CKPT_MISTAKES=$MISTAKES_COUNT
        CKPT_TIMEOUTS=$TIMEOUTS_COUNT
        CKPT_MAX_STREAK=$MAX_STREAK
        CKPT_START_TIME=$SESSION_START_TIME
        apply_integrity_restore
        update_streak_success; read -rp "Press [ENTER] to continue..."; return 0
    done
}

run_critical_security_escalation_5() {
    local b_num="$1"; while true; do
        render_header "$b_num" "SENIOR SECURITY ARCHITECT TRIAL" "CRITICAL SECURITY ESCALATION #5"
        echo -e "${BG_ESCALATION} ⚠ FINAL ASSESSMENT: APEX ESCALATION AUDIT ⚠ ${NC}\n"
        
        echo -e "${BOLD}[STREAM 1/4]${NC} Ultra-high volume DNS server saturated by Conntrack RAM overhead."
        read -rp "Decision [1: Action 'notrack' in RAW table, 2: Mangle mark]: " e1
        [ "$e1" != "1" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S1! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BOLD}[STREAM 2/4]${NC} Frame arrives on WAN with source IP ${C_RED}192.168.1.100${NC}."
        read -rp "Decision [1: DROP as Martian/RFC1918, 2: Masquerade]: " e2
        [ "$e2" != "1" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S2! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BOLD}[STREAM 3/4]${NC} What is the exact netfilter traversal order?"
        read -rp "Decision [1: RAW -> Conntrack -> Mangle -> NAT -> Filter, 2: Filter -> NAT -> RAW]: " e3
        [ "$e3" != "1" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S3! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BOLD}[STREAM 4/4]${NC} What occurs when the Conntrack table hits max capacity?"
        read -rp "Decision [1: Global drop of all new connections, 2: Automatic reboot]: " e4
        [ "$e4" != "1" ] && { update_streak_failure; INTEGRITY=$((INTEGRITY - 1)); echo -e "${BG_DROP} FAILED S4! ${NC}"; [ "$INTEGRITY" -le 0 ] && return 2; read -rp "Retry..."; continue; }
        
        echo -e "\n${BG_ACCEPT} ✔ SCENARIO SECURED: POLICIES VERIFIED | 100% OPERATIONAL PROFICIENCY ACHIEVED! ${NC}"
        echo -e "${BOLD}${C_GREEN}EXPLANATION:${NC} Stateless notrack bypasses connection tracking; Martians are unroutable on WAN; Netfilter traverses from RAW down to Filter; full tables cause global new-connection drops.\n"
        apply_integrity_restore
        update_streak_success; read -rp "Press [ENTER] to continue..."; return 0
    done
}

render_big_grade() {
    local num_str="$1"
    local l1="" l2="" l3="" l4=""

    for (( i=0; i<${#num_str}; i++ )); do
        case "${num_str:i:1}" in
            0) l1+=" ████  "; l2+="█    █ "; l3+="█    █ "; l4+=" ████  " ;;
            1) l1+="    ██ "; l2+="  ███  "; l3+="    ██ "; l4+=" █████ " ;;
            2) l1+=" ████  "; l2+="     █ "; l3+=" ████  "; l4+="██████ " ;;
            3) l1+=" ████  "; l2+="   ██  "; l3+="     █ "; l4+=" ████  " ;;
            4) l1+="█    █ "; l2+="█    █ "; l3+="██████ "; l4+="    █  " ;;
            5) l1+="██████ "; l2+="████   "; l3+="    ██ "; l4+="████   " ;;
            6) l1+=" ████  "; l2+="█      "; l3+="█████  "; l4+=" ████  " ;;
            7) l1+="██████ "; l2+="    █  "; l3+="   █   "; l4+="  █    " ;;
            8) l1+=" ████  "; l2+=" ████  "; l3+="█    █ "; l4+=" ████  " ;;
            9) l1+=" ████  "; l2+=" █████ "; l3+="     █ "; l4+=" ████  " ;;
            *) l1+="       "; l2+="       "; l3+="       "; l4+="       " ;;
        esac
    done

    echo -e "${C_GREEN}${BOLD}$l1${NC}"
    echo -e "${C_GREEN}${BOLD}$l2${NC}"
    echo -e "${C_GREEN}${BOLD}$l3${NC}"
    echo -e "${C_GREEN}${BOLD}$l4${NC}"
}

display_final_grade() {
    local end_time=$(date +%s)
    local elapsed=$((end_time - SESSION_START_TIME))
    local minutes=$((elapsed / 60))
    local seconds=$((elapsed % 60))

    local penalty_scaled=$(( (MISTAKES_COUNT * 25) + (TIMEOUTS_COUNT * 40) ))
    local total_penalty=$((penalty_scaled / 10))
    local streak_bonus=$((MAX_STREAK / 5))
    [ "$streak_bonus" -gt 6 ] && streak_bonus=6

    local final_grade=$((100 - total_penalty + streak_bonus))
    [ "$final_grade" -lt 0 ] && final_grade=0
    [ "$final_grade" -gt 100 ] && final_grade=100

    clear
    echo -e "${C_PURPLE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${C_PURPLE}║${NC}        ${BOLD}${C_CYAN}COMPLETION AUDIT: 100% DEFENSE CERTIFIED${NC}                    ${C_PURPLE}║${NC}"
    echo -e "${C_PURPLE}╚════════════════════════════════════════════════════════════════════════════╝${NC}\n"

    echo -e "${BOLD}${C_BLUE}─── [SYSTEM GRADE BREAKDOWN & METRICS] ──────────────────────────────────────${NC}"
    printf "  ${BOLD}%-32s${NC} : ${C_CYAN}100 PTS${NC}\n" "Baseline Score"
    printf "  ${BOLD}%-32s${NC} : %02dm %02ds\n" "Total Execution Time" "$minutes" "$seconds"
    printf "  ${BOLD}%-32s${NC} : %d incidents (${C_RED}-%d PTS${NC})\n" "Wrong Decisions (-2.5 ea)" "$MISTAKES_COUNT" "$(( (MISTAKES_COUNT * 25) / 10 ))"
    printf "  ${BOLD}%-32s${NC} : %d expirations (${C_RED}-%d PTS${NC})\n" "Timer Expirations (-4.0 ea)" "$TIMEOUTS_COUNT" "$((TIMEOUTS_COUNT * 4))"
    printf "  ${BOLD}%-32s${NC} : %d streak (Rec. bonus: ${C_GREEN}+%d PTS${NC})\n" "Max Flawless Streak" "$MAX_STREAK" "$streak_bonus"
    echo -e "${BOLD}${C_BLUE}─────────────────────────────────────────────────────────────────────────────${NC}\n"

    echo -e "${BOLD}FINAL EVALUATION GRADE:${NC}\n"
    render_big_grade "$final_grade"
    echo ""
}

# ==============================================================================
# MAIN RANDOMIZED EXECUTION ENGINE
# ==============================================================================

while true; do
    INTEGRITY=3
    STREAK=0
    CURRENT_CHECKPOINT=1
    SESSION_START_TIME=$(date +%s)
    MISTAKES_COUNT=0
    TIMEOUTS_COUNT=0
    MAX_STREAK=0

    CKPT_MISTAKES=0
    CKPT_TIMEOUTS=0
    CKPT_MAX_STREAK=0
    CKPT_START_TIME=$SESSION_START_TIME

    modules=()
    for ((m=1; m<=67; m++)); do modules+=($m); done

    # Fisher-Yates Shuffle
    for ((i = ${#modules[@]} - 1; i > 0; i--)); do
        j=$((RANDOM % (i + 1)))
        tmp=${modules[i]}
        modules[i]=${modules[j]}
        modules[j]=$tmp
    done

    # Dynamic Escalation Positions
    escalation_1_pos=$((9 + RANDOM % 4))    # ~11
    escalation_2_pos=$((22 + RANDOM % 4))   # ~24 (Checkpoint 1)
    escalation_3_pos=$((36 + RANDOM % 4))   # ~38
    escalation_4_pos=$((50 + RANDOM % 4))   # ~52 (Checkpoint 2)
    escalation_5_pos=$((62 + RANDOM % 3))   # ~63 (Final Trial)

    esc_done_1=false
    esc_done_2=false
    esc_done_3=false
    esc_done_4=false
    esc_done_5=false
    
    idx=0
    while [ "$idx" -lt "${#modules[@]}" ]; do
        current_module_num=$((idx + 1))

        if [ "$idx" -ge "$escalation_1_pos" ] && [ "$esc_done_1" = false ]; then
            run_critical_security_escalation_1 "$current_module_num"
            if [ "$?" -eq 2 ]; then
                echo -e "\n${C_RED}CRITICAL INTEGRITY FAILURE! REVERTING TO CHECKPOINT STAGE $CURRENT_CHECKPOINT...${NC}"
                INTEGRITY=3
                STREAK=0
                idx=$((CURRENT_CHECKPOINT - 1))
                if [ "$CURRENT_CHECKPOINT" -eq 1 ]; then
                    # Hard Reset: Stage 1
                    MISTAKES_COUNT=0
                    TIMEOUTS_COUNT=0
                    MAX_STREAK=0
                    SESSION_START_TIME=$(date +%s)
                    for ((i = ${#modules[@]} - 1; i > 0; i--)); do
                        j=$((RANDOM % (i + 1)))
                        tmp=${modules[i]}
                        modules[i]=${modules[j]}
                        modules[j]=$tmp
                    done
                    esc_done_1=false
                    esc_done_2=false
                    esc_done_3=false
                    esc_done_4=false
                    esc_done_5=false
                else
                    # Soft Reset & Reshuffle Remaining: Checkpoint 21/41
                    MISTAKES_COUNT=$CKPT_MISTAKES
                    TIMEOUTS_COUNT=$CKPT_TIMEOUTS
                    MAX_STREAK=$CKPT_MAX_STREAK
                    SESSION_START_TIME=$CKPT_START_TIME
                    for ((i = ${#modules[@]} - 1; i > idx; i--)); do
                        j=$((idx + RANDOM % (i - idx + 1)))
                        tmp=${modules[i]}
                        modules[i]=${modules[j]}
                        modules[j]=$tmp
                    done
                fi
                read -rp "Press [ENTER] to resume audit..."
                continue
            fi
            esc_done_1=true
        fi

        if [ "$idx" -ge "$escalation_2_pos" ] && [ "$esc_done_2" = false ]; then
            run_critical_security_escalation_2 "$current_module_num"
            if [ "$?" -eq 2 ]; then
                echo -e "\n${C_RED}CRITICAL INTEGRITY FAILURE! REVERTING TO CHECKPOINT STAGE $CURRENT_CHECKPOINT...${NC}"
                INTEGRITY=3
                STREAK=0
                idx=$((CURRENT_CHECKPOINT - 1))
                if [ "$CURRENT_CHECKPOINT" -eq 1 ]; then
                    MISTAKES_COUNT=0
                    TIMEOUTS_COUNT=0
                    MAX_STREAK=0
                    SESSION_START_TIME=$(date +%s)
                    for ((i = ${#modules[@]} - 1; i > 0; i--)); do
                        j=$((RANDOM % (i + 1)))
                        tmp=${modules[i]}
                        modules[i]=${modules[j]}
                        modules[j]=$tmp
                    done
                    esc_done_1=false
                    esc_done_2=false
                    esc_done_3=false
                    esc_done_4=false
                    esc_done_5=false
                else
                    MISTAKES_COUNT=$CKPT_MISTAKES
                    TIMEOUTS_COUNT=$CKPT_TIMEOUTS
                    MAX_STREAK=$CKPT_MAX_STREAK
                    SESSION_START_TIME=$CKPT_START_TIME
                    for ((i = ${#modules[@]} - 1; i > idx; i--)); do
                        j=$((idx + RANDOM % (i - idx + 1)))
                        tmp=${modules[i]}
                        modules[i]=${modules[j]}
                        modules[j]=$tmp
                    done
                fi
                read -rp "Press [ENTER] to resume audit..."
                continue
            fi
            esc_done_2=true
        fi

        if [ "$idx" -ge "$escalation_3_pos" ] && [ "$esc_done_3" = false ]; then
            run_critical_security_escalation_3 "$current_module_num"
            if [ "$?" -eq 2 ]; then
                echo -e "\n${C_RED}CRITICAL INTEGRITY FAILURE! REVERTING TO CHECKPOINT STAGE $CURRENT_CHECKPOINT...${NC}"
                INTEGRITY=3
                STREAK=0
                idx=$((CURRENT_CHECKPOINT - 1))
                if [ "$CURRENT_CHECKPOINT" -eq 1 ]; then
                    MISTAKES_COUNT=0
                    TIMEOUTS_COUNT=0
                    MAX_STREAK=0
                    SESSION_START_TIME=$(date +%s)
                    for ((i = ${#modules[@]} - 1; i > 0; i--)); do
                        j=$((RANDOM % (i + 1)))
                        tmp=${modules[i]}
                        modules[i]=${modules[j]}
                        modules[j]=$tmp
                    done
                    esc_done_1=false
                    esc_done_2=false
                    esc_done_3=false
                    esc_done_4=false
                    esc_done_5=false
                else
                    MISTAKES_COUNT=$CKPT_MISTAKES
                    TIMEOUTS_COUNT=$CKPT_TIMEOUTS
                    MAX_STREAK=$CKPT_MAX_STREAK
                    SESSION_START_TIME=$CKPT_START_TIME
                    for ((i = ${#modules[@]} - 1; i > idx; i--)); do
                        j=$((idx + RANDOM % (i - idx + 1)))
                        tmp=${modules[i]}
                        modules[i]=${modules[j]}
                        modules[j]=$tmp
                    done
                fi
                read -rp "Press [ENTER] to resume audit..."
                continue
            fi
            esc_done_3=true
        fi

        if [ "$idx" -ge "$escalation_4_pos" ] && [ "$esc_done_4" = false ]; then
            run_critical_security_escalation_4 "$current_module_num"
            if [ "$?" -eq 2 ]; then
                echo -e "\n${C_RED}CRITICAL INTEGRITY FAILURE! REVERTING TO CHECKPOINT STAGE $CURRENT_CHECKPOINT...${NC}"
                INTEGRITY=3
                STREAK=0
                idx=$((CURRENT_CHECKPOINT - 1))
                if [ "$CURRENT_CHECKPOINT" -eq 1 ]; then
                    MISTAKES_COUNT=0
                    TIMEOUTS_COUNT=0
                    MAX_STREAK=0
                    SESSION_START_TIME=$(date +%s)
                    for ((i = ${#modules[@]} - 1; i > 0; i--)); do
                        j=$((RANDOM % (i + 1)))
                        tmp=${modules[i]}
                        modules[i]=${modules[j]}
                        modules[j]=$tmp
                    done
                    esc_done_1=false
                    esc_done_2=false
                    esc_done_3=false
                    esc_done_4=false
                    esc_done_5=false
                else
                    MISTAKES_COUNT=$CKPT_MISTAKES
                    TIMEOUTS_COUNT=$CKPT_TIMEOUTS
                    MAX_STREAK=$CKPT_MAX_STREAK
                    SESSION_START_TIME=$CKPT_START_TIME
                    for ((i = ${#modules[@]} - 1; i > idx; i--)); do
                        j=$((idx + RANDOM % (i - idx + 1)))
                        tmp=${modules[i]}
                        modules[i]=${modules[j]}
                        modules[j]=$tmp
                    done
                fi
                read -rp "Press [ENTER] to resume audit..."
                continue
            fi
            esc_done_4=true
        fi

        if [ "$idx" -ge "$escalation_5_pos" ] && [ "$esc_done_5" = false ]; then
            run_critical_security_escalation_5 "$current_module_num"
            if [ "$?" -eq 2 ]; then
                echo -e "\n${C_RED}CRITICAL INTEGRITY FAILURE! REVERTING TO CHECKPOINT STAGE $CURRENT_CHECKPOINT...${NC}"
                INTEGRITY=3
                STREAK=0
                idx=$((CURRENT_CHECKPOINT - 1))
                if [ "$CURRENT_CHECKPOINT" -eq 1 ]; then
                    MISTAKES_COUNT=0
                    TIMEOUTS_COUNT=0
                    MAX_STREAK=0
                    SESSION_START_TIME=$(date +%s)
                    for ((i = ${#modules[@]} - 1; i > 0; i--)); do
                        j=$((RANDOM % (i + 1)))
                        tmp=${modules[i]}
                        modules[i]=${modules[j]}
                        modules[j]=$tmp
                    done
                    esc_done_1=false
                    esc_done_2=false
                    esc_done_3=false
                    esc_done_4=false
                    esc_done_5=false
                else
                    MISTAKES_COUNT=$CKPT_MISTAKES
                    TIMEOUTS_COUNT=$CKPT_TIMEOUTS
                    MAX_STREAK=$CKPT_MAX_STREAK
                    SESSION_START_TIME=$CKPT_START_TIME
                    for ((i = ${#modules[@]} - 1; i > idx; i--)); do
                        j=$((idx + RANDOM % (i - idx + 1)))
                        tmp=${modules[i]}
                        modules[i]=${modules[j]}
                        modules[j]=$tmp
                    done
                fi
                read -rp "Press [ENTER] to resume audit..."
                continue
            fi
            esc_done_5=true
        fi

        m_id=${modules[idx]}
        "module_$m_id" "$current_module_num"
        if [ "$?" -eq 2 ]; then
            echo -e "\n${C_RED}CRITICAL INTEGRITY FAILURE! REVERTING TO CHECKPOINT STAGE $CURRENT_CHECKPOINT...${NC}"
            INTEGRITY=3
            STREAK=0
            idx=$((CURRENT_CHECKPOINT - 1))
            if [ "$CURRENT_CHECKPOINT" -eq 1 ]; then
                MISTAKES_COUNT=0
                TIMEOUTS_COUNT=0
                MAX_STREAK=0
                SESSION_START_TIME=$(date +%s)
                for ((i = ${#modules[@]} - 1; i > 0; i--)); do
                    j=$((RANDOM % (i + 1)))
                    tmp=${modules[i]}
                    modules[i]=${modules[j]}
                    modules[j]=$tmp
                done
                esc_done_1=false
                esc_done_2=false
                esc_done_3=false
                esc_done_4=false
                esc_done_5=false
            else
                MISTAKES_COUNT=$CKPT_MISTAKES
                TIMEOUTS_COUNT=$CKPT_TIMEOUTS
                MAX_STREAK=$CKPT_MAX_STREAK
                SESSION_START_TIME=$CKPT_START_TIME
                for ((i = ${#modules[@]} - 1; i > idx; i--)); do
                    j=$((idx + RANDOM % (i - idx + 1)))
                    tmp=${modules[i]}
                    modules[i]=${modules[j]}
                    modules[j]=$tmp
                done
            fi
            read -rp "Press [ENTER] to resume audit..."
            continue
        fi

        idx=$((idx + 1))
    done

    display_final_grade
    read -rp "Press [ENTER] to restart a fresh randomized run or Ctrl+C to exit..."
done