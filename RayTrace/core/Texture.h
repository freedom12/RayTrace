#pragma once
#include <GL/gl3w.h>

class Texture
{
public:
	Texture(int w, int h);
	~Texture();
	[[nodiscard]] GLuint getId() const { return id; };
	[[nodiscard]] GLuint getWidth() const { return width; };
	[[nodiscard]] GLuint getHeight() const { return height; };
private:
	GLuint id{};
	int width, height;
};
