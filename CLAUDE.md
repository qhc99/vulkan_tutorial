# Vulkan Tutorial 学习工作区

分工：章节讲解在浏览器 Claude 里做；本地会话负责把章节代码写进工程、构建、运行、调试。
阅读和实现进度不同步：阅读通常领先，本地按"实现进度"逐章补代码。

## 进度
### 阅读进度（浏览器）
- 已读：Introduction、Overview、Development Environment、Base Code、Instance、Validation Layers、Physical devices and queue families
- 下一章：Drawing a triangle → Setup → Logical device and queues
  https://docs.vulkan.org/tutorial/latest/03_Drawing_a_triangle/00_Setup/04_Logical_device_and_queues.html

### 实现进度（本地 `triangle\main.cpp`）
- 已实现并验证：Base Code（GLFW 窗口 + 主循环）、Instance（`vk::raii::Instance`，API 1.4，GLFW 扩展检查）、
  Validation Layers（`VK_LAYER_KHRONOS_validation` + `VK_EXT_debug_utils` messenger，仅 Debug 启用）、
  Physical devices（`isDeviceSuitable`：1.3 + graphics 队列 + swapchain 扩展 + shaderDrawParameters/dynamicRendering/extendedDynamicState；选中 RTX 4070，系统另有 Intel UHD）
- 下一章：Drawing a triangle → Setup → Logical device and queues
  https://docs.vulkan.org/tutorial/latest/03_Drawing_a_triangle/00_Setup/04_Logical_device_and_queues.html
- 验证 debug 回调是否通：临时调用 `instance.submitDebugUtilsMessageEXT(...)` 手动发一条消息，看 stderr；测完删掉。
- 运行验证方法：`Start-Process -PassThru` 启动、`$null = $p.Handle`（PS 5.1 否则拿不到 ExitCode）、等 3 秒、`CloseMainWindow()`，退出码应为 0。
- 本地说"下一章"指实现进度的下一章：读该章正文（`powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\tut.ps1 <章节路径>`），
  把代码加进 `triangle\main.cpp`，构建运行验证，按 Git 规则提交，然后更新这里。实现不能超过阅读进度。

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
  - 我在本地会话里构建用完整路径：`& "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\amd64\MSBuild.exe" ...`
  - 输出：`out\<project>\<Config>\`，运行时工作目录必须是输出目录（教程用相对路径读 shaders/models/textures）。
  - 用户系统 ExecutionPolicy 是默认 Restricted，不能直接跑 .ps1；我自己调用脚本要用 `powershell -NoProfile -ExecutionPolicy Bypass -File ...`。
  - 系统开着 Smart App Control，未签名的新 exe 可能被拦（"An Application Control policy has blocked this file"），Debug 也会，且随机（同一份代码重编译也可能一直被拦）。
    被拦 ≠ 代码有问题；被拦时无法运行验证，不提交，告诉用户。
- 公共设置在 `build\Common.props`，与官方 `attachments/CMakeLists.txt` 对齐：C++20，`VULKAN_HPP_NO_STRUCT_CONSTRUCTORS=1`、`VULKAN_HPP_DISPATCH_LOADER_DYNAMIC=1`、`VULKAN_HPP_HANDLE_ERROR_OUT_OF_DATE_AS_SUCCESS`，链接 `vulkan-1.lib`。
- 依赖（vcpkg, x64-windows）：glfw3、glm、stb、tinyobjloader、tinygltf、ktx。
- 编辑器用 clangd，配置在 `.clangd`（与 `Common.props` 保持同步；改 define/依赖时两处都要改）。
- 两个项目：
  - `triangle\main.cpp`：跟着教程逐章累积的代码。
  - `reference\main.cpp`：官方每章附带的完整代码，用于对照/排错。下载：章节页末尾的 C++ code 链接，
    `curl.exe -L https://docs.vulkan.org/tutorial/latest/_attachments/<xx>.cpp -o reference\main.cpp`
- TODO（到 Shader modules 章节时）：在 `Common.props` 加 slangc 编译步骤，对齐官方命令
  `slangc shader.slang -target spirv -profile spirv_1_4 -emit-spirv-directly -fvk-use-entrypoint-name -entry vertMain -entry fragMain -o slang.spv`，输出到 `$(OutDir)shaders\`。
- 新的大章节（如 compute、glTF）需要独立程序时，复制 `triangle\` 为新项目并加进 `VulkanTutorial.slnx`。

## 浏览器端 prompt 存档
（浏览器 Claude 用；只有我在本地明确要求讲解时才参照执行，此时把"浏览器工具读取"换成上面的 `tools\tut.ps1`。进度以上方【进度】为准，下面不再维护。）

> 我在学 Khronos Vulkan Tutorial（https://docs.vulkan.org/tutorial/latest/00_Introduction.html），请继续逐章帮我解读。
>
> 【解读要求】
> - 每章详细解读/压缩所有知识点：简洁但不遗漏；我有不懂的会再追问，你再补充。
> - 代码部分不要过度压缩：关键代码给完整片段 + 必要的行内注释，讲清每个参数/字段的含义；章末给出本章完整的关键函数代码。
> - 用中文；结构清晰，可用小标题、表格、列表；代码/API 名保留英文原样。
> - 每章末尾加"⚠️ 原文的坑"：指出原文过时、笔误、前后矛盾、代码错误，或与新版本（Vulkan 1.4 / Vulkan-Hpp RAII / dynamic rendering）不符之处，并给出修正写法。
> - 结尾一句话预告下一章。
> - 读取方式：用浏览器工具读当前标签页正文；我说"下一章"时你自己在当前标签页跳到下一章并解读。
>
> 【我的背景】
> - 程序员，C++（RAII、C++20）、实时 3D 图形基础都已具备，不需要讲前置知识。
>
> 【进度】
> - 已完成：Introduction、Overview、Development Environment、Base Code、Instance
> - 下一章：Drawing a triangle → Setup → Validation Layers
>   https://docs.vulkan.org/tutorial/latest/03_Drawing_a_triangle/00_Setup/02_Validation_layers.html
>
> 【主线之后还要学的进阶篇（按此顺序）】
> 1. Synchronization：https://docs.vulkan.org/tutorial/latest/Synchronization/introduction.html
> 2. Advanced Vulkan Compute：https://docs.vulkan.org/tutorial/latest/Advanced_Vulkan_Compute/introduction.html
> 3. Advanced glTF：https://docs.vulkan.org/tutorial/latest/Advanced_glTF/introduction.html
