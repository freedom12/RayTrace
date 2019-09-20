#pragma once
#include <iostream>
#include <utility>
#include <vector> 
#include <memory>
#include <glm/glm.hpp>
#include "../core/Ray.h"
//#include "../material/Material.h"

class Material;

struct Intersection
{
	float t = 0;
	glm::vec3 p = glm::vec3(0);
	glm::vec3 normal = glm::vec3(0);
	std::shared_ptr<Material> pMaterial;
};

class Shape
{
public:
	Shape() = default;
	virtual ~Shape() { std::cout << "Shape Destroy" << std::endl; };
	Shape(const Shape& c) = default;
	Shape& operator=(const Shape& rhs) = default;
	Shape(Shape&& c) noexcept = default;
	Shape& operator=(Shape&& rhs) noexcept = default;
	
	virtual bool hit(const Ray& ray, float tMin, float tMax, Intersection& isect) const = 0;
protected:
	std::shared_ptr<Material> pMaterial;
};


class ShapeList final :public Shape
{
public:
	void add(std::unique_ptr<Shape> &&shape) {
		//list.push_back(shape);
		list.push_back(std::move(shape));
	}

	bool hit(const Ray &ray, const float tMin, const float tMax, Intersection &isect) const override
	{
		auto ret = false;
		auto tClosest = tMax;
		for (const auto& iter : list)
		{
			if (iter->hit(ray, tMin, tClosest, isect))
			{
				tClosest = isect.t;
				ret = true;
			}
		}
		return ret;
	}
private:
	std::vector<std::unique_ptr<Shape>> list;
};
