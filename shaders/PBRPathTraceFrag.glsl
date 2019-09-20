
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

struct BsdfSampleRec 
{ 
	vec3 bsdfDir; 
	float pdf; 
};

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
vec3 Ray_getPoint (Ray r, float t)
{
	return r.origin + t * r.direction;
}

struct Sphere { vec3 center; float radius; Material mat;};
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
			isect.p = Ray_getPoint(ray, t);
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
struct Camera { vec3 u; vec3 v; vec3 w; vec3 position; float fov; float focalDist; float aperture; };
uniform Camera camera;

//Material.albedo.w 1.0 普通材质 (0.0, 1.0)透明材质 折射率 -1.0 发光材质
Sphere sphere1 = Sphere(vec3(0, -1005, 0.0), 1000.0, Material(vec4(0.8, 0.75, 0.7, 1.0), 0.0, 1.0, 1.0, 0.0));
Sphere sphere2 = Sphere(vec3(0.0, 0.0, 0.0), 5, Material(vec4(1.0, 1.0, 1.0, 1.0), 0.0, 1, 1.0, 0.0));
Sphere sphere3 = Sphere(vec3(10.0, 0.0, 0.0), 5, Material(vec4(255.0/255.0, 181.0/255.0, 73.0/255.0, 1.0), 1.0, 0.4, 1.0, 0.0));
Sphere sphere4 = Sphere(vec3(20.0, 0.0, 0.0), 5, Material(vec4(242.0/255.0, 163.0/255.0, 137.0/255.0, 1.0), 1.0, 0.1, 1.0, 0.0));
Sphere sphere5 = Sphere(vec3(-10.0, 0.0, 0.0), 5, Material(vec4(0.0, 1.0, 1.0, 1.0), 0.0, 0.1, 1.0, 0.0));
Sphere sphere6 = Sphere(vec3(-20.0, 0.0, 0.0), 5, Material(vec4(1.0, 1.0, 1.0, 0.1), 1.0, 0.5, 1.5, 0.0));
Sphere sphere7 = Sphere(vec3(-10.0, 10, -0), 1, Material(vec4(1.0, 1.0, 1.0, 1.0), 1.0, 1.0, 1.5, 20.0));
Sphere sphere8 = Sphere(vec3(15.0, 10.0, -5), 1, Material(vec4(1.0, 0.0, 0.0, 1.0), 1.0, 1.0, 1.5, 20.0));

const int Sphere_Size = 8;
Sphere sphereList[Sphere_Size];

const int Light_Size = 2;
Sphere lightList[Light_Size];

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

float random(vec3 scale, float seed) 
{
    return fract(sin(dot(gl_FragCoord.xyz + seed, scale)) * 43758.5453 + seed);
}
vec3 uniformlyRandomDirection(float seed) {
    float u = random(vec3(12.9898, 78.233, 151.7182), seed);
    float v = random(vec3(63.7264, 10.873, 623.6736), seed);
    float z = 1.0 - 2.0 * u;
    float r = sqrt(1.0 - z * z);
    float angle = 6.283185307179586 * v;
    return vec3(r * cos(angle), r * sin(angle), z);
}
vec3 uniformlyRandomVector(float seed) {
    return uniformlyRandomDirection(seed) * sqrt(random(vec3(36.7539, 50.3658, 306.2759), seed));
}
vec3 CosineSampleHemisphere(float u1, float u2)
{
    vec3 dir = vec3(0);;
    float r = sqrt(u1);
    float phi = 2.0 * PI * u2;
    dir.x = r * cos(phi);
    dir.y = r * sin(phi);
    dir.z = sqrt(max(0.0, 1.0 - dir.x*dir.x - dir.y*dir.y));
	dir = normalize(dir);
    return dir;
}

