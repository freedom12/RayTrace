#pragma once
#include <glm/glm.hpp>
#include <optional>

#include "../core/Ray.h"
#include "../core/Random.h"
#include "../shape/Shape.h"

class Material
{
public:
	Material() = default;
	virtual ~Material() = default;
	Material(const Material &c) = default;
	Material &operator=(const Material &rhs) = default;
	Material(Material &&c) noexcept = default;
	Material &operator=(Material &&rhs) noexcept = default;

	static glm::vec3 reflect(const glm::vec3 &vin, const glm::vec3 &normal)
	{
		return vin - 2 * dot(vin, normal) * normal;
	}

	static std::optional<glm::vec3> refract(const glm::vec3 &vin, const glm::vec3 &normal, const float ior)
	{
		const auto uv = normalize((vin));
		const auto dt = dot(uv, normal);
		const auto discriminant = 1 - ior * ior * (1 - dt * dt);
		if (discriminant > 0)
		{
			auto ret = ior * (uv - normal * dt) - normal * sqrt(discriminant);
			return ret;
		}
		return std::nullopt;
	}

	virtual bool scatter(const Ray &ray, const Intersection &isect, glm::vec3 &attenuation, Ray &scattered) const = 0;
};

class Lambertian final : public Material
{
public:
	explicit Lambertian(const glm::vec3 &a) : albedo(a)
	{
	}

	bool scatter(const Ray &ray, const Intersection &isect, glm::vec3 &attenuation, Ray &scattered) const override
	{
		const auto target = isect.p + isect.normal + Random::getUnitSphere();
		scattered = Ray(isect.p, target - isect.p);
		attenuation = albedo;
		return true;
	}

private:
	glm::vec3 albedo;
};

class Metal final : public Material
{
public:
	explicit Metal(const glm::vec3 &a) : albedo(a)
	{
	};

	bool scatter(const Ray &ray, const Intersection &isect, glm::vec3 &attenuation, Ray &scattered) const override
	{
		const auto reflected = reflect(ray.getDirection(), isect.normal);
		scattered = Ray(isect.p, reflected);
		attenuation = albedo;
		return (dot(scattered.getDirection(), isect.normal) > 0);
	}

private:
	glm::vec3 albedo;
};


class Dielectric final : public Material
{
public:
	explicit Dielectric(const float ior) : ior(ior)
	{
	}

	bool scatter(const Ray &ray, const Intersection &isect, glm::vec3 &attenuation, Ray &scattered) const override
	{
		glm::vec3 realNormal;
		float realIOR;
		float cos, kd;

		attenuation = glm::vec3(1);

		if (dot(ray.getDirection(), isect.normal) > 0)
		{
			realNormal = -isect.normal;
			realIOR = ior;
			cos = dot(ray.getDirection(), isect.normal);
		}
		else
		{
			realNormal = isect.normal;
			realIOR = 1.0f / ior;
			cos = -dot(ray.getDirection(), isect.normal);
		}

		const auto reflectDir = reflect(ray.getDirection(), isect.normal);
		const auto refractDir = refract(ray.getDirection(), realNormal, realIOR);
		if (refractDir.has_value())
		{
			kd = schlick(cos, ior);
		}
		else
		{
			scattered = Ray(isect.p, reflectDir);
			kd = 1;
		}

		const auto r = Random::getUnitFloat();
		if (r < kd)
		{
			scattered = Ray(isect.p, reflectDir);
		}
		else
		{
			scattered = Ray(isect.p, refractDir.value_or(glm::vec3()));
		}
		return true;
	};


private:
	float ior;

	[[nodiscard]] float schlick(const float cos, const float ior) const
	{
		auto r0 = (1 - ior) / (1 + ior);
		r0 = r0 * r0;
		return r0 + (1 - r0) * pow((1 - cos), 5);
	}
};
