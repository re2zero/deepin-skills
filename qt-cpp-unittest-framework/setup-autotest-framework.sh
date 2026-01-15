#!/bin/bash

################################################################################
# AutoTest Framework Generator - Enhanced Version
# 智能 C++/Qt 单元测试框架生成器
#
# 功能：
# - 智能检测项目结构（源码、库、插件、服务）
# - 自动识别 Qt/GTest 依赖
# - 生成完整的 stub-ext Mock 工具
# - 生成适配的 CMake 配置
# - 生成手动运行脚本 (run-ut.sh)
# - 验证空框架可运行
################################################################################

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 版本信息
VERSION="4.0.0"

################################################################################
# 辅助函数
################################################################################

print_header() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║     AutoTest Framework Generator v${VERSION}                      ║"
    echo "║          智能 C++/Qt 单元测试框架生成器                           ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[i]${NC} $1"
}

show_usage() {
    cat << EOF
用法: $0 [选项] [项目根目录]

选项:
    -h, --help              显示帮助信息
    -v, --version           显示版本信息
    -p, --project-dir DIR   项目根目录（默认为当前目录）
    -s, --script-dir DIR    工具脚本目录（用于定位 stub 源文件）

示例:
    # 基本用法（在当前目录）
    $0

    # 指定项目目录
    $0 -p /path/to/project

    # 指定工具目录
    $0 -p /path/to/project -s /path/to/tools

EOF
}

################################################################################
# 项目结构检测
################################################################################

