//#include <iostream>
#include <fstream>
#include <sstream>

#include "Shader.h"

Shader::Shader(const std::string &filePath, GLenum shaderType)
{
	std::ifstream f;
	f.open(filePath.c_str(), std::ios::in | std::ios::binary);
	if (!f.is_open())
	{
		std::cout << "Failed to open file: " << filePath.c_str() << std::endl;
		return;
	}

	std::stringstream buffer;
	buffer << f.rdbuf();
	auto source = buffer.str();
	const auto *src = static_cast<const GLchar*>(source.c_str());

	id = glCreateShader(shaderType);

	glShaderSource(id, 1, &src, nullptr);
	glCompileShader(id);

	auto result = 0;
	glGetShaderiv(id, GL_COMPILE_STATUS, &result);
	if (result == GL_FALSE)
	{
		std::string msg("Error while compiling shader\n");
		auto logSize = 0;
		glGetShaderiv(id, GL_INFO_LOG_LENGTH, &logSize);
		logSize++;
		auto info = new char[logSize];
		glGetShaderInfoLog(id, logSize, nullptr, info);
		msg += info;
		delete[] info;
		glDeleteShader(id);
		id = 0;

		std::cout << msg << std::endl;
		throw std::runtime_error(msg);
	}
}

Shader::~Shader()
{
	std::cout << "delete shader " << id << std::endl;
	glDeleteShader(id);
}

GLuint Shader::getId() const
{
	return id;
}