vec3 TangentToWorld(vec3 Vec, vec3 TangentZ)
{
    vec3 UpVector = vec3(1.0, 0.0, 0.0);
    if (abs(TangentZ.z) < 0.999){
        UpVector = vec3(0.0, 0.0, 1.0);
    }
    vec3 TangentX = cross(UpVector,TangentZ);
    TangentX = normalize(TangentX);
    vec3 TangentY = cross(TangentZ,TangentX);
    return TangentX*(Vec.x) + TangentY*(Vec.y) + TangentZ*(Vec.z);
}

vec3 ImportanceSampleGGX(float Roughness,vec3 N,vec2 E) 
{

    // float u = random(vec3(12.9898, 78.233, 151.7182), seed.x);
    // float v = random(vec3(63.7264, 10.873, 623.6736), seed.y);
    // vec2 E = vec2(u,v);

    float a = Roughness * Roughness ;
    float a2 = a*a;

    float Phi = 2.0 * PI * E.x;
    float CosTheta = sqrt((1.0 - E.y) / (1.0 + (a2 - 1.0) * E.y));
    float SinTheta = sqrt(1.0 - CosTheta * CosTheta);

    vec3 H = vec3(0.0, 0.0, 0.0);
    H.x = SinTheta * cos(Phi);
    H.y = SinTheta * sin(Phi);
    H.z = CosTheta;

    return normalize(TangentToWorld(vec3(H.x, H.y, H.z),N));
}


vec4 SampleDir(vec3 N, vec3 L, float Roughness, float Metallic, vec2 seed)
{

    float u = random(vec3(12.9898, 78.233, 151.7182), seed.x);
    float v = random(vec3(63.7264, 10.873, 623.6736), seed.y);
    vec2 E = vec2(u,v);

    vec3 dir = vec3(1);

    float probability = rand();
    float diffuseRatio = 0.5 * (1.0 - Metallic);


    vec3 UpVector = abs(N.z) < 0.999 ? vec3(0, 0, 1) : vec3(1, 0, 0);
    vec3 TangentX = normalize(cross(UpVector, N));
    vec3 TangentY = cross(N, TangentX);

    float type = 0.0;
    if (probability < diffuseRatio){ // sample diffuse
        dir = CosineSampleHemisphere(E.x, E.y);
        dir = TangentX * dir.x + TangentY * dir.y + N * dir.z;
        dir = normalize(dir);
        type = 0.0;
    }else{
        dir = ImportanceSampleGGX(Roughness,L,E);
        type = 1.0;
    }
    return vec4(dir,type);
}

float SchlickFresnel(float u)
{
    float a = clamp(1.0 - u, 0.0, 1.0);
    float a2 = a * a;
    return a2 * a2 * a;
}


vec4 GlassDir(vec3 N, float galss, vec3 d){
    vec3 ffnormal = dot(N, d) <= 0.0 ? N : N * -1.0;
    float n1 = 1.0;
    float n2 = galss;
    float R0 = (n1 - n2) / (n1 + n2);
    R0 *= R0;
    float theta = dot(-d, ffnormal);
    float prob =  R0 + (1.0 - R0) * SchlickFresnel(theta);
    vec3 dir = vec3(1);


    float eta = dot(N, ffnormal) > 0.0 ? (n1 / n2) : (n2 / n1);
    float cos2t = 1.0 - eta * eta * (1.0 - theta * theta);


    if (cos2t < 0.0 || rand() < prob) // Reflection
    {
        dir = normalize(reflect(d, ffnormal));
    }
    else
    {
        dir = normalize(refract(d, ffnormal, eta));
        //dir = ImportanceSampleGGX(0.3,dir,vec2(rand(),rand()));
    }
    
    return vec4(dir,2.0);
}

BsdfSampleRec brdf3_d(vec3 N,vec3 L,vec3 V,Material mat)
{
    vec3 uBaseColor     = mat.albedo.xyz;
    float uMetallic     = mat.metallic;
    vec3 diffuseColor   = uBaseColor - uBaseColor * uMetallic;
    N = normalize(N);
    L = normalize(L);
    float NoL   = saturate( dot( N, L ) );

    //#lambert = DiffuseColor * NoL / PI
    //#pdf = NoL / PI
    vec3 color = vec3(0.0,0.0,0.0);
    if(NoL > 0.0){
        color = diffuseColor;
    }

    BsdfSampleRec bf = BsdfSampleRec(vec3(0), 0);
    bf.bsdfDir = color;
    bf.pdf = NoL / PI;
          
    return bf;
}