detect_project_structure() {
    print_step 1 "智能检测项目结构..."

    # 检查 CMakeLists.txt
    if [ ! -f "${PROJECT_ROOT}/CMakeLists.txt" ]; then
        print_error "未找到 CMakeLists.txt，这不是一个有效的 CMake 项目"
        exit 1
    fi
    print_success "找到 CMakeLists.txt"

    # 检测源码目录
    SRC_DIRS=("src" "source" "lib" "libs")
    SOURCE_DIR=""
    for dir in "${SRC_DIRS[@]}"; do
        if [ -d "${PROJECT_ROOT}/${dir}" ]; then
            SOURCE_DIR="${PROJECT_ROOT}/${dir}"
            print_success "检测到源码目录: ${dir}/"
            break
        fi
    done

    if [ -z "$SOURCE_DIR" ]; then
        print_warning "未检测到标准源码目录，将在项目根目录创建测试"
        SOURCE_DIR="${PROJECT_ROOT}"
    fi

    # 分析源码目录结构（用于自适应测试目录）
    SUBDIRS=""
    STANDALONE_SRC=""
    
    if [ -d "$SOURCE_DIR" ]; then
        SUBDIRS=$(find "$SOURCE_DIR" -maxdepth 1 -type d ! -path "$SOURCE_DIR" ! -name "test*" ! -name "3rdparty" -exec basename {} \; | sort)
        STANDALONE_SRC=$(find "$SOURCE_DIR" -maxdepth 1 -type f \( -name "*.cpp" -o -name "*.h" \) ! -name "main.cpp" ! -name "test_*" | wc -l)
        
        if [ -n "$SUBDIRS" ]; then
            print_success "检测到源码子目录: $(echo $SUBDIRS | tr '\n' ' ')"
        fi
        if [ "$STANDALONE_SRC" -gt 0 ]; then
            print_success "检测到独立源文件（将归入 libs/ 目录）"
        fi
    fi
    
    # 检测是否使用 Qt
    USE_QT=false
    if grep -q "Qt[56]" "${PROJECT_ROOT}/CMakeLists.txt" 2>/dev/null || \
       grep -q "find_package(Qt" "${PROJECT_ROOT}/CMakeLists.txt" 2>/dev/null || \
       grep -q "Qt[56]" "$SOURCE_DIR"/* 2>/dev/null; then
         USE_QT=true
         print_success "检测到 Qt 支持"
     fi
    
    # 检测插件目录
    PLUGIN_DIR=""
    if [ -d "${PROJECT_ROOT}/plugins" ]; then
        PLUGIN_DIR="${PROJECT_ROOT}/plugins"
        print_success "检测到插件目录: plugins/"
    fi
    
    # 检测服务目录
    SERVICE_DIR=""
    if [ -d "${PROJECT_ROOT}/services" ]; then
        SERVICE_DIR="${PROJECT_ROOT}/services"
        print_success "检测到服务目录: services/"
    fi

    # 检测 C++ 标准
    CPP_STANDARD="14"
    if grep -q "CMAKE_CXX_STANDARD.*17" "${PROJECT_ROOT}/CMakeLists.txt" 2>/dev/null; then
        CPP_STANDARD="17"
        print_success "检测到 C++17 标准"
    elif grep -q "CMAKE_CXX_STANDARD.*20" "${PROJECT_ROOT}/CMakeLists.txt" 2>/dev/null; then
        CPP_STANDARD="20"
        print_success "检测到 C++20 标准"
    fi

    # 检测 DTK 框架
    USE_DTK=false
    if grep -qi "DTK\|dtk" "${PROJECT_ROOT}/CMakeLists.txt" 2>/dev/null; then
        USE_DTK=true
        print_success "检测到 DTK 框架"
    fi

    print_info "项目结构分析完成"
    echo ""
}

################################################################################
# 创建目录结构
################################################################################

create_directory_structure() {
    print_step 2 "创建测试目录结构..."
    
    # 创建测试目录
    mkdir -p "${AUTOTEST_ROOT}"
    mkdir -p "${AUTOTEST_ROOT}/3rdparty/testutils"
    
    # 根据项目结构创建对应的测试目录
    if [ -n "$SUBDIRS" ]; then
        for dir in $SUBDIRS; do
            mkdir -p "${AUTOTEST_ROOT}/${dir}"
            print_info "创建测试目录: ${dir}/"
        done
    fi
    
    # 如果有独立源文件，创建 libs 目录
    if [ "$STANDALONE_SRC" -gt 0 ]; then
        mkdir -p "${AUTOTEST_ROOT}/libs"
        print_info "创建测试目录: libs/（用于独立源文件）"
    fi
    
    print_success "目录结构创建完成"
    echo ""
}

################################################################################
# 复制 stub-ext 工具（从本地技能资源）
################################################################################

copy_stub_ext() {
    print_step 3 "复制 stub-ext Mock 工具..."

    local STUBUTILS_DIR="${AUTOTEST_ROOT}/3rdparty/testutils"
    local SKILL_RESOURCE_DIR="${SCRIPT_DIR}/resources/testutils"

    # 检查是否已经存在且完整（至少 6 个文件）
    if [ -d "$STUBUTILS_DIR" ] && [ $(find "$STUBUTILS_DIR" \( -name "*.h" -o -name "*.cpp" \) | wc -l) -ge 6 ]; then
        print_success "stub-ext 工具已存在且完整"
        return 0
    fi

    # 从技能资源目录复制
    if [ -d "$SKILL_RESOURCE_DIR" ]; then
        cp -r "$SKILL_RESOURCE_DIR" "${AUTOTEST_ROOT}/3rdparty/"
        local copied_files=$(find "$STUBUTILS_DIR" \( -name "*.h" -o -name "*.cpp" \) | wc -l)
        print_success "stub-ext 工具复制完成 (${copied_files} 个文件）"
        return 0
    else
        print_error "无法找到技能资源目录: $SKILL_RESOURCE_DIR"
        print_info "技能资源应位于: ~/.claude/skills/qt-cpp-unittest-framework/resources/testutils/"
        return 1
    fi
}

################################################################################
# 复制 stub 源文件（调用 copy_stub_ext）
################################################################################

copy_stub_sources() {
    copy_stub_ext
}


################################################################################
# 生成 CMake 测试工具
################################################################################

generate_cmake_test_utils() {
    print_step 4 "生成 CMake 测试工具..."

    mkdir -p "${PROJECT_ROOT}/cmake"

    cat > "${PROJECT_ROOT}/cmake/UnitTestUtils.cmake" << 'CMAKEOF'
# UnitTestUtils.cmake - 通用 C++ 单元测试 CMake 工具
# 版本: 4.0.0

cmake_minimum_required(VERSION 3.10)

# 全局变量
set(CPP_STUB_SRC "" CACHE INTERNAL "Stub source files for testing")
set(UT_TEST_CXX_FLAGS "" CACHE INTERNAL "Test-specific CXX flags")

#=============================================================================
# 条件添加子目录
#=============================================================================

function(add_subdirectory_if_exists dir)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dir}/CMakeLists.txt")
        add_subdirectory(${dir})
    elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${dir}")
        message(STATUS "UT: Subdirectory ${dir} exists but has no CMakeLists.txt")
    else()
        message(STATUS "UT: Subdirectory ${dir} does not exist, skipping")
    endif()
endfunction()

#=============================================================================
# 测试环境初始化
#=============================================================================

function(ut_init_test_environment)
    message(STATUS "UT: Initializing test environment...")

    # 查找测试框架
    find_package(GTest REQUIRED)
    include_directories(${GTEST_INCLUDE_DIRS})

    # Qt 测试支持
    if(USE_QT)
        find_package(Qt6 COMPONENTS Test QUIET)
        if(NOT Qt6Test_FOUND)
            find_package(Qt5 COMPONENTS Test QUIET)
        endif()
        if(Qt6Test_FOUND OR Qt5Test_FOUND)
            if(Qt6Test_FOUND)
                link_libraries(Qt6::Test)
                message(STATUS "UT: Using Qt6 Test")
            else()
                link_libraries(Qt5::Test)
                message(STATUS "UT: Using Qt5 Test")
            endif()
        endif()
    endif()

    # 链接基础库
    link_libraries(${GTEST_LIBRARIES} pthread stdc++fs)

    # 设置测试定义
    add_definitions(-DDEBUG_STUB_INVOKE)

    # 设置 stub 工具
    ut_setup_test_stubs()

    # 设置覆盖率
    ut_setup_coverage()

    message(STATUS "UT: Test environment initialized")
endfunction()

#=============================================================================
# Stub 工具设置
#=============================================================================

function(ut_setup_test_stubs)
    if(NOT EXISTS "${AUTOTEST_ROOT}/3rdparty/testutils")
        message(WARNING "UT: testutils not found, stub functionality will be limited")
        return()
    endif()

    message(STATUS "UT: Setting up test stubs...")

    # 查找 stub 源文件
    file(GLOB STUB_SRC_FILES
        "${AUTOTEST_ROOT}/3rdparty/testutils/cpp-stub/*.h"
        "${AUTOTEST_ROOT}/3rdparty/testutils/cpp-stub/*.hpp"
        "${AUTOTEST_ROOT}/3rdparty/testutils/stub-ext/*.h"
        "${AUTOTEST_ROOT}/3rdparty/testutils/stub-ext/*.cpp"
    )

    if(STUB_SRC_FILES)
        set(CPP_STUB_SRC ${STUB_SRC_FILES} CACHE INTERNAL "Stub source files")
        message(STATUS "UT: Found stub files: ${STUB_SRC_FILES}")

        # 包含目录
        include_directories(
            "${AUTOTEST_ROOT}/3rdparty/testutils/cpp-stub"
            "${AUTOTEST_ROOT}/3rdparty/testutils/stub-ext"
            "${AUTOTEST_ROOT}/3rdparty/testutils"
        )
        message(STATUS "UT: Stub tools configured")
    else()
        message(WARNING "UT: No stub source files found")
    endif()
endfunction()

#=============================================================================
# 覆盖率设置
#=============================================================================

function(ut_setup_coverage)
    message(STATUS "UT: Setting up code coverage...")

    # 基础测试标志
    set(TEST_FLAGS "-fno-inline;-fno-access-control;-O0")

    # 覆盖率标志
    list(APPEND TEST_FLAGS "-fprofile-arcs;-ftest-coverage;-lgcov")

    # ASAN 标志
    if(ENABLE_ASAN AND CMAKE_BUILD_TYPE STREQUAL "Debug")
        list(APPEND TEST_FLAGS "-fsanitize=address,undefined;-fno-omit-frame-pointer")
        message(STATUS "UT: ASAN enabled")
    endif()

    set(UT_TEST_CXX_FLAGS ${TEST_FLAGS} CACHE INTERNAL "Test flags")

    # 设置全局标志
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-inline -fno-access-control -O0 -fprofile-arcs -ftest-coverage" PARENT_SCOPE)

    if(ENABLE_ASAN AND CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address,undefined -fno-omit-frame-pointer" PARENT_SCOPE)
    endif()

    message(STATUS "UT: Coverage configured")
endfunction()

#=============================================================================
# 创建测试可执行文件
#=============================================================================

function(ut_create_test_executable test_name)
    set(options "")
    set(oneValueArgs "")
    set(multiValueArgs SOURCES HEADERS DEPENDENCIES LINK_LIBRARIES)
    cmake_parse_arguments(TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    message(STATUS "UT: Creating test executable: ${test_name}")

    # 收集源文件
    set(ALL_SOURCES ${TEST_SOURCES})

    # 添加头文件（如果提供）
    if(TEST_HEADERS)
        list(APPEND ALL_SOURCES ${TEST_HEADERS})
    endif()

    # 添加 stub 源文件
    if(CPP_STUB_SRC)
        list(APPEND ALL_SOURCES ${CPP_STUB_SRC})
    endif()

    # 创建可执行文件
    add_executable(${test_name} ${ALL_SOURCES})

    # 应用测试标志
    if(UT_TEST_CXX_FLAGS)
        target_compile_options(${test_name} PRIVATE ${UT_TEST_CXX_FLAGS})
    endif()

    # 链接库
    if(TEST_LINK_LIBRARIES)
        target_link_libraries(${test_name} PRIVATE ${TEST_LINK_LIBRARIES})
    endif()

    # ASAN 库
    if(ENABLE_ASAN AND CMAKE_BUILD_TYPE STREQUAL "Debug")
        target_link_libraries(${test_name} PRIVATE
            -fsanitize=address,undefined
            -fprofile-arcs
            -ftest-coverage
            -lgcov
        )
    else()
        target_link_libraries(${test_name} PRIVATE
            -fprofile-arcs
            -ftest-coverage
            -lgcov
        )
    endif()

    # 添加测试
    add_test(NAME ${test_name} COMMAND ${test_name})

    message(STATUS "UT: Test executable created: ${test_name}")
endfunction()

#=============================================================================
# 创建库测试
#=============================================================================

function(ut_create_library_test lib_name source_dir)
    set(test_name "test-${lib_name}")

    message(STATUS "UT: Creating library test: ${test_name}")

    # 查找测试文件
    file(GLOB_RECURSE TEST_SOURCES "*.cpp" "*.h")

    # 查找库源文件
    file(GLOB_RECURSE LIB_SOURCES
        "${source_dir}/*.cpp"
        "${source_dir}/*.h"
    )

    # 创建测试
    ut_create_test_executable(${test_name}
        SOURCES ${TEST_SOURCES} ${LIB_SOURCES}
    )

    # 包含源目录
    target_include_directories(${test_name} PRIVATE "${source_dir}")

    message(STATUS "UT: Library test created: ${test_name}")
endfunction()

#=============================================================================
# 创建插件测试
#=============================================================================

function(ut_create_plugin_test plugin_name plugin_path)
    set(test_name "test-${plugin_name}")

    message(STATUS "UT: Creating plugin test: ${test_name}")

    # 查找测试文件
    file(GLOB_RECURSE TEST_SOURCES "*.cpp" "*.h")

    # 查找插件源文件
    file(GLOB_RECURSE PLUGIN_SOURCES
        "${plugin_path}/*.cpp"
        "${plugin_path}/*.h"
    )

    # 创建测试
    ut_create_test_executable(${test_name}
        SOURCES ${TEST_SOURCES} ${PLUGIN_SOURCES}
    )

    # 包含插件路径
    target_include_directories(${test_name} PRIVATE "${plugin_path}")

    message(STATUS "UT: Plugin test created: ${test_name}")
endfunction()

#=============================================================================
# 创建服务测试
#=============================================================================

function(ut_create_service_test service_name service_path)
    set(test_name "test-${service_name}")

    message(STATUS "UT: Creating service test: ${test_name}")

    # 查找测试文件
    file(GLOB_RECURSE TEST_SOURCES "*.cpp" "*.h")

    # 查找服务源文件（排除 main.cpp）
    file(GLOB_RECURSE SERVICE_SOURCES
        "${service_path}/*.cpp"
        "${service_path}/*.h"
    )

    # 排除 main.cpp
    list(FILTER SERVICE_SOURCES EXCLUDE REGEX ".*/main\\.cpp$")

    # 创建测试
    ut_create_test_executable(${test_name}
        SOURCES ${TEST_SOURCES} ${SERVICE_SOURCES}
    )

    # 包含服务路径
    target_include_directories(${test_name} PRIVATE "${service_path}")

    message(STATUS "UT: Service test created: ${test_name}")
endfunction()

message(STATUS "UT: Unit test utilities loaded")
CMAKEOF

    print_success "生成 cmake/UnitTestUtils.cmake"
    echo ""
}

