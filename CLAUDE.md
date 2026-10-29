# Vulkan Tutorial 学习工作区

> 分工：章节讲解平时在浏览器 Claude 里做，本地会话主要负责构建、运行、调试代码。
> 以下【解读要求】是浏览器端用的 prompt 存档；只有我在本地明确要求讲解时才按它执行。

我在学 Khronos Vulkan Tutorial（https://docs.vulkan.org/tutorial/latest/00_Introduction.html），请继续逐章帮我解读。

## 解读要求
- 每章详细解读/压缩所有知识点：简洁但不遗漏；我有不懂的会再追问，你再补充。
- 用中文；结构清晰，可用小标题、表格、列表；代码/API 名保留英文原样。
- 每章末尾加"⚠️ 原文的坑"：指出原文过时、笔误、前后矛盾或与新版本（Vulkan 1.4 / Vulkan-Hpp RAII / dynamic rendering）不符的地方。
- 结尾一句话预告下一章。
- 读取方式：用本地脚本读正文（不要用 WebFetch，它只给摘要）：
  - 我说"下一章"时：`.\tools\tut.ps1 -Next`（自动按侧边栏顺序跳到下一页，并更新 `.tutorial-current`）
  - 指定页面：`.\tools\tut.ps1 <相对路径或完整 URL>`；重读当前页：`.\tools\tut.ps1`；目录：`.\tools\tut.ps1 -Nav`
  - 输出头部的 `<!-- next: ... -->` 就是下一章路径，可用于结尾预告。
  - 讲完一章后更新下面的【进度】。

## 我的背景
- 程序员，C++（RAII、C++20）、实时 3D 图形基础都已具备，不需要讲前置知识。

## 进度
- 已完成：Introduction、Overview、Development Environment
- 下一章：Drawing a triangle → Setup → Base Code
  https://docs.vulkan.org/tutorial/latest/03_Drawing_a_triangle/00_Setup/00_Base_code.html

## 主线之后还要学的进阶篇（按此顺序）
1. Synchronization：https://docs.vulkan.org/tutorial/latest/Synchronization/introduction.html
2. Advanced Vulkan Compute：https://docs.vulkan.org/tutorial/latest/Advanced_Vulkan_Compute/introduction.html
3. Advanced glTF：https://docs.vulkan.org/tutorial/latest/Advanced_glTF/introduction.html

## 本地构建环境
- 工具链：VS 2026 Community（MSBuild 18，toolset v145，MSVC 14.51），Vulkan SDK 1.4.363（`$env:VULKAN_SDK`），vcpkg 在 `C:\Users\quinn\workspace\vcpkg`（manifest 模式，`vcpkg.json`）。
- 用 MSBuild 而不是 CMake；不需要 Developer Prompt，MSBuild 自己配好 cl/link。
  - 构建：`.\tools\build.ps1 [-Config Debug|Release] [-Run] [-Rebuild] [-Project triangle]`
  - 输出：`out\<project>\<Config>\`，运行时工作目录就是输出目录（教程用相对路径读 shaders/models/textures）。
  - 临时要直接用 cl：`& "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\Launch-VsDevShell.ps1" -Arch amd64 -SkipAutomaticLocation`
- 公共设置在 `build\Common.props`，与官方 `attachments/CMakeLists.txt` 对齐：C++20，`VULKAN_HPP_NO_STRUCT_CONSTRUCTORS=1`、`VULKAN_HPP_DISPATCH_LOADER_DYNAMIC=1`、`VULKAN_HPP_HANDLE_ERROR_OUT_OF_DATE_AS_SUCCESS`，链接 `vulkan-1.lib`。
- 依赖（vcpkg, x64-windows）：glfw3、glm、stb、tinyobjloader、tinygltf、ktx。
- 两个项目：
  - `triangle\main.cpp`：我自己跟着教程写的代码（目前是环境冒烟测试，开始 Base Code 时替换）。
  - `reference\main.cpp`：官方每章附带的完整代码，用 `.\tools\ref.ps1 <章节URL|路径|xx.cpp>` 下载（会覆盖），然后 `.\tools\build.ps1 -Project reference -Run`。用于对照/排错。
- TODO（到 Shader modules 章节时）：在 `Common.props` 加 slangc 编译步骤，对齐官方命令
  `slangc shader.slang -target spirv -profile spirv_1_4 -emit-spirv-directly -fvk-use-entrypoint-name -entry vertMain -entry fragMain -o slang.spv`，输出到 `$(OutDir)shaders\`。
- 新的大章节（如 compute、glTF）需要独立程序时，复制 `triangle\` 为新项目并加进 `VulkanTutorial.slnx`。
