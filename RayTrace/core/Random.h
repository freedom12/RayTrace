#pragma once
#include <random>
#include <glm/glm.hpp>

class Random
{
public:
	static float getUnitFloat()
	{
		return float(rand()) / float(RAND_MAX);
	}
	static glm::vec2 getUnitVec2()
	{
		return glm::vec2(getUnitFloat(), getUnitFloat());
	}
	static glm::vec3 getUnitVec3()
	{
		return glm::vec3(getUnitFloat(), getUnitFloat(), getUnitFloat());
	}
	static glm::vec3 getUnitSphere()
	{
		auto p = 2.0f * getUnitVec3() - glm::vec3(1);
		p = glm::normalize(p) * getUnitFloat();
		return p;
	}
	static glm::vec3 getUnitCircle()
	{
		auto p = 2.0f * getUnitVec2() - glm::vec2(1);
		p = glm::normalize(p) * getUnitFloat();
		return glm::vec3(p.x, p.y, 0);
	}
};

