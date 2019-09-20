#include "TestRenderer.h"

#include <vector>
#include "../shape/Sphere.h"
#include "../core/Random.h"

TestRenderer::TestRenderer(const int w, const int h) : width(w), height(h)
{
	depthCount = 5;
	sampleCount = 5;
	auto from = glm::vec3(0, 0, -10);
	auto to = glm::vec3(0, 0, -1);
	camera = std::make_unique<Camera>(from, to, glm::vec3(0, 1, 0), 20, width/height, 0.1, glm::distance(from, to));
	
	
	auto shaders = std::vector<std::unique_ptr<Shader>>();
	shaders.push_back(std::make_unique<Shader>("../shaders/QuadVert.glsl", GL_VERTEX_SHADER));
	shaders.push_back(std::make_unique<Shader>("../shaders/TestFrag.glsl", GL_FRAGMENT_SHADER));
	program = std::make_unique<Program>(shaders);
	shaders.clear();

	target = std::make_unique<RenderQuad>();

	scene = std::make_unique<ShapeList>();
	scene->add(std::make_unique<Sphere>(glm::vec3(0, 0, -1), 0.5f,
	                                    std::make_shared<Lambertian>(glm::vec3(0.8, 0.3, 0.3))));
	scene->add(std::make_unique<Sphere>(glm::vec3(0, -100.5f, -1), 100.0f,
	                                    std::make_shared<Lambertian>(glm::vec3(0.8, 0.8, 0.0))));
	scene->add(std::make_unique<Sphere>(glm::vec3(1, 0, -1), 0.5f,
	                                    std::make_shared<Metal>(glm::vec3(0.8, 0.6, 0.2))));
	scene->add(std::make_unique<Sphere>(glm::vec3(0, 0, -1), 0.5f,
	                                    std::make_shared<Dielectric>(1.5)));
	scene->add(std::make_unique<Sphere>(glm::vec3(-1, 0, -1), -0.45f,
	                                    std::make_shared<Dielectric>(1.5)));

	const auto size = width * height;
	//auto data = new glm::vec3[size]();

	colors = std::make_unique<glm::vec3[]>(size);
	calculateColors();

	glGenTextures(1, &texture);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, texture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_FLOAT, colors.get());
	glBindTexture(GL_TEXTURE_2D, 0);
}

TestRenderer::~TestRenderer()
{
	glDeleteTextures(1, &texture);
}

void TestRenderer::update(float /*dt*/)
{
}

void TestRenderer::updateSize(const int w, const int h)
{
	width = w;
	height = h;
}

void TestRenderer::render()
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

void TestRenderer::calculateColors() const
{
	auto lowLeftCorner = glm::vec3(-2, -1, -1);
	auto horizontal = glm::vec3(4, 0, 0);
	auto vertical = glm::vec3(0, 2, 0);
	auto original = glm::vec3(0, 0, 0);
	
	for (auto j = height - 1; j >= 0; j--)
	{
		for (auto i = 0; i < width; i++)
		{
			auto color = glm::vec3();
			for (auto k = 0; k < sampleCount; k++)
			{
				const auto x = (float(i) + Random::getUnitFloat()) / float(width);
				const auto y = (float(j) + Random::getUnitFloat()) / float(height);
				auto ray = camera->createRay(x, y);
				//auto ray = Ray(original, lowLeftCorner + horizontal * x / float(width) + vertical * y / float(height));
				color += getColor(*ray, depthCount);
			}
			const auto index = i + j * width;
			colors[index] = color / float(sampleCount);
		}
	}
}

glm::vec3 TestRenderer::getColor(const Ray &ray, const int depth) const
{
	auto isect = Intersection();
	if (scene->hit(ray, 0.0001f, 9999999, isect))
	{
		auto attenuation = glm::vec3(1);
		Ray scattered;
		if (depth > 0 && isect.pMaterial->scatter(ray, isect, attenuation, scattered))
		{
			return attenuation * getColor(scattered, depth - 1);
		}
		return attenuation;
	}
	return glm::vec3(0.5);
}
