#include "GLSLTestScene.h"
#include <vector>
#include "../shape/Sphere.h"
#include "../core/Random.h"

GLSLTestScene::GLSLTestScene(const int w, const int h) : width(w), height(h)
{
	depthCount = 10;
	sampleCount = 2;
	auto from = glm::vec3(-3, 2, -7);
	auto to = glm::vec3(0, 0, -1);
	camera = std::make_unique<Camera>(from, to, glm::vec3(0, 1, 0), 20, width / height, 1, glm::distance(from, to));


	auto shaders = std::vector<std::unique_ptr<Shader>>();
	shaders.push_back(std::make_unique<Shader>("../shaders/TestVert.glsl", GL_VERTEX_SHADER));
	shaders.push_back(std::make_unique<Shader>("../shaders/GLSLTestFrag.glsl", GL_FRAGMENT_SHADER));
	program = std::make_unique<Program>(shaders);
	shaders.clear();

	glGenTextures(1, &texture);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, texture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_FLOAT, colors.get());
	glBindTexture(GL_TEXTURE_2D, 0);
}

GLSLTestScene::~GLSLTestScene()
{
	glDeleteTextures(1, &texture);
}

void GLSLTestScene::update(float dt)
{
}

void GLSLTestScene::updateSize(int w, int h)
{
	width = w;
	height = h;
}

void GLSLTestScene::render()
{
	glViewport(0, 0, width, height);
	glClearColor(0.45f, 0.55f, 0.60f, 1.00f);
	glClear(GL_COLOR_BUFFER_BIT);

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, texture);
	glUniform1i(glGetUniformLocation(program->getId(), "texture1"), 0);
	target->draw(*program);
	glBindTexture(GL_TEXTURE_2D, 0);
}