################################################################################
# 生成测试主 CMakeLists.txt
################################################################################

generate_main_cmake() {
    print_step 5 "生成测试主 CMakeLists.txt..."

    cat > "${AUTOTEST_ROOT}/CMakeLists.txt" << CMAKEEOF
# CMakeLists.txt for AutoTests
cmake_minimum_required(VERSION 3.10)

project(autotests)

    # 设置 C++ 标准
    set(CMAKE_CXX_STANDARD ${CPP_STANDARD})
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    
    # 设置 autotests 根目录
    set(AUTOTEST_ROOT ${CMAKE_CURRENT_SOURCE_DIR})
    
    # 包含测试工具
    list(APPEND CMAKE_MODULE_PATH "\${CMAKE_CURRENT_SOURCE_DIR}/../cmake")
    include(UnitTestUtils)
    
    # 选项
    option(USE_QT "Enable Qt support" $(echo "$USE_QT" | tr '[:upper:]' '[:lower:]'))
    option(ENABLE_COVERAGE "Enable code coverage" ON)
    option(ENABLE_ASAN "Enable AddressSanitizer" ON)
    
    # 初始化测试环境
    ut_init_test_environment()
    
    # 启用测试
    enable_testing()
    
    message(STATUS "=====================================")
    message(STATUS "AutoTests Configuration:")
    message(STATUS "  Use Qt:        \${USE_QT}")
    message(STATUS "Coverage:      \${ENABLE_COVERAGE}")
    message(STATUS "  ASAN:          \${ENABLE_ASAN}")
    message(STATUS "=====================================")
    
    # 根据项目结构添加子目录
CMAKEEOF

    # 根据检测到的子目录添加
    if [ -n "$SUBDIRS" ]; then
        for dir in $SUBDIRS; do
            echo "add_subdirectory_if_exists(${dir})" >> "${AUTOTEST_ROOT}/CMakeLists.txt"
        done
    fi
    
    # 如果有独立源文件，添加 libs 目录
    if [ "$STANDALONE_SRC" -gt 0 ]; then
        echo "add_subdirectory_if_exists(libs)" >> "${AUTOTEST_ROOT}/CMakeLists.txt"
    fi
    
    print_success "生成 autotests/CMakeLists.txt"
    echo ""
}

