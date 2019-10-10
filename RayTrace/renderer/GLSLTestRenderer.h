#pragma once
#include "Renderer.h"

#include <GL/gl3w.h>
#include <glm/glm.hpp>
#include <memory>

#include "../core/RenderQuad.h"
#include "../material/Material.h"
#include "../core/Camera.h"

class GLSLTestRenderer final :
	public Renderer
{
public:
	GLSLTestRenderer(int w, int h);
	virtual ~GLSLTestRenderer();

	void update(float dt) override;
	void updateSize(int w, int h) override;
	void render() override;

	GLSLTestRenderer(const GLSLTestRenderer &c) = delete;
	GLSLTestRenderer &operator=(const GLSLTestRenderer &rhs) = delete;
	GLSLTestRenderer(GLSLTestRenderer &&c) noexcept = default;
	GLSLTestRenderer &operator=(GLSLTestRenderer &&rhs) noexcept = default;
private:
	int width, height;

	int maxSampleCount = 99999;
	int curSampleCount = 0;

	GLuint rayTraceFBO{}, accumFBO{}, outputFBO{};
	GLuint rayTraceTexture{}, accumTexture{}, outputTexture{}, bloomTexture{};
	std::unique_ptr<Program> rayTraceProgram, accumProgram, outputProgram, postProgram;

	std::unique_ptr<RenderQuad> target;
	std::unique_ptr<ShapeList> scene;
	std::unique_ptr<glm::vec3[]> colors;
	std::unique_ptr<Camera> camera;

	[[nodiscard]] std::unique_ptr<Program> createProgram(const std::string &vertFilePath,
	                                                     const std::string &fragFilePath) const;
};
