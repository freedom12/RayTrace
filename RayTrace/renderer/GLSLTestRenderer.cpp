#include "GLSLTestRenderer.h"
#include <vector>
#include <glm/glm.hpp>
#include <glm/gtc/type_ptr.hpp>

#include "../shape/Sphere.h"
#include "../core/Random.h"


GLSLTestRenderer::GLSLTestRenderer(const int w, const int h) : width(w), height(h)
{
	auto from = glm::vec3(-0, 5, -30);
	auto to = glm::vec3(0, 0, 0);
	camera = std::make_unique<Camera>(from, to, glm::vec3(0, 1, 0), 20, width / height, 1, glm::distance(from, to));

	target = std::make_unique<RenderQuad>();

	
	rayTraceProgram = createProgram("../shaders/QuadVert.glsl", "../shaders/RayTraceFrag.glsl");
	accumProgram = createProgram("../shaders/QuadVert.glsl", "../shaders/AccumFrag.glsl");
	outputProgram = createProgram("../shaders/QuadVert.glsl", "../shaders/OutputFrag.glsl");
	postProgram = createProgram("../shaders/QuadVert.glsl", "../shaders/PostFrag.glsl");

	glGenFramebuffers(1, &rayTraceFBO);
	glBindFramebuffer(GL_FRAMEBUFFER, rayTraceFBO);
	glGenTextures(1, &rayTraceTexture);
	glBindTexture(GL_TEXTURE_2D, rayTraceTexture);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, width, height, 0, GL_RGB, GL_FLOAT, 0);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glBindTexture(GL_TEXTURE_2D, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, rayTraceTexture, 0);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	glGenFramebuffers(1, &accumFBO);
	glBindFramebuffer(GL_FRAMEBUFFER, accumFBO);
	glGenTextures(1, &accumTexture);
	glBindTexture(GL_TEXTURE_2D, accumTexture);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, width, height, 0, GL_RGB, GL_FLOAT, 0);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glBindTexture(GL_TEXTURE_2D, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, accumTexture, 0);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	glGenFramebuffers(1, &outputFBO);
	glBindFramebuffer(GL_FRAMEBUFFER, outputFBO);
	glGenTextures(1, &outputTexture);
	glBindTexture(GL_TEXTURE_2D, outputTexture);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, width, height, 0, GL_RGB, GL_FLOAT, 0);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glBindTexture(GL_TEXTURE_2D, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outputTexture, 0);
	glGenTextures(1, &bloomTexture);
	glBindTexture(GL_TEXTURE_2D, bloomTexture);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, width, height, 0, GL_RGB, GL_FLOAT, 0);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glBindTexture(GL_TEXTURE_2D, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, bloomTexture, 0);
	GLuint attachments[2] = { GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1 };
	glDrawBuffers(2, attachments);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

GLSLTestRenderer::~GLSLTestRenderer()
{
	glDeleteTextures(1, &rayTraceTexture);
	glDeleteTextures(1, &accumTexture);

	glDeleteFramebuffers(1, &rayTraceFBO);
	glDeleteFramebuffers(1, &accumFBO);
}

void GLSLTestRenderer::update(float dt)
{
}

void GLSLTestRenderer::updateSize(const int w, const int h)
{
	width = w;
	height = h;
}

void GLSLTestRenderer::render()
{
	//maxSampleCount = 1;
	if (curSampleCount < maxSampleCount)
	{
		glViewport(0, 0, width, height);
		glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		curSampleCount++;

		rayTraceProgram->use();
		glUniform1f(glGetUniformLocation(rayTraceProgram->getId(), "sampleCounter"), curSampleCount);
		glUniform2f(glGetUniformLocation(rayTraceProgram->getId(), "resolution"), width, height);
		glUniform3f(glGetUniformLocation(rayTraceProgram->getId(), "randomVector"), Random::getUnitFloat(), Random::getUnitFloat(), Random::getUnitFloat());

		glUniform3fv(glGetUniformLocation(rayTraceProgram->getId(), "camera.position"), 1, glm::value_ptr(camera->position));
		glUniform3fv(glGetUniformLocation(rayTraceProgram->getId(), "camera.u"), 1, glm::value_ptr(camera->u));
		glUniform3fv(glGetUniformLocation(rayTraceProgram->getId(), "camera.v"), 1, glm::value_ptr(camera->v));
		glUniform3fv(glGetUniformLocation(rayTraceProgram->getId(), "camera.w"), 1, glm::value_ptr(camera->w));
		glUniform1f(glGetUniformLocation(rayTraceProgram->getId(), "camera.fov"), camera->fov);
		glUniform1f(glGetUniformLocation(rayTraceProgram->getId(), "camera.focalDist"), camera->focusDist);
		glUniform1f(glGetUniformLocation(rayTraceProgram->getId(), "camera.aperture"), camera->radius);
		rayTraceProgram->unUse();

		glBindFramebuffer(GL_FRAMEBUFFER, rayTraceFBO);
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, accumTexture);
		target->draw(*rayTraceProgram);
		glBindTexture(GL_TEXTURE_2D, 0);
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
	}


	glBindFramebuffer(GL_FRAMEBUFFER, accumFBO);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, rayTraceTexture);
	target->draw(*accumProgram);
	glBindTexture(GL_TEXTURE_2D, 0);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	std::cout << "!!!!!!!!!!!!!!!!!!" << curSampleCount << std::endl;
	
	
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, rayTraceTexture);
	glBindFramebuffer(GL_FRAMEBUFFER, outputFBO);
	target->draw(*outputProgram);
	glBindTexture(GL_TEXTURE_2D, 0);
	glBindFramebuffer(GL_FRAMEBUFFER, 0);

	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, outputTexture);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, bloomTexture);
	target->draw(*postProgram);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, 0);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, 0);
}

std::unique_ptr<Program> GLSLTestRenderer::createProgram(const std::string &vertFilePath,
	const std::string &fragFilePath) const
{
	auto shaders = std::vector<std::unique_ptr<Shader>>();
	shaders.push_back(std::make_unique<Shader>(vertFilePath, GL_VERTEX_SHADER));
	shaders.push_back(std::make_unique<Shader>(fragFilePath, GL_FRAGMENT_SHADER));
	return std::make_unique<Program>(shaders);
}
