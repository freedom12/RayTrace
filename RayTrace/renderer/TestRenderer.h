#pragma once
#include "Renderer.h"

#include <GL/gl3w.h>
#include <glm/glm.hpp>
#include <memory>

#include "../core/RenderQuad.h"
#include "../material/Material.h"
#include "../core/Camera.h"

class TestRenderer final :
	public Renderer
{
public:
	TestRenderer(int w, int h);
	virtual ~TestRenderer();

	void update(float dt) override;
	void updateSize(int w, int h) override;
	void render() override;

	TestRenderer(const TestRenderer &c) = delete;
	TestRenderer &operator=(const TestRenderer &rhs) = delete;
	TestRenderer(TestRenderer &&c) noexcept = default;
	TestRenderer &operator=(TestRenderer &&rhs) noexcept = default;
private:
	int width, height;
	int depthCount = 5;
	int sampleCount = 1;

	GLuint texture{};
	std::unique_ptr<Program> program;
	std::unique_ptr<RenderQuad> target;
	std::unique_ptr<ShapeList> scene;
	std::unique_ptr<glm::vec3[]> colors;
	std::unique_ptr<Camera> camera;

	void calculateColors() const;
	[[nodiscard]] glm::vec3 getColor(const Ray &ray, int depth) const;
};
