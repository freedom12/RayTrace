
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
	float metallic;
	float roughness; 
	float specular; 
	float emission;
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
	int objId;
};

struct Ray { vec3 origin; vec3 direction; };
struct Sphere { vec3 center; float radius; Material mat;};
struct Camera { vec3 u; vec3 v; vec3 w; vec3 position; float fov; float focalDist; float aperture; };
uniform Camera camera;

const int Sphere_Size = 11;
Sphere sphereList[Sphere_Size];
const int Light_Size = 2;
Sphere lightList[Light_Size];

Sphere sphere1 = Sphere(vec3(0, -10005, 0.0), 10000.0, Material(vec4(1, 1, 1, 1.0), 0.0, 0.05, 1.0, 0.0));
Sphere sphere2 = Sphere(vec3(30.0, 0.0, 0.0), 5, Material(vec4(242.0/255.0, 163.0/255.0, 137.0/255.0, 1.0), 1.0, 0.1, 1.0, 0.0));
Sphere sphere3 = Sphere(vec3(20.0, 0.0, 0.0), 5, Material(vec4(255.0/255.0, 181.0/255.0, 73.0/255.0, 1.0), 1.0, 0.4, 1.0, 0.0));
Sphere sphere4 = Sphere(vec3(10.0, 0.0, 0.0), 5, Material(vec4(90.0/255.0, 150.0/255.0, 200.0/255.0, 1.0), 0.0, 0.3, 1.0, 0.0));
Sphere sphere5 = Sphere(vec3(0.0, 0.0, 0.0), 5, Material(vec4(1.0, 1.0, 1.0, 1.0), 0.0, 1.0, 1.0, 0.0));
Sphere sphere6 = Sphere(vec3(-10.0, 0.0, 0.0), 5, Material(vec4(0.0, 1.0, 1.0, 1.0), 0.0, 0.1, 2.0, 0.0));
Sphere sphere7 = Sphere(vec3(-20.0, 0.0, 0.0), 5, Material(vec4(1.0, 1.0, 1.0, 0.0), 0.0, 0.1, 1.0, 0.0));
Sphere sphere8 = Sphere(vec3(-30.0, 0.0, 0.0), 5, Material(vec4(1.0, 1.0, 1.0, 0.0), 0.0, 0.4, 1.0, 0.0));
Sphere sphere9 = Sphere(vec3(-35.0, 5, 25), 10, Material(vec4(1.0, 0.0, 0.0, 1.0), 0.0, 0.1, 0.1, 0.0));
//Sphere sphere10 = Sphere(vec3(5, 0, -7.5), 3, Material(vec4(1.0, 1.0, 1.0, -1.0), 0.0, 0.1, 1.0, 0.0));

Sphere sphereL1 = Sphere(vec3(-10.0, 10, -5), 1, Material(vec4(1.0, 1.0, 1.0, 1.0), 1.0, 1.0, 1.0, 50.0));
Sphere sphereL2 = Sphere(vec3(15.0, 10.0, 5), 1, Material(vec4(1.0, 0.0, 0.0, 1.0), 1.0, 1.0, 1.0, 40.0));

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
	sphereList[8] = sphere9;

	sphereList[9] = sphereL1;
	sphereList[10] = sphereL2;
	lightList[0] = sphereL1;
	lightList[1] = sphereL2;
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
			isect.ffnormal = dot(isect.normal, ray.direction) <= 0.0 ? isect.normal : isect.normal * -1.0;
			return true;
        }


		t = (-b + sqrt(discriminant)) / (2.0 * a);
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
			isect.ffnormal = dot(isect.normal, ray.direction) <= 0.0 ? isect.normal : isect.normal * -1.0;
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
			isect.objId = i;
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

	return 1.0 / ( Vis_SmithV * Vis_SmithL ) * 4 * NoL * NoV;

	/*
	float k = (roughness + 1) * (roughness + 1) / 8;
	float g1 = NoV / (NoV * (1 - k) + k);
	float g2 = NoL / (NoL * (1 - k) + k);
    return g1*g2 / (4 * NoV * NoL + EPS);
	*/
	/*
	float alpha = roughness * roughness;
	float alpha2 = alpha * alpha;
	float tan2 = 1.f / (NoV * NoV) - 1.f;
	float g1 = 2.f / (1.f + sqrt(1 + alpha2 * tan2));

	tan2 = 1.f / (NoL * NoL) - 1.f;
	float g2 = 2.f / (1.f + sqrt(1 + alpha2 * tan2));

	return g1 * g2;
	*/
}

