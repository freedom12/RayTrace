
#version 460

#define PI        3.14159265358979323
#define TWO_PI    6.28318530717958648
#define INFINITY  1000000.0
#define EPS 0.0001
#define saturate(x) clamp(x, 0.0, 1.0)

precision highp float;
const int depth = 5;

in vec2 TexCoords;
out vec4 color;

layout(binding = 0) uniform sampler2D accumTexture;
uniform vec3 randomVector;
uniform vec2 resolution;
uniform float sampleCounter;

struct Material 
{  
	vec4 albedo; 
	float metallic;
	float roughness; 
	float specular; 
	float emission;
};

struct Intersection 
{ 
	vec3 p; 
	vec3 normal; 
	float t; 
	Material mat;
	vec4 emissive;
};

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { vec3 center; float radius; Material mat;};
struct Camera { vec3 u; vec3 v; vec3 w; vec3 position; float fov; float focalDist; float aperture; };
uniform Camera camera;

const int Sphere_Size = 8;
Sphere sphereList[Sphere_Size];
const int Light_Size = 2;
Sphere lightList[Light_Size];

Sphere sphere1 = Sphere(vec3(0, -1005, 0.0), 1000.0, Material(vec4(0.8, 0.75, 0.7, 1.0), 0.0, 1.0, 1.0, 0.0));
Sphere sphere2 = Sphere(vec3(0.0, 0.0, 0.0), 5, Material(vec4(1.0, 1.0, 1.0, 1.0), 0.0, 1, 1.0, 0.0));
Sphere sphere3 = Sphere(vec3(10.0, 0.0, 0.0), 5, Material(vec4(255.0/255.0, 181.0/255.0, 73.0/255.0, 1.0), 1.0, 0.4, 1.0, 0.0));
Sphere sphere4 = Sphere(vec3(20.0, 0.0, 0.0), 5, Material(vec4(242.0/255.0, 163.0/255.0, 137.0/255.0, 1.0), 1.0, 0.1, 1.0, 0.0));
Sphere sphere5 = Sphere(vec3(-10.0, 0.0, 0.0), 5, Material(vec4(0.0, 1.0, 1.0, 1.0), 0.0, 0.1, 1.5, 0.0));
Sphere sphere6 = Sphere(vec3(-20.0, 0.0, 0.0), 5, Material(vec4(1.0, 1.0, 1.0, 0.1), 0.0, 0.3, 1.0, 0.0));
Sphere sphere7 = Sphere(vec3(-10.0, 10, -5), 1, Material(vec4(1.0, 1.0, 1.0, 1.0), 1.0, 1.0, 1.0, 10.0));
Sphere sphere8 = Sphere(vec3(15.0, 10.0, 5), 1, Material(vec4(1.0, 0.0, 0.0, 1.0), 1.0, 1.0, 1.0, 5.0));

void initScene()
{
	sphereList[0] = sphere1;
	sphereList[1] = sphere2;
	sphereList[2] = sphere3;
	sphereList[3] = sphere4;
	sphereList[4] = sphere5;
	sphereList[5] = sphere6;
	sphereList[6] = sphere7;
	sphereList[7] = sphere8;

	lightList[0] = sphere7;
	lightList[1] = sphere8;
}

bool Sphere_hit(Sphere sphere, Ray ray, float tMin, float tMax, inout Intersection isect)
{
	tMin = 0.01;
	
	vec3 dir = ray.direction;
	vec3 toSphere = ray.origin - sphere.center;
    float a = dot(dir, dir);
    float b = 2.0 * dot(toSphere, dir);
    float c = dot(toSphere, toSphere) - sphere.radius * sphere.radius;
    float discriminant = b*b - 4.0*a*c;
	
    if(discriminant > 0.0) {
        float t = (-b - sqrt(discriminant)) / (2.0 * a);
        if(t > tMin && t < tMax)
		{
			isect.t = t;
			isect.p = ray.origin + t * ray.direction;
			isect.normal = normalize(isect.p - sphere.center);
			isect.mat = sphere.mat;
			
			isect.emissive = vec4(0.0);
			if (isect.mat.emission > 0.0)
			{
				isect.emissive.xyz = isect.mat.albedo.xyz * isect.mat.emission;
				float area = 4.0 * PI * sphere.radius * sphere.radius;
				float pdf = (t * t) / area;
				isect.emissive.w = pdf;
			}
			if(sphere.radius < 0.0)
			{
				isect.normal = isect.normal * -1.0;
			}
			return true;
        }
    }

    return false;
}