################################################################################
# 生成测试运行脚本
################################################################################

generate_test_runner_script() {
    print_step 6 "生成测试运行脚本..."

    cat > "${AUTOTEST_ROOT}/run-ut.sh" << 'SHELLEOF'
#!/bin/bash

# AutoTest Runner Script
# 功能：编译测试 + 运行测试 + 生成覆盖率报告

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --from-step <N>    从步骤 N 开始执行 (1-5)"
    echo "  -h, --help         显示帮助信息"
    echo ""
    echo "步骤:"
    echo "  1. 准备构建环境"
    echo "  2. 配置 CMake"
    echo "  3. 编译测试"
    echo "  4. 运行测试"
    echo "  5. 生成覆盖率报告"
    echo ""
    echo "示例:"
    echo "  $0                  # 运行所有步骤"
    echo "  $0 --from-step 4    # 从步骤 4 开始（跳过编译）"
}

# 解析参数
START_STEP=1
while [[ $# -gt 0 ]]; do
    case $1 in
        --from-step)
            START_STEP="$2"
            if ! [[ "$START_STEP" =~ ^[1-5]$ ]]; then
                print_error "无效的步骤号: $START_STEP，必须是 1-5"
                exit 1
            fi
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "未知选项: $1"
            show_usage
            exit 1
            ;;
    esac
done

# 获取目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build-autotests"
REPORT_DIR="${BUILD_DIR}/test-reports"

echo "========================================"
echo "  AutoTest Runner"
echo "========================================"
echo "项目根目录: $PROJECT_ROOT"
echo "构建目录: $BUILD_DIR"
echo "报告目录: $REPORT_DIR"
if [ "$START_STEP" -gt 1 ]; then
    echo -e "${BLUE}[INFO]${NC} 从步骤 $START_STEP 开始"
fi
echo ""

# 初始化变量
TEST_PASSED=false

# 从技能资源复制 stub-ext 工具
copy_stub_from_resources() {
    print_step 0 "检查并复制 stub-ext 工具..."

    local STUBUTILS_DIR="${SCRIPT_DIR}/3rdparty/testutils"
    local SKILL_RESOURCE_DIR="${SCRIPT_DIR}/../resources/testutils"

    # 检查是否已经存在且完整
    if [ -d "$STUBUTILS_DIR/cpp-stub" ] && [ -d "$STUBUTILS_DIR/stub-ext" ]; then
        local stub_files=$(find "$STUBUTILS_DIR" \( -name "*.h" -o -name "*.cpp" \) | wc -l)
        if [ "$stub_files" -ge 6 ]; then
            print_success "stub-ext 工具已存在"
            return 0
        fi
    fi

    # 从技能资源目录复制
    if [ -d "$SKILL_RESOURCE_DIR" ]; then
        cp -r "$SKILL_RESOURCE_DIR" "${SCRIPT_DIR}/3rdparty/"
        local copied_files=$(find "$STUBUTILS_DIR" \( -name "*.h" -o -name "*.cpp" \) | wc -l)
        print_success "stub-ext 工具复制完成（${copied_files} 个文件）"
        return 0
    fi

    print_error "无法找到技能资源目录，请手动放置 stub-ext"
    return 1
}

# 从技能资源复制 stub-ext
copy_stub_from_resources || {
    print_error "stub-ext 工具不可用，但继续生成框架"
}

# Step 1: 准备构建环境
if [ $START_STEP -le 1 ]; then
    print_step 1 "准备构建环境..."
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    mkdir -p "$BUILD_DIR"
    mkdir -p "$REPORT_DIR"
    print_success "构建环境准备完成"
fi

# Step 2: 配置 CMake
if [ $START_STEP -le 2 ]; then
    print_step 2 "配置 CMake..."
    cd "$BUILD_DIR"
    cmake "$SCRIPT_DIR" \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    print_success "CMake 配置完成"
fi

# Step 3: 编译测试
if [ $START_STEP -le 3 ]; then
    print_step 3 "编译测试..."
    cd "$BUILD_DIR"
    cmake --build . -j $(nproc)
    print_success "编译完成"
fi

# Step 4: 运行测试
if [ $START_STEP -le 4 ]; then
    print_step 4 "运行测试..."

    # 确保报告目录存在
    mkdir -p "$REPORT_DIR"

    # 运行测试并保存结果
    cd "$BUILD_DIR"
    if ctest --output-on-failure > "$REPORT_DIR/test_output.log" 2>&1; then
        print_success "所有测试通过"
        TEST_PASSED=true
    else
        print_error "部分测试失败"
        TEST_PASSED=false
    fi
fi

# Step 5: 生成覆盖率报告
if [ $START_STEP -le 5 ]; then
    print_step 5 "生成覆盖率报告..."

    # 临时禁用错误退出
    set +e

    if command -v lcov &> /dev/null; then
        cd "$BUILD_DIR"
        mkdir -p coverage

        # 收集覆盖率数据
        lcov --directory . --capture --output-file coverage/total.info > "$REPORT_DIR/coverage_output.log" 2>&1 || true

        # 过滤覆盖率数据
        if [ -f "coverage/total.info" ]; then
            lcov --extract "coverage/total.info" "*/src/*" --output-file coverage/filtered.info >> "$REPORT_DIR/coverage_output.log" 2>&1 || true
            lcov --remove "coverage/filtered.info" "*/test*" "*/autotests/*" --output-file coverage/filtered.info >> "$REPORT_DIR/coverage_output.log" 2>&1 || true
        fi

        # 生成 HTML 报告
        if [ -f "coverage/filtered.info" ] && [ -s "coverage/filtered.info" ]; then
            genhtml --output-directory coverage/html --title "Coverage Report" coverage/filtered.info >> "$REPORT_DIR/coverage_output.log" 2>&1
            if [ $? -eq 0 ]; then
                print_success "覆盖率报告生成完成"
                print_success "📊 覆盖率报告: $BUILD_DIR/coverage/html/index.html"
            else
                print_error "HTML 覆盖率报告生成失败"
            fi
        else
            print_error "没有覆盖率数据"
        fi
    else
        print_error "lcov 未安装，跳过覆盖率生成"
    fi

    # 重新启用错误退出
    set -e
fi

# 最终结果
echo ""
echo "========================================"
if [ "$TEST_PASSED" = true ]; then
    print_success "🎉 测试执行完成！"
else
    print_error "❌ 测试有失败，请查看测试报告"
fi
echo ""
echo "生成的报告:"
echo "  测试输出: $REPORT_DIR/test_output.log"
echo "  覆盖率输出: $REPORT_DIR/coverage_output.log"
if [ -d "$BUILD_DIR/coverage/html" ]; then
    echo "  覆盖率报告: $BUILD_DIR/coverage/html/index.html"
fi
echo ""
echo "快速命令:"
echo "  重新运行测试: cd $BUILD_DIR && ctest"
echo "  查看可用目标: cd $BUILD_DIR && make help"
echo "========================================"

# 如果测试失败，返回非零退出码
if [ "$TEST_PASSED" != true ]; then
    exit 1
fi
SHELLEOF

    chmod +x "${AUTOTEST_ROOT}/run-ut.sh"
    print_success "生成 autotests/run-ut.sh"
    echo ""
}

