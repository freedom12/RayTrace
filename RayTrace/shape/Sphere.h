#pragma once
#include <glm/glm.hpp>
#include <iostream>
#include "Shape.h"

class Sphere final :
	public Shape
{
public:
	Sphere(const glm::vec3 cen, const float r, const std::shared_ptr<Material> &pMat): center(cen), radius(r)
	{
		pMaterial = pMat;
	};
	~Sphere() { std::cout << "Sphere Destroy" << std::endl; };
	Sphere(const Sphere &c) = default;
	Sphere &operator=(const Sphere &rhs) = default;
	Sphere(Sphere &&c) noexcept = default;
	Sphere &operator=(Sphere &&rhs) noexcept = default;
	bool hit(const Ray &ray, float tMin, float tMax, Intersection &isect) const override;
private:
	glm::vec3 center = glm::vec3(0);
	float radius = 0;
};
