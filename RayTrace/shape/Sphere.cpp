#include "Sphere.h"

bool Sphere::hit(const Ray &ray, const float tMin, const float tMax, Intersection &isect) const
{
	const auto dir = ray.getDirection();
	const auto oc = ray.getOrigin() - center;

	const auto a = glm::dot(dir, dir);
	const auto b = 2.0f * glm::dot(oc, dir);
	const auto c = glm::dot(oc, oc) - radius * radius;
	//实际上是判断这个方程有没有根，如果有2个根就是击中
	const auto discriminant = b * b - 4.0f * a * c;
	if (discriminant > 0)
	{
		const auto sqrtDiscriminant = sqrt(discriminant);
		auto t = (-b - sqrtDiscriminant) / (2.0f * a);
		if (t < tMax && t > tMin)
		{
			isect.t = t;
			isect.p = ray.getPoint(t);
			isect.normal = glm::normalize(isect.p - center);
			isect.pMaterial = pMaterial;

			if(radius < 0)
			{
				isect.normal = isect.normal * -1.0f;
			}
			return true;
		}
		
		t = (-b + sqrtDiscriminant) / (2.0f * a);
		if (t < tMax && t > tMin)
		{
			isect.t = t;
			isect.p = ray.getPoint(t);
			isect.pMaterial = pMaterial;
			isect.normal = glm::normalize(isect.p - center);

			if (radius < 0)
			{
				isect.normal = isect.normal * -1.0f;
			}
			return true;
		}
	}

	return false;
}
