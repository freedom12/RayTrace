#pragma once
#include <GL/gl3w.h>
#include "Program.h"

class RenderQuad
{
public:
	RenderQuad();
	~RenderQuad();
	void draw(Program &program) const;
private:
	GLuint vao{};
	GLuint vbo{};
};
