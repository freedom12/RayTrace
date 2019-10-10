#pragma once
#include <GL/gl3w.h>
#include <iostream>

class Shader
{
private:
	GLuint id = 0;
public:
	Shader(const std::string &filePath, GLenum shaderType);
	~Shader();
	[[nodiscard]] GLuint getId() const;
};