float D_GGX( float Roughness, float NoH )
{
	float a = Roughness * Roughness ;
    float a2 = a*a;
	
	float d = NoH * NoH * (a2 - 1) + 1.0;
    return a2 / ( PI*d*d);     
}


float Vis_Smith( float Roughness, float NoV, float NoL )
{
    float a = Roughness * Roughness ;
    float a2 = a*a;
	
	float b = NoV * NoV;
	float Vis_SmithV = (NoV + sqrt(a2 + b - a2 * b));

	b = NoL * NoL;
	float Vis_SmithL = (NoL + sqrt(a2 + b - a2 * b));

    return 1.0 / ( Vis_SmithV * Vis_SmithL );
}

vec3 F_Schlick( vec3 SpecularColor, float VoH )
{
    float Fc = pow( 1.0 - VoH, 5.0 );
    return Fc + (1.0 - Fc) * SpecularColor;
    //return saturate( 50.0 * SpecularColor.y ) * Fc + (1.0 - Fc) * SpecularColor;
}

BsdfSampleRec brdf3_s(vec3 N,vec3 L,vec3 V,Material mat)
{
    
    vec3 uBaseColor = mat.albedo.xyz;
    float uRoughness = mat.roughness;
    float uSpecular = mat.specular;
    float uMetallic = mat.metallic;
    N = normalize(N);
    L = normalize(L);
    V = normalize(V);

    vec3 H                    = normalize(V + L);
    
    float NoL                = saturate( dot( N, L ) );
    float NoV                = saturate( dot( N, V ) );
    float VoH                = saturate( dot( V, H ) );
    float NoH                = saturate( dot( N, H ) );

    vec3 specularColor        = mix( vec3( 0.08 * uSpecular ), uBaseColor, uMetallic );

    // Microfacet specular = D*G*F / (4*NoL*NoV) = D*Vis*F
    // Vis = G / (4*NoL*NoV)

    // Microfacet specular = D*G*F / (4*NoL*NoV)
    // pdf = D * NoH / (4 * VoH)
    
    float D         = D_GGX(uRoughness,NoH);
    float Vis       = Vis_Smith(uRoughness,NoV,NoL);
    vec3  F         = F_Schlick(specularColor,VoH);

    BsdfSampleRec bf = BsdfSampleRec(vec3(0), 0);
    bf.pdf = D * NoH / (4.0 * VoH);
	bf.bsdfDir = Vis * F * D * NoL / bf.pdf;
    return bf;
}

float powerHeuristic(float a, float b){
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
	//return powerHeuristic(brdfPdf, lightPdf)* emission / (lightPdf);
}



vec3 Diffuse_Lambert( vec3 DiffuseColor )
{
    return DiffuseColor * (1.0 / PI);
}

vec3 brdf(vec3 N,vec3 L,vec3 V,vec3 inColor, Material mat){
    
    vec3 uBaseColor = mat.albedo.xyz;
    float uRoughness = mat.roughness;
    float uSpecular = mat.specular;
    float uMetallic = mat.metallic;
    N = normalize(N);
    L = normalize(L);
    V = normalize(V);
    vec3 H                    = normalize(V + L);
    
    float NoL                = saturate( dot( N, L ) );
    float NoV                = saturate( dot( N, V ) );
    float VoH                = saturate( dot( V, H ) );
    float NoH                = saturate( dot( N, H ) );

    vec3 diffuseColor        = uBaseColor - uBaseColor * uMetallic;
    vec3 specularColor        = mix( vec3( 0.08 * uSpecular ), uBaseColor, uMetallic );

    
    float D         = D_GGX(uRoughness, NoH);
    float Vis       = Vis_Smith(uRoughness,NoV,NoL);
    vec3  F         = F_Schlick(specularColor,VoH);

    vec3 diffuse    = Diffuse_Lambert(diffuseColor);

    vec3 specular   = D * Vis * F;
    vec3 color      = inColor * ( diffuse + specular ) * NoL;

	if (color.x > inColor.x)  //防止粗糙度过小时的能量不守恒，会出现亮点
	{
		color = inColor;   
	}


    return color;
}

