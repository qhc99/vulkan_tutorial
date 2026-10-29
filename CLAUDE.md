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
- 已完成：Introduction、Overview、Development Environment、Base Code（`triangle\main.cpp` 已按本章写好并验证：GLFW 窗口 + 主循环）
- 下一章：Drawing a triangle → Setup → Instance
  https://docs.vulkan.org/tutorial/latest/03_Drawing_a_triangle/00_Setup/01_Instance.html

## 主线之后还要学的进阶篇（按此顺序）
1. Synchronization：https://docs.vulkan.org/tutorial/latest/Synchronization/introduction.html
2. Advanced Vulkan Compute：https://docs.vulkan.org/tutorial/latest/Advanced_Vulkan_Compute/introduction.html
3. Advanced glTF：https://docs.vulkan.org/tutorial/latest/Advanced_glTF/introduction.html

## Git 规则
- 每次测试成功（MSBuild 构建通过 + 程序运行验证符合本章预期）后，自动 `git add -A` 并 commit，无需再问。
- 提交信息格式：`<章节名>: <做了什么>`，例如 `Instance: create vk::raii::Instance with GLFW extensions`。
- 构建或运行失败时不提交；只 commit，不 push。

## 本地构建环境
- 工具链：VS 2026 Community（MSBuild 18，toolset v145，MSVC 14.51），Vulkan SDK 1.4.363（`$env:VULKAN_SDK`），vcpkg 在 `C:\Users\quinn\workspace\vcpkg`（manifest 模式，`vcpkg.json`）。
- 用 MSBuild（vcxproj + `VulkanTutorial.slnx`），不用 CMake，也不用自定义构建脚本。
  - VS 2026 打开 `VulkanTutorial.slnx` → F5；或 VS Code `Ctrl+Shift+B` / F5（`.vscode/tasks.json` 直接调 MSBuild.exe）。
  - 命令行：VS Code 终端默认是 "Developer PowerShell for VS 2026"（`.vscode/settings.json`），`msbuild`、`cl` 都在 PATH：
    `msbuild triangle\triangle.vcxproj [-p:Configuration=Release]`（默认 Debug|x64）
  - 输出：`out\<project>\<Config>\`，运行时工作目录必须是输出目录（教程用相对路径读 shaders/models/textures）。
  - 用户系统 ExecutionPolicy 是默认 Restricted，不能直接跑 .ps1；我自己调用脚本要用 `powershell -NoProfile -ExecutionPolicy Bypass -File ...`。
  - 系统开着 Smart App Control，未签名的新 exe 可能被拦（"An Application Control policy has blocked this file"）。
- 公共设置在 `build\Common.props`，与官方 `attachments/CMakeLists.txt` 对齐：C++20，`VULKAN_HPP_NO_STRUCT_CONSTRUCTORS=1`、`VULKAN_HPP_DISPATCH_LOADER_DYNAMIC=1`、`VULKAN_HPP_HANDLE_ERROR_OUT_OF_DATE_AS_SUCCESS`，链接 `vulkan-1.lib`。
- 依赖（vcpkg, x64-windows）：glfw3、glm、stb、tinyobjloader、tinygltf、ktx。
- 两个项目：
  - `triangle\main.cpp`：跟着教程逐章累积的代码。
  - 编辑器用 clangd，配置在 `.clangd`（与 `Common.props` 保持同步；改 define/依赖时两处都要改）。
  - `reference\main.cpp`：官方每章附带的完整代码，用于对照/排错。下载：章节页末尾的 C++ code 链接，
    `curl.exe -L https://docs.vulkan.org/tutorial/latest/_attachments/<xx>.cpp -o reference\main.cpp`
- TODO（到 Shader modules 章节时）：在 `Common.props` 加 slangc 编译步骤，对齐官方命令
  `slangc shader.slang -target spirv -profile spirv_1_4 -emit-spirv-directly -fvk-use-entrypoint-name -entry vertMain -entry fragMain -o slang.spv`，输出到 `$(OutDir)shaders\`。
- 新的大章节（如 compute、glTF）需要独立程序时，复制 `triangle\` 为新项目并加进 `VulkanTutorial.slnx`。
