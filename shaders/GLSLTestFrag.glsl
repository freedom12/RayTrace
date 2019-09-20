#version 330

#define PI        3.14159265358979323
#define TWO_PI    6.28318530717958648
const int depth = 150;

in vec2 TexCoords;
out vec4 color;

uniform sampler2D accumTexture;
uniform vec3 randomVector;
uniform vec2 resolution;

struct Material { int type; vec4 albedo; float ior; };
struct Intersection { vec3 p; vec3 normal; float t; Material mat;};

struct Ray { vec3 origin; vec3 direction; };
vec3 Ray_getPoint (Ray r, float t)
{
	return r.origin + t * r.direction;
}

struct Sphere { vec3 center; float radius; Material mat;};
bool Sphere_hit(Sphere sphere, Ray ray, float tMin, float tMax, inout Intersection isect)
{
	vec3 dir = ray.direction;
	vec3 oc = ray.origin - sphere.center;

	float a = dot(dir, dir);
	float b = 2.0f * dot(oc, dir);
	float c = dot(oc, oc) - sphere.radius * sphere.radius;
	//实际上是判断这个方程有没有根，如果有2个根就是击中
	float det = b * b - 4.0f * a * c;
	if (det < 0) return false;

	det = sqrt(det);
	float t =  (-b - det) / (2.0f * a);
	if (t > tMin && t < tMax)
	{
		isect.t = t;
		isect.p = Ray_getPoint(ray, t);
		isect.normal = normalize(isect.p - sphere.center);
		isect.mat = sphere.mat;

		if(sphere.radius < 0)
		{
			isect.normal = isect.normal * -1.0f;
		}
		return true;
	}

	t =  (-b + det) / (2.0f * a);
	if (t > tMin && t < tMax)
	{
		isect.t = t;
		isect.p = Ray_getPoint(ray, t);
		isect.normal = normalize(isect.p - sphere.center);
		isect.mat = sphere.mat;

		if(sphere.radius < 0)
		{
			isect.normal = isect.normal * -1.0f;
		}
		return true;
	}

	return false;
}
struct Camera { vec3 u; vec3 v; vec3 w; vec3 position; float fov; float focalDist; float aperture; };

Camera camera = Camera(vec3(1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, 0.0, -1.0), vec3(0.0, 0.0, 1.0), 60.0, 1.0, 1.0);

Sphere sphere1 = Sphere(vec3(0, -100.5f, -1), 100.0, Material(1, vec4(0.8, 0.8, 0.0, 1.0), 1.0 ));
Sphere sphere2 = Sphere(vec3(0.0, 0.0, -1.0), 0.5, Material(2, vec4(0.8, 0.3, 0.3, 1.0), 1.0 ));
Sphere sphere3 = Sphere(vec3(1.5, 0.0, -1.0), 0.5, Material(2, vec4(0.1, 0.3, 0.5, 1.0), 1.0 ));
Sphere sphere4 = Sphere(vec3(-1.5, 0.0, -1.0), 0.5, Material(3, vec4(0.9, 0.9, 0.9, 1.0), 1.5 ));
Sphere sphere5 = Sphere(vec3(-1.5, 0.0, -1.0), 0.5, Material(3, vec4(0.9, 0.9, 0.9, 1.0), 1.5 ));

const int size = 5;
Sphere list[size];

bool List_hit( Ray ray, float tMin, float tMax, inout Intersection isect )
{
	bool ret = false;
	float tClosest = tMax;
	for (int i = 0; i < size; i++)
	{
		if (Sphere_hit(list[i], ray, tMin, tClosest, isect))
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

vec3 GetRandomPointInUnitSphere()
{
	vec3 p = 2.0 * vec3(rand(), rand(), rand()) - vec3(1.0);
    p = normalize(p) * rand();

	return p;
}

float schlick (float cosin, float ior)
{
	float r0 = (1 - ior) / (1 + ior);
	r0 = r0 * r0;
	return r0 + (1 - r0) * pow((1 - cosin), 5);
}

vec3 GetColor(Ray ray, int depth)
{
	Intersection isect;

	vec3 ret = vec3(1.0);
	vec3 dir = vec3(1.0);
	for (int i = 0; i < depth; i++)
	{
		if (List_hit(ray, 0.00001, 999999, isect))
		{
			Material mat = isect.mat;
			int type = mat.type;
			if (type == 1)
			{
				ret *= 0.5;

				dir = isect.normal + GetRandomPointInUnitSphere();
				vec3 attenuation = mat.albedo.xyz;
				ret *= attenuation;
			} 
			else if (type == 2)
			{
				dir = reflect(ray.direction, isect.normal);
				vec3 attenuation = mat.albedo.xyz;
				ret *= attenuation;
				if (dot(dir, isect.normal) <= 0)
				{
					break;
				}
			}
			else if (type == 3)
			{
				vec3 realNormal = vec3(1.0);
				float realIOR = 0;
				float cosin = 0, kd = 0;
		
				vec3 attenuation = vec3(1);
				attenuation = mat.albedo.xyz;

				if (dot(ray.direction, isect.normal) > 0)
				{
					realNormal = -isect.normal;
					realIOR = mat.ior;
					cosin = realIOR * dot(ray.direction, isect.normal);
				}
				else
				{
					realNormal = isect.normal;
					realIOR = 1.0f / mat.ior;
					cosin = -dot(ray.direction, isect.normal);
				}

				vec3 reflectDir = reflect(ray.direction, isect.normal);
				vec3 refractDir = refract(ray.direction, realNormal, realIOR);
				if (length(refractDir) > 0)
				{
					kd = schlick(cosin, mat.ior);
				}
				else
				{
					dir = reflectDir;
					kd = 1;
				}

				if (rand() < kd)
				{
					dir = reflectDir;
				}
				else
				{
					dir = refractDir;
				}

				ret *= attenuation;
			}
			else
			{
				ret = vec3(1.0, 0.0, 0.0);
				dir = isect.normal + GetRandomPointInUnitSphere();
			}
			ray = Ray(isect.p, dir);
			//ray = Ray(isect.p + dir * 0.05, dir);
		}
		else 
		{
			break;
		}
	}

	return ret;
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
	jitter = vec2(0, 0);
	vec2 d = (2.0 * TexCoords - 1.0) + jitter;
	d.x *= resolution.x / resolution.y; 
	//d.x *= tan(camera.fov / 2.0);
	//d.y *= tan(camera.fov / 2.0);
	vec3 rayDir = normalize(d.x * camera.u + d.y * camera.v + camera.w);


	Ray ray = Ray(camera.position, rayDir);
	
	list[0] = sphere1;
	list[1] = sphere2;
	list[2] = sphere3;
	list[3] = sphere4;
	list[4] = sphere5;

	color = vec4(GetColor(ray, depth), 1.0) + texture(accumTexture, TexCoords);
}