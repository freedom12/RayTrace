#include "Program.h"

Program::Program(const std::vector<std::unique_ptr<Shader>> &shaders)
{
	id = glCreateProgram();

	for (const auto &shader : shaders)
	{
		glAttachShader(id, shader->getId());
	}

	glLinkProgram(id);

	for (const auto &shader : shaders)
	{
		glDetachShader(id, shader->getId());
	}
	std::cout << "program" << id << std::endl;
	auto result = 0;
	glGetProgramiv(id, GL_LINK_STATUS, &result);
	if (result == GL_FALSE)
	{
		std::string msg("Error while linking program\n");
		auto logSize = 0;
		glGetProgramiv(id, GL_INFO_LOG_LENGTH, &logSize);
		logSize++;
		const auto info = new char[logSize];
		glGetProgramInfoLog(id, logSize, nullptr, info);
		msg += info;
		delete[] info;
		glDeleteProgram(id);
		id = 0;

		std::cout << msg << std::endl;
	}
}

Program::~Program()
{
	glDeleteProgram(id);
}

void Program::use() const
{
	glUseProgram(id);
}

void Program::unUse() const
{
	glUseProgram(0);
}

GLuint Program::getId() const
{
	return id;
}
