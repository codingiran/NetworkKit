#!/bin/bash

# NetworkKit 测试运行脚本
# 这个脚本提供了多种测试运行选项

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${2}${1}${NC}"
}

# 打印标题
print_title() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# 显示使用帮助
show_help() {
    echo "NetworkKit 测试运行脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示此帮助信息"
    echo "  -a, --all               运行所有测试 (默认)"
    echo "  -u, --unit              仅运行单元测试"
    echo "  -p, --performance       仅运行性能测试"
    echo "  -e, --examples          仅运行使用示例"
    echo "  -v, --verbose           详细输出"
    echo "  -c, --coverage          启用代码覆盖率"
    echo "  -s, --silent            静默模式"
    echo "  -r, --release           Release模式编译"
    echo ""
    echo "示例:"
    echo "  $0 -a -v               运行所有测试（详细输出）"
    echo "  $0 -u                  仅运行单元测试"
    echo "  $0 -p -c               运行性能测试并生成覆盖率报告"
    echo "  $0 -e -v               运行使用示例（详细输出）"
    echo ""
}

# 默认参数
RUN_ALL=true
RUN_UNIT=false
RUN_PERFORMANCE=false
RUN_EXAMPLES=false
VERBOSE=false
COVERAGE=false
SILENT=false
RELEASE=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -a|--all)
            RUN_ALL=true
            RUN_UNIT=false
            RUN_PERFORMANCE=false
            RUN_EXAMPLES=false
            shift
            ;;
        -u|--unit)
            RUN_ALL=false
            RUN_UNIT=true
            shift
            ;;
        -p|--performance)
            RUN_ALL=false
            RUN_PERFORMANCE=true
            shift
            ;;
        -e|--examples)
            RUN_ALL=false
            RUN_EXAMPLES=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -s|--silent)
            SILENT=true
            shift
            ;;
        -r|--release)
            RELEASE=true
            shift
            ;;
        *)
            print_message "未知选项: $1" $RED
            show_help
            exit 1
            ;;
    esac
done

# 构建基础命令
BASE_CMD="swift test"

# 添加覆盖率选项
if [ "$COVERAGE" = true ]; then
    BASE_CMD="$BASE_CMD --enable-code-coverage"
fi

# 添加编译配置
if [ "$RELEASE" = true ]; then
    BASE_CMD="$BASE_CMD --configuration release"
fi

# 添加输出选项
if [ "$VERBOSE" = true ]; then
    BASE_CMD="$BASE_CMD --verbose"
fi

# 开始执行测试
print_title "NetworkKit 测试套件"

# 检查是否在正确的目录中
if [ ! -f "Package.swift" ]; then
    print_message "错误: 请在NetworkKit项目根目录中运行此脚本" $RED
    exit 1
fi

# 运行测试
if [ "$RUN_ALL" = true ]; then
    print_title "运行所有测试"
    if [ "$SILENT" = false ]; then
        print_message "正在运行所有测试..." $YELLOW
    fi
    
    if [ "$SILENT" = true ]; then
        $BASE_CMD > /dev/null 2>&1
    else
        $BASE_CMD
    fi
    
    if [ $? -eq 0 ]; then
        print_message "✅ 所有测试通过!" $GREEN
    else
        print_message "❌ 测试失败!" $RED
        exit 1
    fi
fi

if [ "$RUN_UNIT" = true ]; then
    print_title "运行单元测试"
    if [ "$SILENT" = false ]; then
        print_message "正在运行单元测试..." $YELLOW
    fi
    
    if [ "$SILENT" = true ]; then
        $BASE_CMD --filter NetworkKitTests > /dev/null 2>&1
    else
        $BASE_CMD --filter NetworkKitTests
    fi
    
    if [ $? -eq 0 ]; then
        print_message "✅ 单元测试通过!" $GREEN
    else
        print_message "❌ 单元测试失败!" $RED
        exit 1
    fi
fi

if [ "$RUN_PERFORMANCE" = true ]; then
    print_title "运行性能测试"
    if [ "$SILENT" = false ]; then
        print_message "正在运行性能测试..." $YELLOW
    fi
    
    if [ "$SILENT" = true ]; then
        $BASE_CMD --filter NetworkKitPerformanceTests > /dev/null 2>&1
    else
        $BASE_CMD --filter NetworkKitPerformanceTests
    fi
    
    if [ $? -eq 0 ]; then
        print_message "✅ 性能测试通过!" $GREEN
    else
        print_message "❌ 性能测试失败!" $RED
        exit 1
    fi
fi

if [ "$RUN_EXAMPLES" = true ]; then
    print_title "运行使用示例"
    if [ "$SILENT" = false ]; then
        print_message "正在运行使用示例..." $YELLOW
    fi
    
    if [ "$SILENT" = true ]; then
        $BASE_CMD --filter NetworkKitUsageExamples > /dev/null 2>&1
    else
        $BASE_CMD --filter NetworkKitUsageExamples
    fi
    
    if [ $? -eq 0 ]; then
        print_message "✅ 使用示例测试通过!" $GREEN
    else
        print_message "❌ 使用示例测试失败!" $RED
        exit 1
    fi
fi

# 显示覆盖率报告
if [ "$COVERAGE" = true ]; then
    print_title "代码覆盖率报告"
    if command -v xcrun &> /dev/null; then
        print_message "生成代码覆盖率报告..." $YELLOW
        # 这里可以添加生成覆盖率报告的具体命令
        # 例如使用 xcrun xccov 来生成报告
        print_message "覆盖率报告已生成" $GREEN
    else
        print_message "警告: 未找到 xcrun，无法生成覆盖率报告" $YELLOW
    fi
fi

print_title "测试完成"
print_message "所有指定的测试都已成功完成!" $GREEN

# 显示一些有用的信息
if [ "$SILENT" = false ]; then
    echo ""
    echo "更多信息:"
    echo "  - 查看测试文档: Tests/README.md"
    echo "  - 查看使用示例: Tests/NetworkKitTests/NetworkKitUsageExamples.swift"
    echo "  - 查看性能测试: Tests/NetworkKitTests/NetworkKitPerformanceTests.swift"
    echo "  - 项目总结: NetworkKit_Test_Summary.md"
    echo ""
fi 