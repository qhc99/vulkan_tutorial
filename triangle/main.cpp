// Environment smoke test: Vulkan-Hpp RAII + GLFW + GLM all compile, link and run.
// Replace with the tutorial's Base Code when starting that chapter.
#include <vulkan/vulkan_raii.hpp>
#define GLFW_INCLUDE_VULKAN
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>

#include <cstdlib>
#include <iostream>

int main()
{
    vk::raii::Context context;
    uint32_t v = context.enumerateInstanceVersion();
    std::cout << "Vulkan instance version: " << VK_API_VERSION_MAJOR(v) << '.' << VK_API_VERSION_MINOR(v) << '.'
              << VK_API_VERSION_PATCH(v) << '\n';
    std::cout << "Header version: " << VK_HEADER_VERSION << '\n';

    for (auto const& layer : context.enumerateInstanceLayerProperties())
        std::cout << "  layer: " << layer.layerName << '\n';

    if (!glfwInit())
        return EXIT_FAILURE;
    std::cout << "GLFW " << glfwGetVersionString() << ", Vulkan supported: " << (glfwVulkanSupported() ? "yes" : "no")
              << '\n';
    glfwTerminate();

    glm::vec3 a{1, 2, 3};
    std::cout << "glm dot: " << glm::dot(a, a) << '\n';
    return EXIT_SUCCESS;
}
