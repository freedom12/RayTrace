#pragma once
#include  <memory>
#include <glm/glm.hpp>
#include "Random.h"
#include "Ray.h"
float const PI = 3.1415926f;

class Camera
{
public:
	Camera(const glm::vec3 lookFrom, const glm::vec3 lookat, const glm::vec3 vup, const float vfov, const float _aspect,
	       const float r = 0, const float _focusDist = 1)
	{
		fov = vfov;
		aspect = _aspect;
		focusDist = _focusDist;

		radius = r * 0.5f;
		const auto unitAngle = PI / 180.0f * vfov;
		const auto halfHeight = tan(unitAngle * 0.5f);
		const auto halfWidth = aspect * halfHeight;
		position = lookFrom;
		w = normalize((lookat - lookFrom));
		u = normalize(cross(vup, w));
		v = normalize(cross(w, u));
		lowLeftCorner = lookFrom + w * focusDist - halfWidth * u * focusDist - halfHeight * v * focusDist;
		horizontal = 2 * halfWidth * focusDist * u;
		vertical = 2 * halfHeight * focusDist * v;
	}

	[[nodiscard]] std::unique_ptr<Ray> createRay(const float x, const float y) const
	{
		if (radius == 0)
			return std::make_unique<Ray>(position, lowLeftCorner + x * horizontal + y * vertical - position);
		const auto rd = radius * Random::getUnitCircle();
		const auto offset = rd.x * u + rd.y * v;
		return std::make_unique<Ray>(position + offset,
		                             lowLeftCorner + x * horizontal + y * vertical - position - offset);
	}

	glm::vec3 position{};
	glm::vec3 lowLeftCorner{};
	glm::vec3 horizontal{};
	glm::vec3 vertical{};
	glm::vec3 u{}, v{}, w{};
	float radius;
	float fov;
	float aspect;
	float focusDist;
};
