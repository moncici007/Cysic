#!/bin/bash

# Cysic 代理和证明器安装路径
CYSIC_AGENT_PATH="$HOME/cysic-prover-agent"
CYSIC_PROVER_PATH="$HOME/cysic-aleo-prover"

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 安装必要的依赖
function install_dependencies() {
    apt update && apt upgrade -y
    apt install curl wget -y
}

# 检查并安装 Node.js 和 npm
function check_and_install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js 已安装，版本: $(node -v)"
    else
        echo "Node.js 未安装，正在安装..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    if command -v npm > /dev/null 2>&1; then
        echo "npm 已安装，版本: $(npm -v)"
    else
        echo "npm 未安装，正在安装..."
        sudo apt-get install -y npm
    fi
}

# 检查并安装 PM2
function check_and_install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 已安装，版本: $(pm2 -v)"
    else
        echo "PM2 未安装，正在安装..."
        npm install pm2@latest -g
    fi
}

# 安装代理服务器
function install_agent() {
    # 创建代理目录
    rm -rf $CYSIC_AGENT_PATH
    mkdir -p $CYSIC_AGENT_PATH
    cd $CYSIC_AGENT_PATH

    # 下载代理服务器
    wget https://github.com/cysic-labs/aleo-miner/releases/download/v0.1.15/cysic-prover-agent-v0.1.15.tgz
    tar -xf cysic-prover-agent-v0.1.15.tgz
    cd cysic-prover-agent-v0.1.15

    # 配置防火墙
    sudo ufw allow 9000/tcp

    # 启动代理服务器
    pm2 start start.sh --name "cysic-prover-agent"
    echo "代理服务器已启动。"
}

# 安装证明器
function install_prover() {
    # 创建证明器目录
    rm -rf $CYSIC_PROVER_PATH
    mkdir -p $CYSIC_PROVER_PATH
    cd $CYSIC_PROVER_PATH

    # 下载证明器
    wget https://github.com/cysic-labs/aleo-miner/releases/download/v0.1.17/cysic-aleo-prover-v0.1.17.tgz
    tar -xf cysic-aleo-prover-v0.1.17.tgz 
    cd cysic-aleo-prover-v0.1.17

    # 获取用户的奖励领取地址
    read -p "请输入您的奖励领取地址 (Aleo 地址,没有的话进入 https://www.provable.tools/account 创建): " CLAIM_REWARD_ADDRESS
    
    # 获取用户的 IP 地址
    read -p "请输入证明器的 IP 地址 (例如: 192.168.1.100): " PROVER_IP

    # 创建启动脚本
    cat <<EOF > start_prover.sh
#!/bin/bash
cd $CYSIC_PROVER_PATH/cysic-aleo-prover-v0.1.17
export LD_LIBRARY_PATH=./:\$LD_LIBRARY_PATH
./cysic-aleo-prover -l ./prover.log -a $PROVER_IP -w $CLAIM_REWARD_ADDRESS.machine_name_1 -tls=true -p asia.aleopool.cysic.xyz:16699
EOF
    chmod +x start_prover.sh

    # 使用 PM2 启动证明器
    pm2 start start_prover.sh --name "cysic-aleo-prover"
    echo "证明器已安装并启动。"
}

# 查看证明器日志
function check_prover_logs() {
    pm2 logs cysic-aleo-prover
}

# 停止证明器
function stop_prover() {
    pm2 stop cysic-aleo-prover
    echo "证明器已停止。"
}

# 启动证明器
function start_prover() {
    pm2 start cysic-aleo-prover
    echo "证明器已启动。"
}

# 重启证明器
function restart_prover() {
    pm2 restart cysic-aleo-prover
    echo "证明器已重启。"
}

# 主菜单
function main_menu() {
    clear
    echo "脚本以及教程由推特用户大赌哥 @y95277777 编写，免费开源，请勿相信收费"
    echo "========================= Cysic 代理和证明器安装 ======================================="
    echo "请选择要执行的操作:"
    echo "1. 安装 Cysic 代理服务器"
    echo "2. 安装 Cysic 证明器"
    echo "3. 查看证明器日志"
    echo "4. 停止证明器"
    echo "5. 启动证明器"
    echo "6. 重启证明器"
    read -p "请输入选项（1-6）: " OPTION
    case $OPTION in
    1) install_dependencies && check_and_install_nodejs_and_npm && check_and_install_pm2 && install_agent ;;
    2) install_dependencies && check_and_install_nodejs_and_npm && check_and_install_pm2 && install_prover ;;
    3) check_prover_logs ;;
    4) stop_prover ;;
    5) start_prover ;;
    6) restart_prover ;;
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