vec3 directLight(Ray ray, Intersection isect)
{
    vec3 color = vec3(0.0,0.0,0.0);
	
	for (int i = 0; i < Light_Size; i++)
	{
		Sphere light = lightList[i];
		vec3 pointlight = light.center + uniformlyRandomVector(randomVector.z) * light.radius; 
		vec3 lightdir = normalize(pointlight - isect.p);
		vec3 viewDir = -ray.direction;
		float d = length(pointlight - isect.p);

		Ray shadowRay;
		Intersection shadowIsect;

		shadowRay.direction  = lightdir;
		shadowRay.origin = isect.p + EPS * lightdir;
		bool result = List_hit(shadowRay, EPS, d-EPS, shadowIsect);

		if(!result || shadowIsect.mat.emission > 0)
		{
			float pdf =  (d*d) / (4.0 * PI * light.radius * light.radius);
			vec3 lightColor = light.mat.albedo.xyz * light.mat.emission / pdf;
			color += brdf(isect.normal, lightdir, viewDir, lightColor, isect.mat);
		} 
	}

    return color;
}

vec3 GetColor(Ray ray, int depth)
{
	Intersection isect = Intersection(vec3(0), vec3(0), 0, Material(vec4(0), 0, 0, 0, 0), vec4(0));

	vec3 radiance = vec3(0.0);//累积的光照
	vec3 throughput = vec3(1.0);//brdf值

	vec3 dir = vec3(1.0);
	bool specularBounce = true;
	float brdfPdf = 1;

	for (int i = 0; i < depth; i++)
	{
		if (!List_hit(ray, EPS, INFINITY, isect))
		{
			float t = 0.5 * (ray.direction.y + 1.0);
			vec3 hdrColor =(1 - t) * vec3(1.0) + t * vec3(0.5f, 0.7f, 1);//getHdr(texture2D( hdrTexture, getuv(ray.d)));
			hdrColor = vec3(0.3);
			radiance += hdrColor * throughput;
			break;
		}

		
		Material mat = isect.mat;

		if (mat.emission > 0) {
			radiance += EmitterSample(i, specularBounce, brdfPdf, isect.emissive.w, isect.emissive.xyz) * throughput;
			break;
		}
		else if(mat.albedo.w < 1.0)
		{
			specularBounce = true;
            dir = GlassDir(isect.normal, 3, ray.direction).xyz;
            brdfPdf = 1.0;
            throughput *= mat.albedo.xyz;
        }
		else
		{
			specularBounce = false;
			
			radiance += directLight(ray, isect) * throughput;

			vec4 result = SampleDir(isect.normal, normalize(reflect(ray.direction, isect.normal)), mat.roughness, mat.metallic, vec2(randomVector.x+float(i),randomVector.y+float(i)));
			dir = result.xyz;
            int type = int(result.w);
			BsdfSampleRec brdf = BsdfSampleRec(vec3(0), 10);
            if(type == 0){
                brdf = brdf3_d(isect.normal, dir, -ray.direction, mat);
            }else if(type == 1){
                brdf = brdf3_s(isect.normal, dir, -ray.direction, mat);
            }
            throughput *= brdf.bsdfDir;
            brdfPdf = brdf.pdf;

			
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

	vec3 result = (texture(accumTexture, TexCoords).xyz * (sampleCounter - 1) + GetColor(ray, depth)) / sampleCounter;

	color = vec4(result, 1.0);
}