float SchlickFresnel(float u)
{
    float a = clamp(1.0 - u, 0.0, 1.0);
    float a2 = a * a;
    return a2 * a2 * a;
}

vec3 MetalDir(Ray ray, Intersection isect)
{
	vec3 dir;
	vec3 N = isect.ffnormal;
	vec3 V = -ray.direction;

	float probability = rand();
	float dRatio = 0.5 * (1.0 - isect.mat.metallic);
	float sRatio = 1.0 - dRatio;

	float r1 = rand();
	float r2 = rand();

	vec3 upVector = abs(N.z) < 0.999 ? vec3(0, 0, 1) : vec3(1, 0, 0);
	vec3 tangentX = normalize(cross(upVector, N));
	vec3 tangentY = cross(N, tangentX);

	if (probability < dRatio) 
	{
		vec3 sampleDir = CosineHemisphereSample(r1, r2);
		sampleDir = tangentX * sampleDir.x + tangentY * sampleDir.y + N * sampleDir.z;
		dir = sampleDir;
	}
	else
	{
		vec3 sampleDir = ImportanceGGXSample(isect.mat.roughness, r1, r2);
		sampleDir = tangentX * sampleDir.x + tangentY * sampleDir.y + N * sampleDir.z;
		dir = reflect(-V, sampleDir);
	}

	return dir;
}

vec3 MetalF(Ray ray, Intersection isect, vec3 dir, inout float pdf)
{
	vec3 ret;

	float dRatio = 0.5 * (1.0 - isect.mat.metallic);
	float sRatio = 1.0 - dRatio;

	vec3 N = isect.ffnormal;
	vec3 V = -ray.direction;
	vec3 L = dir;
	vec3 H = normalize(L + V);
	float NoH = saturate(dot(H, N));
	float NoL = saturate(dot(L, N));
	float NoV = saturate(dot(N, V));
	float LoH = saturate(dot(L, H));
	float VoH = saturate(dot(V, H));

	vec3 dColor = isect.mat.albedo.xyz;
	vec3 sColor = mix(vec3(0.08 * isect.mat.specular) , isect.mat.albedo.xyz, isect.mat.metallic);
	
	float sK = SchlickFresnel(VoH);
	float dK = (1.0 - sK) * (1.0 - isect.mat.metallic);

	vec3 F = mix(sColor, vec3(1.0), sK);
	float D = D_GTR2(isect.mat.roughness, NoH);
	float G = Vis_Smith(isect.mat.roughness, NoL, NoV);

	float dPDF = NoL / PI;
	float sPDF = D * NoH / (4.0 * VoH);
	
	pdf = dRatio * dPDF + sRatio * sPDF;
	ret = (dColor / PI * dK * dRatio + F * G * D / (4 * NoL * NoV) * sRatio) * NoL / pdf;

	return ret;
}

vec3 MetalSampleF(Ray ray, Intersection isect, inout vec3 dir, inout float pdf)
{
	vec3 ret;

	dir = MetalDir(ray, isect);
	ret = MetalF(ray, isect, dir, pdf);

	return ret;
}

float Fr(float cosTheta, float ior) {
	float R0 = (ior - 1) / (ior + 1);
	R0 = R0 * R0;
	float Fr = R0 + (1 - R0) * pow((1 - cosTheta), 5);

	return Fr;
}

vec3 GlassDir(Ray ray, Intersection isect, inout int type)
{
	vec3 dir;

	float r = rand();
	vec3 N = isect.ffnormal;
	vec3 V = -ray.direction;
	vec3 L = dir;
	
	bool entering = dot(-ray.direction, isect.normal) < 0;

	float ior = 1.5;
	ior = entering ? ior : 1/ior;
	float NoV = abs(dot(N, V));
	float NoL = abs(dot(N, L));

	vec3 upVector = abs(N.z) < 0.999 ? vec3(0, 0, 1) : vec3(1, 0, 0);
	vec3 tangentX = normalize(cross(upVector, N));
	vec3 tangentY = cross(N, tangentX);

	float r1 = rand();
	float r2 = rand();
	vec3 H = ImportanceGGXSample(isect.mat.roughness, r1, r2);
	H = tangentX * H.x + tangentY * H.y + N * H.z;

	float F = Fr(entering?NoL:NoV, ior);
	if (r > F)
	{
		dir = refract(-V, H, ior);

		if (dir != vec3(0))
		{
			type = 1;
			dir = normalize(dir);
			return dir;
		}
	}
	
	type = 0;
	dir = reflect(-V, H);

	return dir;
}