################################################################################
# 生成文档
################################################################################

generate_documentation() {
    print_step 7 "生成文档..."

    cat > "${AUTOTEST_ROOT}/README.md" << 'MDEOF'
# AutoTest Framework

## 快速开始

### 1. 编写测试

```cpp
#include <gtest/gtest.h>
#include "stubext.h"
#include "myclass.h"

class UT_MyClass : public testing::Test {
public:
    void SetUp() override {
        obj = new MyClass();
    }

    void TearDown() override {
        stub.clear();
        delete obj;
    }

    stub_ext::StubExt stub;
    MyClass *obj = nullptr;
};

TEST_F(UT_MyClass, Calculate_ValidInput_ReturnsCorrectResult) {
    // Arrange
    int a = 10, b = 20;
    int expected = 30;

    // Act
    int result = obj->calculate(a, b);

    // Assert
    EXPECT_EQ(result, expected);
}
```

### 2. 运行测试

```bash
cd autotests
./run-ut.sh
```

### 3. 从指定步骤开始

```bash
# 跳过编译，直接运行测试
./run-ut.sh --from-step 4

# 只生成覆盖率报告
./run-ut.sh --from-step 5
```

## 测试命名规范

- **测试类**: `UT_<ClassName>`
- **测试用例**: `<Feature>_<Scenario>_<ExpectedResult>`

示例：
```cpp
TEST_F(UT_MyClass, Calculate_ValidInput_ReturnsCorrectResult)
TEST_F(UT_MyClass, Calculate_EmptyInput_ThrowsException)
```

## Stub 使用示例

### 验证函数调用

```cpp
TEST_F(UT_MyClass, ExternalCall_VerifyCalled) {
    bool called = false;
    stub.set_lamda(&ExternalClass::method, [&called](void**) {
        called = true;
    });

    obj->callExternal();

    EXPECT_TRUE(called);
}
```

### 控制返回值

```cpp
TEST_F(UT_MyClass, GetValue_Stubbed_ReturnsFixedValue) {
    stub.set_lamda(&ExternalClass::getValue, [](void** ret) {
        *(int*)ret = 42;
    });

    EXPECT_EQ(obj->getExternalValue(), 42);
}
```

## 最佳实践

1. **AAA 模式**: Arrange-Act-Assert
2. **测试独立性**: 每个测试独立运行
3. **Stub 使用**: 隔离外部依赖
4. **覆盖率**: 目标 > 80%

## 手动构建

如需手动控制构建过程：

```bash
# 创建构建目录
mkdir -p ../build-autotests
cd ../build-autotests

# 配置 CMake
cmake ../autotests -DCMAKE_BUILD_TYPE=Debug

# 编译
cmake --build . -j $(nproc)

# 运行测试
ctest --output-on-failure

# 生成覆盖率
lcov --directory . --capture --output-file coverage.info
genhtml coverage.info --output-directory coverage-html
```
MDEOF

    print_success "生成 autotests/README.md"
    echo ""
}

