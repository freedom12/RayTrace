#pragma once

class Renderer
{
public:
	Renderer() = default;
	virtual ~Renderer() = default;
	Renderer(const Renderer &c) = default;
	Renderer &operator=(const Renderer &rhs) = default;
	Renderer(Renderer &&c) noexcept = default;
	Renderer &operator=(Renderer &&rhs) noexcept = default;


	virtual void update(float dt) = 0;
	virtual void updateSize(int w, int h) = 0;
	virtual void render() = 0;
protected:
	float progress = 0;
};