bool List_hit( Ray ray, float tMin, float tMax, inout Intersection isect )
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

vec3 UniformSphereSample(float r1, float r2)
{
	float z = 1.0 - 2.0 * r1;
	float r = sqrt(max(0.f, 1.0 - z * z));
	float phi = 2.0 * PI * r2;
	float x = r * cos(phi);
	float y = r * sin(phi);

	return vec3(x, y, z);
}

vec3 CosineHemisphereSample(float r1, float r2)
{
    vec3 dir;
    float r = sqrt(r1);
    float phi = 2.0 * PI * r2;
    dir.x = r * cos(phi);
    dir.y = r * sin(phi);
    dir.z = sqrt(max(0.0, 1.0 - dir.x*dir.x - dir.y*dir.y));
	dir = normalize(dir);
    return dir;
}

vec3 ImportanceGGXSample(float roughness, float r1, float r2)
{
    float a = roughness * roughness;
	float a2 = a * a;

	float phi = r1 * 2.0 * PI;

	float cosTheta = sqrt((1.0 - r2) / (1.0 + (a2 - 1.0) *r2));
	float sinTheta = sqrt(1.0 - (cosTheta * cosTheta));

	vec3 H;
	H.x = sinTheta * cos(phi);
	H.y = sinTheta * sin(phi);
	H.z = cosTheta;

    return H;
}

float D_GTR2( float roughness, float NoH )
{
	float a = roughness * roughness ;
    float a2 = a * a;
	float cos2th = NoH * NoH;
	float den = cos2th * (a2 - 1.0) + 1.0;
    return a2 / (PI * den * den);     
}

float Vis_Smith( float roughness, float NoV, float NoL )
{
    float a = roughness * roughness ;
	float a2 = a * a;

	float b = NoV * NoV;
	float Vis_SmithV = (NoV + sqrt(a2 + b - a2 * b));

	b = NoL * NoL;
	float Vis_SmithL = (NoL + sqrt(a2 + b - a2 * b));
	return 1.0 / ( Vis_SmithV * Vis_SmithL );

	//float k = (roughness + 1) * (roughness + 1) / 8;
	//float g1 = NoV / (NoV * (1 - k) + k);
	//float g2 = NoL / (NoL * (1 - k) + k);
   // return g1*g2 / (4 * NoV * NoL + EPS);
}

float SchlickFresnel(float u)
{
    float a = clamp(1.0 - u, 0.0, 1.0);
    float a2 = a * a;
    return a2 * a2 * a;
}

vec3 BRDFSample(Ray ray, Intersection isect)
{
	vec3 N = isect.normal;
	vec3 V = -ray.direction;

	vec3 dir;

	float probability = rand();
	float diffuseRatio = 0.5 * (1.0 - isect.mat.metallic);

	float r1 = rand();
	float r2 = rand();

	vec3 upVector = abs(N.z) < 0.999 ? vec3(0, 0, 1) : vec3(1, 0, 0);
	vec3 tangentX = normalize(cross(upVector, N));
	vec3 tangentY = cross(N, tangentX);

	if (probability < diffuseRatio) // sample diffuse
	{
		dir = CosineHemisphereSample(r1, r2);
		dir = tangentX * dir.x + tangentY * dir.y + N * dir.z;
	}
	else
	{
		vec3 H = ImportanceGGXSample(isect.mat.roughness, r1, r2);
		H = tangentX * H.x + tangentY * H.y + N * H.z;
		dir = reflect(-V, H);
	}

	return dir;
}

float BRDFPdf(in Ray ray, vec3 btdfDir, Intersection isect)
{
	vec3 N = isect.normal;
	vec3 V = -ray.direction;
	vec3 L = btdfDir;
	vec3 H = normalize(L + V);

	float diffuseRatio = 0.5 * (1.0 - isect.mat.metallic);
	float specularRatio = 1.0 - diffuseRatio;

	float NoH = saturate(dot(H, N));
	float VoH = saturate(dot(V, H));
	float NoL = saturate(dot(L, N));

	float pdfSpec = D_GTR2(isect.mat.roughness, NoH) * NoH / (4.0 * VoH);
	float pdfDiff = NoL / PI;

	return diffuseRatio * pdfDiff + specularRatio * pdfSpec;
}

