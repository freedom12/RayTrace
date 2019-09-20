#pragma once
#include "Renderer.h"

#include <GL/gl3w.h>
#include <glm/glm.hpp>
#include <memory>

#include "../core/RenderQuad.h"
#include "../material/Material.h"
#include "../core/Camera.h"

class GLSLTestScene final :
	public Renderer
{
public:
	GLSLTestScene(int w, int h);
	virtual ~GLSLTestScene();

	void update(float dt) override;
	void updateSize(int w, int h) override;
	void render() override;

	GLSLTestScene(const GLSLTestScene &c) = delete;
	GLSLTestScene &operator=(const GLSLTestScene &rhs) = delete;
	GLSLTestScene(GLSLTestScene &&c) noexcept = default;
	GLSLTestScene &operator=(GLSLTestScene &&rhs) noexcept = default;
private:
	int width, height;
	int depthCount = 1;
	int sampleCount = 1;

	GLuint texture{};
	std::unique_ptr<Program> program;
	std::unique_ptr<RenderQuad> target;
	std::unique_ptr<ShapeList> scene;
	std::unique_ptr<glm::vec3[]> colors;
	std::unique_ptr<Camera> camera;

	void calculateColors() const;
	[[nodiscard]] glm::vec3 getColor(const Ray& ray, int depth) const;
};