vec3 GlassF(Ray ray, Intersection isect, vec3 dir, inout float pdf, int type)
{
	vec3 ret;	
	
	vec3 N = isect.ffnormal;
	vec3 V = -ray.direction;
	vec3 L = dir;
	float NoL = abs(dot(N, L));
	float NoV = abs(dot(N, V));


	bool entering = dot(-ray.direction, isect.normal) < 0;

	float ior = 1.5;
	ior = entering ? ior : 1/ior;
	
	float F = Fr(entering?NoL:NoV, ior);
	if (type == 1)
	{
		vec3 H = normalize(V + L * 1/ior);

		float NoH = dot(H, N);
		float LoH = dot(L, H);
		float VoH = dot(V, H);

		float D = D_GTR2(isect.mat.roughness, abs(NoH));
		float G = Vis_Smith(isect.mat.roughness, (NoL), (NoV));

		float sqrtDenom = VoH + ior * LoH;
		float dwh_dwi = abs((ior * ior * LoH) / (sqrtDenom * sqrtDenom));
		pdf = D * dwh_dwi;
		
		float factor = abs(VoH * LoH / (NoL * NoV));
		ret = isect.mat.albedo.xyz * G * factor * abs(NoL) / abs(LoH * NoH);
	}
	else 
	{	
		vec3 N = isect.ffnormal;
		vec3 V = -ray.direction;
		vec3 L = dir;
		vec3 H = normalize(L + V);
		float NoH = saturate(dot(H, N));
		float NoL = saturate(dot(L, N));
		float NoV = saturate(dot(N, V));
		float LoH = saturate(dot(L, H));
		float VoH = saturate(dot(V, H));


		float D = D_GTR2(isect.mat.roughness, NoH);
		float G = Vis_Smith(isect.mat.roughness, NoL, NoV);
		
		float dwh_dwi = 1.0 / (4.0 * VoH);
		pdf = D * abs(NoH) * dwh_dwi * F;
		//ret = isect.mat.albedo.xyz * (F * G * D) * NoL / (4 * NoL * NoV + EPS) / pdf;
		ret = isect.mat.albedo.xyz * G * VoH / (NoV * NoH);
	}

	return ret;
}

vec3 GlassSampleF(Ray ray, Intersection isect, inout vec3 dir, inout float pdf)
{
	vec3 ret;

	int type;
	dir = GlassDir(ray, isect, type);
	ret = GlassF(ray, isect, dir, pdf, type);

	return ret;
}

vec3 MediumDir(Ray ray, Intersection isect)
{
	vec3 dir;
	vec3 N = isect.ffnormal;
	vec3 V = -ray.direction;

	float r1 = rand();
	float r2 = rand();

	vec3 upVector = abs(N.z) < 0.999 ? vec3(0, 0, 1) : vec3(1, 0, 0);
	vec3 tangentX = normalize(cross(upVector, N));
	vec3 tangentY = cross(N, tangentX);

	vec3 sampleDir = CosineHemisphereSample(r1, r2);
	sampleDir = tangentX * sampleDir.x + tangentY * sampleDir.y + N * sampleDir.z;
	dir = -sampleDir;
	
	
	dir = ray.direction;
	return dir;
}

vec3 MediumF(Ray ray, Intersection isect, vec3 dir, inout float pdf, Intersection lastIsect)
{
	vec3 ret;

	if (isect.objId != -1 && isect.objId == lastIsect.objId)
	{
		pdf = 1;
		float k = length(isect.p - lastIsect.p)/ 5;
		k = saturate(k);
		k = min(k, 0.8);
		ret = (1-k) * (isect.mat.albedo.xyz);
	}
	else 
	{
		pdf = 1;
		ret = vec3(1);
	}
	pdf = 1;
	ret = vec3(1);
	return ret;
}

