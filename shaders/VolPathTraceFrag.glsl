
#version 460

#define PI        3.14159265358979323
#define TWO_PI    6.28318530717958648
#define INFINITY  1000000.0
#define EPS 0.00001
#define saturate(x) clamp(x, 0.0, 1.0)

precision highp float;
const int depth = 30;

in vec2 TexCoords;
out vec4 color;

layout(binding = 0) uniform sampler2D accumTexture;
uniform vec3 randomVector;
uniform vec2 resolution;
uniform float sampleCounter;

struct Material
{
	vec4 albedo;
	float density;
	bool isMedium;
};

struct Intersection
{
	vec3 p;
	vec3 normal;
	vec3 ffnormal;
	float t;
	Material mat;
	vec4 emissive;
	bool isSpecularBounce;
};

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { vec3 center; float radius; Material mat; };
struct Camera { vec3 u; vec3 v; vec3 w; vec3 position; float fov; float focalDist; float aperture; };
uniform Camera camera;

const int Sphere_Size = 2;
Sphere sphereList[Sphere_Size];

Sphere sphere1 = Sphere(vec3(0, -10005, 0.0), 10000.0, Material(vec4(1, 1, 1, 1.0), 0.0, false));
Sphere sphere2 = Sphere(vec3(0.0, 0.0, 0.0), 5, Material(vec4(1, 1, 1, 1.0), 0.5, false));

void initScene()
{
	sphereList[0] = sphere1;
	sphereList[1] = sphere2;
}

bool Sphere_hit(Sphere sphere, Ray ray, float tMin, float tMax, inout Intersection isect)
{
	tMin = 0.01;

	vec3 dir = ray.direction;
	vec3 toSphere = ray.origin - sphere.center;
	float a = dot(dir, dir);
	float b = 2.0 * dot(toSphere, dir);
	float c = dot(toSphere, toSphere) - sphere.radius * sphere.radius;
	float discriminant = b * b - 4.0 * a * c;

	if (discriminant > 0.0) {
		float t = (-b - sqrt(discriminant)) / (2.0 * a);
		if (t > tMin && t < tMax)
		{
			isect.t = t;
			isect.p = ray.origin + t * ray.direction;
			isect.normal = normalize(isect.p - sphere.center);
			isect.mat = sphere.mat;
			isect.emissive = vec4(0.0);

			if (sphere.radius < 0.0)
			{
				isect.normal = isect.normal * -1.0;
			}
			isect.ffnormal = dot(isect.normal, ray.direction) <= 0.0 ? isect.normal : isect.normal * -1.0;

			return true;
		}


		t = (-b + sqrt(discriminant)) / (2.0 * a);
		if (t > tMin && t < tMax)
		{
			isect.t = t;
			isect.p = ray.origin + t * ray.direction;
			isect.normal = normalize(isect.p - sphere.center);
			isect.mat = sphere.mat;

			if (sphere.radius < 0.0)
			{
				isect.normal = isect.normal * -1.0;
			}
			isect.ffnormal = dot(isect.normal, ray.direction) <= 0.0 ? isect.normal : isect.normal * -1.0;

			return true;
		}
	}

	return false;
}

bool List_hit(Ray ray, float tMin, float tMax, inout Intersection isect)
{
	bool ret = false;
	float tClosest = tMax;
	for (int i = 0; i < Sphere_Size; i++)
	{
		if (Sphere_hit(sphereList[i], ray, tMin, tClosest, isect))
		{
			tClosest = isect.t;
			ret = true;
		}
	}
	return ret;
}

vec2 seed;
float rand()
{
	seed -= vec2(randomVector.x * randomVector.y);
	return fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453);
}


vec3 GetColor(Ray ray, int depth)
{
	Intersection isect;

	vec3 radiance = vec3(0.0);
	vec3 throughput = vec3(1.0);
	vec3 dir = vec3(1.0);
	float pdf = 1.0;
	for (int i = 0; i < depth; i++)
	{
		if (!List_hit(ray, EPS, INFINITY, isect))
		{
			float y = 0.5 * (ray.direction.y + 1.0);
			float x = 0.5 * (ray.direction.x + 1.0);
			vec3 hdrColor = (1 - y) * vec3(1.0) + y * vec3(0.5f, 0.7f, 1);//getHdr(texture2D( hdrTexture, getuv(ray.d)));
			if ((int(y * 10) % 2) == (int(x * 10) % 2))
			{
				hdrColor = vec3(1);
			}
			else
			{
				hdrColor = vec3(0);
			}


			hdrColor *= 0.3;
			radiance += hdrColor * throughput;
			break;
		}
		Material mat = isect.mat;
		if (mat.isMedium)
		{
			Intersection isect1;
			Intersection isect2;
			//if ()
		}

		ray = Ray(isect.p + EPS * dir, dir);
	}

	return max(radiance, vec3(1, 0, 0));
}

void main(void)
{
	seed = gl_FragCoord.xy;

	float r1 = 2.0 * rand();
	float r2 = 2.0 * rand();

	vec2 jitter;
	jitter.x = r1 < 1.0 ? sqrt(r1) - 1.0 : 1.0 - sqrt(2.0 - r1);
	jitter.y = r2 < 1.0 ? sqrt(r2) - 1.0 : 1.0 - sqrt(2.0 - r2);
	jitter /= (resolution * 0.5);

	vec2 d = (2.0 * TexCoords - 1.0) + jitter;
	d.x *= resolution.x / resolution.y * tan(camera.fov / 2.0);
	d.y *= tan(camera.fov / 2.0);
	vec3 rayDir = normalize(d.x * camera.u + d.y * camera.v + camera.w);

	Ray ray = Ray(camera.position, rayDir);

	initScene();

	vec3 result = (texture(accumTexture, TexCoords).xyz * (sampleCounter - 1) + GetColor(ray, depth)) / sampleCounter;

	color = vec4(result, 1.0);
}