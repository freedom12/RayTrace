#pragma once
#include <GL/gl3w.h>
#include <memory>
#include <vector>
#include "Shader.h"

class Program
{
private:
	GLuint id;
public:
	explicit Program(const std::vector<std::unique_ptr<Shader>> &shaders);
	~Program();
	void use() const;
	void unUse() const;
	[[nodiscard]] GLuint getId() const;
};