vec3 MediumSampleF(Ray ray, Intersection isect, inout vec3 dir, inout float pdf, Intersection lastIsect)
{
	vec3 ret;

	dir = MediumDir(ray, isect);
	ret = MediumF(ray, isect, dir, pdf, lastIsect);

	return ret;
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
		Ray shadowRay;
		Intersection shadowIsect;

		Sphere light = lightList[i];
		vec3 lightPos = light.center + UniformSphereSample(rand(), rand()) * light.radius; 
		vec3 lightDir = normalize(lightPos - isect.p);
		float lightDis = length(lightPos - isect.p);
		vec3 lightColor = light.mat.albedo.xyz * light.mat.emission;
		float lightPdf = (lightDis*lightDis) / (4.0 * PI * light.radius * light.radius);

		shadowRay.direction  = lightDir;
		shadowRay.origin = isect.p + EPS * shadowRay.direction;
		bool result = List_hit(shadowRay, EPS, lightDis - EPS * 2, shadowIsect);

		if(!result || shadowIsect.mat.emission > 0)
		{
			float brdfPdf;
			vec3 f;
			if (isect.mat.albedo.w > 1.0 - EPS)
			{
				f = MetalF(ray, isect, shadowRay.direction, brdfPdf);
			}
			else if (dot(shadowRay.direction, isect.normal) > 0)
			{
				f = GlassF(ray, isect, shadowRay.direction, brdfPdf, 0);
			}
			else 
			{
				f = GlassF(ray, isect, shadowRay.direction, brdfPdf, 1);
			}
			color += f * lightColor * PowerHeuristic(lightPdf, brdfPdf) * brdfPdf / lightPdf;
		}


		int type;
		if (isect.mat.albedo.w > 1.0 - EPS)
		{
			shadowRay.direction = MetalDir(ray, isect);
		} 
		else 
		{
			shadowRay.direction = GlassDir(ray, isect, type);
		}
		shadowRay.direction  = MetalDir(ray, isect);
		shadowRay.origin = isect.p + EPS * shadowRay.direction;
		result = List_hit(shadowRay, EPS, lightDis + EPS * 2, shadowIsect);

		if(result && shadowIsect.mat.emission > 0)
		{
			float brdfPdf;
			vec3 f;
			if (isect.mat.albedo.w > 1.0 - EPS)
			{
				f = MetalF(ray, isect, shadowRay.direction, brdfPdf);
			}
			else
			{
				f = GlassF(ray, isect, shadowRay.direction, brdfPdf, type);
			}
			
			//f = MetalF(ray, isect, shadowRay.direction, brdfPdf);
			color += f * lightColor * PowerHeuristic(brdfPdf, lightPdf);// * brdfPdf / brdfPdf
		}
		
	}

	color = color / Light_Size;
    return color;
}


vec3 GetColor(Ray ray, int depth)
{
	Intersection lastIsect;
	Intersection isect;
	isect.objId = -1;

	vec3 radiance = vec3(0.0);
	vec3 throughput = vec3(1.0);
	vec3 dir = vec3(1.0);
	float pdf = 1.0;
	for (int i = 0; i < depth; i++)
	{
		lastIsect = isect;
		if (!List_hit(ray, EPS, INFINITY, isect))
		{
			float y = 0.5 * (ray.direction.y + 1.0);
			float x = 0.5 * (ray.direction.x + 1.0);
			vec3 hdrColor =(1 - y) * vec3(1.0) + y * vec3(0.5f, 0.7f, 1);//getHdr(texture2D( hdrTexture, getuv(ray.d)));
			if ((int(y*10)%2) == (int(x*10)%2))
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

		if (mat.emission > 0) {
			radiance += EmitterSample(i, isect.isSpecularBounce, pdf, isect.emissive.w, isect.emissive.xyz) * throughput;
			break;
		}
		
		if (mat.albedo.w > 1.0 - EPS)
		{
			isect.isSpecularBounce = false;
			radiance += DirectLight(ray, isect) * throughput;
			throughput *= MetalSampleF(ray, isect, dir, pdf);
		}
		else if(mat.albedo.w > 0 - EPS) 
		{
			isect.isSpecularBounce = false;
			radiance += DirectLight(ray, isect) * throughput;
			throughput *= GlassSampleF(ray, isect, dir, pdf);
		}
		else 
		{
			isect.isSpecularBounce = false;
			throughput *= MediumSampleF(ray, isect, dir, pdf, lastIsect);
		}
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