vec3 BRDFEval(in Ray ray, vec3 btdfDir, Intersection isect)
{
	vec3 N = isect.normal;
	vec3 V = -ray.direction;
	vec3 L = btdfDir;
	vec3 H = normalize(L + V);
	float NoL = saturate(dot(N, L));
	float NoV = saturate(dot(N, V));
	float NoH = saturate(dot(N, H));
	float LoH = saturate(dot(L, H));
	float VoH = saturate(dot(V, H));

	vec3 dColor = isect.mat.albedo.xyz;
	vec3 sColor = mix(vec3(0.08 * isect.mat.specular) , isect.mat.albedo.xyz, isect.mat.metallic);

	float dK = (1.0 - isect.mat.metallic);
	float sK = SchlickFresnel(LoH);

	vec3 F = mix(sColor, vec3(1.0), sK);
	float D = D_GTR2(isect.mat.roughness, NoH);
	float G = Vis_Smith(isect.mat.roughness, NoL, NoV);

	vec3 eval = dColor / PI * dK + F * G * D;
	
	return eval;
}


float PowerHeuristic(float a, float b){
    float t = a * a;
	float ret = t / (b * b + t);
	
	return ret;
}

vec3 EmitterSample(int depth, bool specularBounce, float brdfPdf, float lightPdf, vec3 emission)
{
    if (depth == 0 || specularBounce)
	{
        return emission;
	}
    return vec3(0);
	//return PowerHeuristic(brdfPdf, lightPdf)* emission / (lightPdf);
}

vec3 DirectLight(Ray ray, Intersection isect)
{
    vec3 color;
	
	for (int i = 0; i < Light_Size; i++)
	{
		Sphere light = lightList[i];
		vec3 pointlight = light.center + UniformSphereSample(rand(), rand()) * light.radius; 
		vec3 lightDir = normalize(pointlight - isect.p);
		vec3 viewDir = -ray.direction;
		float d = length(pointlight - isect.p);
		vec3 lightColor = light.mat.albedo.xyz * light.mat.emission;

		Ray shadowRay;
		Intersection shadowIsect;

		shadowRay.direction  = lightDir;
		shadowRay.origin = isect.p + EPS * lightDir;
		bool result = List_hit(shadowRay, EPS, d - EPS * 2, shadowIsect);

		if(!result || shadowIsect.mat.emission > 0)
		{
			float brdfPdf = BRDFPdf(ray, lightDir, isect);
			float lightPdf = (d*d) / (4.0 * PI * light.radius * light.radius);
			
			vec3 f = BRDFEval(ray, lightDir, isect);
			color += f * saturate(dot(isect.normal, lightDir)) * lightColor / lightPdf * PowerHeuristic(lightPdf, brdfPdf);			
		}

		
		vec3 brdfDir = BRDFSample(ray, isect);
		shadowRay.direction  = brdfDir;
		shadowRay.origin = isect.p + EPS * brdfDir;
		result = List_hit(shadowRay, EPS, d + EPS * 2, shadowIsect);

		if(result && shadowIsect.mat.emission > 0)
		{
			float brdfPdf = BRDFPdf(ray, brdfDir, isect);
			float lightPdf = (d*d) / (4.0 * PI * light.radius * light.radius);

			vec3 f = BRDFEval(ray, brdfDir, isect);
			color += f * saturate(dot(isect.normal, brdfDir)) * lightColor / brdfPdf * PowerHeuristic(brdfPdf, lightPdf);
		}
	}

	color = color / Light_Size;
    return color;
}

vec3 GetColor(Ray ray, int depth)
{
	Intersection isect;

	vec3 radiance = vec3(0.0);
	vec3 throughput = vec3(1.0);
	vec3 dir = vec3(1.0);
	float brdfPdf = 1.0;

	for (int i = 0; i < depth; i++)
	{
		if (!List_hit(ray, EPS, INFINITY, isect))
		{
			float t = 0.5 * (ray.direction.y + 1.0);
			vec3 hdrColor =(1 - t) * vec3(1.0) + t * vec3(0.5f, 0.7f, 1);//getHdr(texture2D( hdrTexture, getuv(ray.d)));
			hdrColor = vec3(0.1);
			radiance += hdrColor * throughput;
			break;
		}

		Material mat = isect.mat;

		if (mat.emission > 0) {
			radiance += EmitterSample(i, false, brdfPdf, isect.emissive.w, isect.emissive.xyz) * throughput;
			break;
		}

		radiance += DirectLight(ray, isect) * throughput;

		dir = BRDFSample(ray, isect);
		brdfPdf = BRDFPdf(ray, dir, isect);	
		throughput *= BRDFEval(ray, dir, isect) * saturate(dot(isect.normal, dir)) / brdfPdf;

		ray = Ray(isect.p + EPS * dir, dir);
	}
	
	return max(radiance, vec3(0));
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