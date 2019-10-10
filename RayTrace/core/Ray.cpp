#include "Ray.h"

Ray::Ray(const glm::vec3 &o, const glm::vec3 &d)
{
	origin = o;
	direction = normalize(d);
}

glm::vec3 Ray::getPoint(const float t) const
{
	return origin + t * direction;
}
