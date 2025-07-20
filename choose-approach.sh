#!/bin/bash

# WoW Client Orchestration - Approach Comparison
# This script helps you choose the right orchestration approach

echo "🎮 WoW Docker Client - Orchestration Approach Selector"
echo "====================================================="
echo ""

function show_comparison() {
    echo "📊 COMPARISON OF APPROACHES:"
    echo ""
    
    printf "%-25s %-20s %-20s %-20s\n" "Feature" "Dynamic Docker" "Docker Swarm" "Generated Compose"
    printf "%-25s %-20s %-20s %-20s\n" "$(printf '%*s' 25 '' | tr ' ' '-')" "$(printf '%*s' 20 '' | tr ' ' '-')" "$(printf '%*s' 20 '' | tr ' ' '-')" "$(printf '%*s' 20 '' | tr ' ' '-')"
    printf "%-25s %-20s %-20s %-20s\n" "Setup Complexity" "Low" "Medium" "Low"
    printf "%-25s %-20s %-20s %-20s\n" "Scaling Speed" "Fast" "Very Fast" "Medium"
    printf "%-25s %-20s %-20s %-20s\n" "Max Instances" "Unlimited*" "Unlimited" "Unlimited"
    printf "%-25s %-20s %-20s %-20s\n" "Resource Overhead" "Low" "Medium" "Low"
    printf "%-25s %-20s %-20s %-20s\n" "Auto-restart" "Yes" "Yes" "Yes"
    printf "%-25s %-20s %-20s %-20s\n" "Load Balancing" "Manual" "Automatic" "Manual"
    printf "%-25s %-20s %-20s %-20s\n" "Multi-node" "No" "Yes" "No"
    printf "%-25s %-20s %-20s %-20s\n" "Maintenance" "Easy" "Medium" "Easy"
    printf "%-25s %-20s %-20s %-20s\n" "Production Ready" "Yes" "Enterprise" "Yes"
    
    echo ""
    echo "*Limited by available ports and system resources"
}

function get_user_requirements() {
    echo "🤔 REQUIREMENTS QUESTIONNAIRE:"
    echo ""
    
    echo "1. How many instances do you typically need?"
    echo "   a) 1-10 instances"
    echo "   b) 10-50 instances" 
    echo "   c) 50+ instances"
    read -p "   Your choice (a/b/c): " instances_need
    
    echo ""
    echo "2. Do you need multi-node (cluster) support?"
    echo "   a) No, single machine is fine"
    echo "   b) Yes, I want to distribute across multiple machines"
    read -p "   Your choice (a/b): " multi_node
    
    echo ""
    echo "3. How important is automatic load balancing?"
    echo "   a) Not important, manual is fine"
    echo "   b) Very important, I need automatic load balancing"
    read -p "   Your choice (a/b): " load_balancing
    
    echo ""
    echo "4. What's your team's Docker experience level?"
    echo "   a) Basic (docker run, docker-compose)"
    echo "   b) Advanced (Docker Swarm, Kubernetes)"
    read -p "   Your choice (a/b): " experience
    
    echo ""
    echo "5. How often will you scale up/down?"
    echo "   a) Rarely (set and forget)"
    echo "   b) Frequently (multiple times per day)"
    read -p "   Your choice (a/b): " scaling_frequency
    
    # Calculate recommendation
    calculate_recommendation
}

function calculate_recommendation() {
    local score_dynamic=0
    local score_swarm=0
    local score_compose=0
    
    # Instance count scoring
    case $instances_need in
        "a") score_dynamic=$((score_dynamic + 3)); score_compose=$((score_compose + 2)); score_swarm=$((score_swarm + 1)) ;;
        "b") score_dynamic=$((score_dynamic + 2)); score_compose=$((score_compose + 1)); score_swarm=$((score_swarm + 3)) ;;
        "c") score_dynamic=$((score_dynamic + 1)); score_compose=$((score_compose + 1)); score_swarm=$((score_swarm + 3)) ;;
    esac
    
    # Multi-node scoring
    case $multi_node in
        "a") score_dynamic=$((score_dynamic + 3)); score_compose=$((score_compose + 2)); score_swarm=$((score_swarm + 1)) ;;
        "b") score_dynamic=$((score_dynamic + 0)); score_compose=$((score_compose + 0)); score_swarm=$((score_swarm + 3)) ;;
    esac
    
    # Load balancing scoring
    case $load_balancing in
        "a") score_dynamic=$((score_dynamic + 3)); score_compose=$((score_compose + 2)); score_swarm=$((score_swarm + 1)) ;;
        "b") score_dynamic=$((score_dynamic + 1)); score_compose=$((score_compose + 1)); score_swarm=$((score_swarm + 3)) ;;
    esac
    
    # Experience scoring
    case $experience in
        "a") score_dynamic=$((score_dynamic + 3)); score_compose=$((score_compose + 3)); score_swarm=$((score_swarm + 1)) ;;
        "b") score_dynamic=$((score_dynamic + 2)); score_compose=$((score_compose + 2)); score_swarm=$((score_swarm + 3)) ;;
    esac
    
    # Scaling frequency scoring
    case $scaling_frequency in
        "a") score_dynamic=$((score_dynamic + 2)); score_compose=$((score_compose + 3)); score_swarm=$((score_swarm + 2)) ;;
        "b") score_dynamic=$((score_dynamic + 3)); score_compose=$((score_compose + 1)); score_swarm=$((score_swarm + 3)) ;;
    esac
    
    # Determine winner
    if [ $score_dynamic -ge $score_swarm ] && [ $score_dynamic -ge $score_compose ]; then
        recommended="Dynamic Docker"
        script="manage-clients-dynamic.sh"
    elif [ $score_swarm -ge $score_compose ]; then
        recommended="Docker Swarm"
        script="manage-clients-swarm.sh"
    else
        recommended="Generated Compose"
        script="manage-clients.sh (updated)"
    fi
    
    show_recommendation
}

