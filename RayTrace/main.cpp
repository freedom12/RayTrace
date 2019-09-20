#include <iostream>
#include <GL/gl3w.h>
#include <GLFW/glfw3.h>

#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"

#include "material/Material.h"
#include "renderer/TestRenderer.h"
#include "renderer/GLSLTestRenderer.h"

GLFWwindow *window;
Renderer *renderer;
int width = 800, height = 400;

static int init();
static void update();
static void clean();

static void glfw_error_callback(const int error, const char *description)
{
	std::cout << "Glfw Error " << error << ": " << description << std::endl;
}

static void glfw_framebuffer_size_callback(GLFWwindow *window, const int width, const int height)
{
	renderer->updateSize(width, height);
	update();
}

int main(int, char **)
{
	const auto code = init();
	if (code != 0)
	{
		return code;
	}

	while (!glfwWindowShouldClose(window))
	{
		update();
	}

	clean();

	return 0;
}


static int init()
{
	glfwSetErrorCallback(glfw_error_callback);
	if (!glfwInit())
	{
		std::cout << "Failed to initialize GLFW!" << std::endl;
		return 1;
	}

	const auto glsl_version = "#version 460";
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 6);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE); // 3.2+ only
	glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE); // 3.0+ only


	window = glfwCreateWindow(width, height, "Ray Trace", nullptr, nullptr);
	if (!window)
	{
		std::cout << "Failed to initialize window!" << std::endl;
		glfwTerminate();
		return 1;
	}
	glfwMakeContextCurrent(window);
	glfwSwapInterval(1);

	glfwSetFramebufferSizeCallback(window, glfw_framebuffer_size_callback);


	if (gl3wInit())
	{
		std::cout << "Failed to initialize OpenGL!" << std::endl;
		glfwTerminate();
		return 1;
	}


	IMGUI_CHECKVERSION();
	ImGui::CreateContext();
	auto &io = ImGui::GetIO();
	(void)io;
	//io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;     // Enable Keyboard Controls
	//io.ConfigFlags |= ImGuiConfigFlags_NavEnableGamepad;      // Enable Gamepad Controls

	// Setup Dear ImGui style
	ImGui::StyleColorsDark();
	//ImGui::StyleColorsClassic();

	// Setup Platform/Renderer bindings
	ImGui_ImplGlfw_InitForOpenGL(window, true);
	ImGui_ImplOpenGL3_Init(glsl_version);


	//renderer = new GLSLTestRenderer(width, height);
	renderer = new TestRenderer(width, height);
	return 0;
}

static void update()
{
	// Poll and handle events (inputs, window resize, etc.)
	// You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
	// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application.
	// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application.
	// Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
	glfwPollEvents();

	ImGui_ImplOpenGL3_NewFrame();
	ImGui_ImplGlfw_NewFrame();
	ImGui::NewFrame();

	{
		ImGui::Begin("Ray Trace");
		ImGui::Text(" %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate,
		            ImGui::GetIO().Framerate);
		ImGui::End();
	}

	renderer->render();

	ImGui::Render();
	ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
	glfwSwapBuffers(window);
}

static void clean()
{
	ImGui_ImplOpenGL3_Shutdown();
	ImGui_ImplGlfw_Shutdown();
	ImGui::DestroyContext();

	glfwDestroyWindow(window);
	glfwTerminate();

	delete renderer;
	renderer = nullptr;
}
