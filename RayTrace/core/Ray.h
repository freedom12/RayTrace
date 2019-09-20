#pragma once
#include <glm/glm.hpp>

class Ray
{
public:
	Ray() = default;;
	Ray(const glm::vec3& o, const glm::vec3& d);
	[[nodiscard]] glm::vec3 getOrigin() const { return origin; };
	[[nodiscard]] glm::vec3 getDirection() const { return direction; };
	[[nodiscard]] glm::vec3 getPoint(float t) const;
private:
	glm::vec3 origin{};
	glm::vec3 direction{};
};