function show_recommendation() {
    echo ""
    echo "🎯 RECOMMENDATION:"
    echo "=================="
    echo ""
    echo "Based on your requirements, we recommend: 🌟 $recommended"
    echo ""
    
    case $recommended in
        "Dynamic Docker")
            echo "✅ Best for your needs because:"
            echo "   • Simple setup and management"
            echo "   • Great for single-node deployments"
            echo "   • Efficient resource usage"
            echo "   • Easy debugging and maintenance"
            echo ""
            echo "🚀 Quick start:"
            echo "   ./manage-clients-dynamic.sh setup"
            echo "   ./manage-clients-dynamic.sh start 5"
            ;;
        "Docker Swarm")
            echo "✅ Best for your needs because:"
            echo "   • Enterprise-grade scaling"
            echo "   • Multi-node support"
            echo "   • Automatic load balancing"
            echo "   • Built-in health checks"
            echo ""
            echo "🚀 Quick start:"
            echo "   ./manage-clients-swarm.sh init"
            echo "   ./manage-clients-swarm.sh deploy 10"
            ;;
        "Generated Compose")
            echo "✅ Best for your needs because:"
            echo "   • Familiar docker-compose workflow"
            echo "   • Good for stable deployments"
            echo "   • Easy to customize"
            echo "   • Standard Docker tooling"
            echo ""
            echo "🚀 Quick start:"
            echo "   ./manage-clients.sh setup"
            echo "   ./manage-clients.sh start 5"
            ;;
    esac
    
    echo ""
    echo "📚 For detailed documentation, see: README-dynamic.md"
}

function show_menu() {
    echo "Choose an option:"
    echo "1) Show feature comparison"
    echo "2) Get personalized recommendation"
    echo "3) Show all available scripts"
    echo "4) Exit"
    echo ""
    read -p "Your choice (1-4): " choice
    
    case $choice in
        1) show_comparison; echo ""; show_menu ;;
        2) get_user_requirements ;;
        3) show_scripts; echo ""; show_menu ;;
        4) echo "Happy orchestrating! 🎮"; exit 0 ;;
        *) echo "Invalid choice. Please try again."; echo ""; show_menu ;;
    esac
}

function show_scripts() {
    echo ""
    echo "📁 AVAILABLE SCRIPTS:"
    echo "===================="
    echo ""
    
    if [ -f "manage-clients-dynamic.sh" ]; then
        echo "✅ manage-clients-dynamic.sh    (Dynamic Docker - Recommended)"
    else
        echo "❌ manage-clients-dynamic.sh    (Not found)"
    fi
    
    if [ -f "manage-clients-swarm.sh" ]; then
        echo "✅ manage-clients-swarm.sh      (Docker Swarm)"
    else
        echo "❌ manage-clients-swarm.sh      (Not found)"
    fi
    
    if [ -f "manage-clients.sh" ]; then
        echo "✅ manage-clients.sh            (Updated with generation)"
    else
        echo "❌ manage-clients.sh            (Not found)"
    fi
    
    if [ -f "generate-compose.sh" ]; then
        echo "✅ generate-compose.sh          (Compose generation utility)"
    else
        echo "❌ generate-compose.sh          (Not found)"
    fi
    
    echo ""
    echo "📄 Documentation:"
    if [ -f "README-dynamic.md" ]; then
        echo "✅ README-dynamic.md            (Comprehensive guide)"
    else
        echo "❌ README-dynamic.md            (Not found)"
    fi
}

# Main execution
clear
show_menu