################################################################################
# 总结
################################################################################

print_summary() {
    echo ""
    echo "========================================"
    print_success "测试框架生成完成！"
    echo "========================================"
    echo ""
    echo "生成的文件："
    echo "  📁 ${AUTOTEST_ROOT}/"
    echo "  ├─ 3rdparty/testutils/     # Stub Mock 工具"
    echo "  ├─ CMakeLists.txt         # 测试构建配置"
    echo "  ├─ run-ut.sh             # 测试运行脚本"
    echo "  ├─ libs/                 # 库测试"
    echo "  ├─ plugins/              # 插件测试"
    echo "  ├─ services/             # 服务测试"
    echo "  └─ README.md            # 使用文档"
    echo ""
    echo "  📁 ${PROJECT_ROOT}/cmake/"
    echo "  └─ UnitTestUtils.cmake     # CMake 测试工具"
    echo ""
    echo "下一步："
    echo "  1. cd ${AUTOTEST_ROOT}"
    echo "  2. 根据需要编写测试用例（参考 README.md）"
    echo "  3. ./run-ut.sh 运行测试"
    echo ""
    echo "文档："
    echo "  📖 ${AUTOTEST_ROOT}/README.md"
    echo ""
}

################################################################################
# 主函数
################################################################################

main() {
    print_header

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                echo "AutoTest Framework Generator v${VERSION}"
                exit 0
                ;;
            -p|--project-dir)
                PROJECT_ROOT="$(cd "$2" && pwd)"
                shift 2
                ;;
            -s|--script-dir)
                SCRIPT_DIR="$(cd "$2" && pwd)"
                shift 2
                ;;
            *)
                print_error "未知选项: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # 设置默认值
    PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
    AUTOTEST_ROOT="${PROJECT_ROOT}/autotests"

    # 检测项目结构
    detect_project_structure

    # 创建目录结构
    create_directory_structure

    # 复制 stub 源文件
    copy_stub_ext

    # 生成 CMake 工具
    generate_cmake_test_utils

    # 生成测试主 CMakeLists.txt
    generate_main_cmake

    # 生成测试运行脚本
    generate_test_runner_script

    # 生成文档
    generate_documentation


    # 总结
    print_summary

    exit 0
}

# 运行主函数
main "$@"
