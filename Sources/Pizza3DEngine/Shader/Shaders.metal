//
//  Shaders.metal
//  MetalEngine
//
//  Created by Luca Pitzalis on 09/06/21.
//

#include <metal_stdlib>

using namespace metal;

struct Vertex{
    float3 pos;
    float4 color;
    float3 normal;
    float2 uv;
    float3 polyCentroid;
    int primitiveType;
};

struct VertexOut {
    float4 color;
    float4 pos [[position]];
    float3 worldNormal;
    float3 worldPosition;
    float3 worldPolyCentroid;
    float2 uv;
    int primitiveType;
};

struct Uniforms{
    float4x4 modelMatrix;
    float4x4 inverseModelMatrix;
    float4x4 projectionMatrix;
    float4x4 worldMatrix;
};

struct Light{
    float3 color;
    float3 worldPosition;
    float3 attenuation;
    float3 direction;
    float range;
    float coneAngle;
    int type;
    
    
};

struct Material{
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float shininess;
    int model;
};

struct FragmentUniforms{
    int numLights;
    float3 cameraPosition;
};

/*
 Lighting Models---------------------------------
 
 TABLE:
 
 0 = phong
 1 = lambert
 2 = constant
 */

float4 phongLighting(const VertexOut interpolated, constant FragmentUniforms &uniforms, constant Light *lights, const device Material &material){
    // AMBIENT
    //float3 ambient = gi.ambientColor*material.ambientColor;
    
    float3 totalAmbient = float3(0,0,0);
    float3 totalDiffuse = float3(0,0,0);
    float3 totalSpecular = float3(0,0,0);
    
    
    for(int i = 0; i<uniforms.numLights; i++){
        switch(lights[i].type){
                
            case 0: //AMBIENT
            {
                totalAmbient = lights[i].color*material.ambientColor;
                break;
            }
            case 1:
            {
                //POINT
                float dist = distance(lights[i].worldPosition, interpolated.worldPosition);
                
                float intensity = 1.0/(lights[i].attenuation.x +lights[i].attenuation.y*dist +lights[i].attenuation.z*(dist*dist));
                float3 norm = normalize(interpolated.worldNormal);
                float3 lightDir = normalize(interpolated.worldPosition-lights[i].worldPosition);
                float diff = saturate(-dot(norm, lightDir));
                float3 diffuse = diff*material.diffuseColor*lights[i].color*intensity;
                totalDiffuse += diffuse;
                if(diff > 0){
                    float3 eye = normalize(interpolated.worldPosition-uniforms.cameraPosition);
                    float3 reflectDir = reflect(lightDir, norm);
                    float spec = pow(saturate(dot(eye, reflectDir)), material.shininess);
                    float3 specular = spec * material.specularColor * lights[i].color * intensity;
                
                    totalSpecular += specular;
                }
                break;
            }
            case 2: //SPOT
            {
                float dist = distance(lights[i].worldPosition, interpolated.worldPosition);
                float3 lightDir = normalize(interpolated.worldPosition-lights[i].worldPosition);
                float3 coneDir = normalize(lights[i].direction);
                
                float spotResult = dot(coneDir, lightDir);
                if(spotResult > cos(lights[i].coneAngle)){
                    float intensity = 1.0/(lights[i].attenuation.x +lights[i].attenuation.y*dist +lights[i].attenuation.z*(dist*dist));
                    intensity = 1;
                    float3 norm = normalize(interpolated.worldNormal);

                    float diff = saturate(-dot(norm, lightDir));
                    float3 diffuse = diff*material.diffuseColor*lights[i].color*intensity;
                    totalDiffuse += diffuse;
                    if(diff > 0){
                        float3 eye = normalize(interpolated.worldPosition-uniforms.cameraPosition);
                        float3 reflectDir = reflect(lightDir, norm);
                        float spec = pow(saturate(dot(reflectDir, eye)), material.shininess);
                        float3 specular = spec * material.specularColor * lights[i].color * intensity;
                    
                        totalSpecular += specular;
                    }
                }
                
                break;
            }
            default: //3 SUN
                
                //float intensity = 1;
                float3 norm = normalize(interpolated.worldNormal);
                float3 lightDir = normalize(lights[i].direction);
                float diff = saturate(-dot(lightDir, norm));
                float3 diffuse = diff*material.diffuseColor*lights[i].color;
                totalDiffuse += diffuse;
                if(diff > 0){
                    float3 eye = normalize(interpolated.worldPosition-uniforms.cameraPosition);
                    float3 reflectDir = reflect(lightDir, norm);
                    float spec = pow(saturate(dot(reflectDir, eye)), material.shininess);
                    float3 specular = spec * material.specularColor * lights[i].color ;
                    totalSpecular += specular;
                }
                break;
        }
        
    }
    return float4((totalAmbient+totalDiffuse+totalSpecular) * interpolated.color.xyz, 1);

}

float4 constantLighting(const VertexOut interpolated, constant FragmentUniforms &uniforms, constant Light *lights, const device Material &material){

    
    float3 totalAmbient = float3(0,0,0);
    float3 totalDiffuse = material.diffuseColor;
    
    
    for(int i = 0; i<uniforms.numLights; i++){
        switch(lights[i].type){
                
            case 0: //AMBIENT
            {
                totalAmbient += lights[i].color*material.ambientColor;
                break;
            }
            default:
            {
                break;
            }
            
        }
        
    }
    return float4((totalAmbient) * totalDiffuse*interpolated.color.xyz, 1);
}

float4 lambertLighting(const VertexOut interpolated, constant FragmentUniforms &uniforms, constant Light *lights, const device Material &material){
    // AMBIENT
    float3 totalAmbient = float3(0,0,0);
    float3 totalDiffuse = float3(0,0,0);
    
    
    for(int i = 0; i<uniforms.numLights; i++){
        switch(lights[i].type){
                
            case 0: //AMBIENT
            {
                totalAmbient = lights[i].color*material.ambientColor;
                break;
            }
            case 1:
            {
                //POINT
                float dist = distance(lights[i].worldPosition, interpolated.worldPosition);
                
                float intensity = 1.0/(lights[i].attenuation.x +lights[i].attenuation.y*dist +lights[i].attenuation.z*(dist*dist));
                //float intensity = 1;
                float3 norm = normalize(interpolated.worldNormal);
                float3 lightDir = normalize(interpolated.worldPosition-lights[i].worldPosition);
                float diff = saturate(-dot(norm, lightDir));
                float3 diffuse = diff*material.diffuseColor*lights[i].color*intensity;
                totalDiffuse += diffuse;
                break;
            }
            case 2: //SPOT
            {
                float dist = distance(lights[i].worldPosition, interpolated.worldPosition);
                float3 lightDir = normalize(interpolated.worldPosition-lights[i].worldPosition);
                float3 coneDir = normalize(lights[i].direction);
                
                float spotResult = dot(coneDir, lightDir);
                if(spotResult > cos(lights[i].coneAngle)){
                    float intensity = 1.0/(lights[i].attenuation.x +lights[i].attenuation.y*dist +lights[i].attenuation.z*(dist*dist));
                    intensity = 1;
                    float3 norm = normalize(interpolated.worldNormal);
                    
                    float diff = saturate(-dot(norm, lightDir));
                    float3 diffuse = diff*material.diffuseColor*lights[i].color*intensity;
                    totalDiffuse += diffuse;
                    
                }
                
                break;
            }
            default: //3 SUN
                
                //float intensity = 1;
                float3 norm = normalize(interpolated.worldNormal);
                float3 lightDir = normalize(lights[i].direction);
                float diff = saturate(-dot(lightDir, norm));
                float3 diffuse = diff*material.diffuseColor*lights[i].color;
                totalDiffuse += diffuse;

                break;
        }
        
    }
    return float4((totalAmbient+totalDiffuse) * interpolated.color.xyz, 1);
    
}


float4 illuminate(const VertexOut interpolated, constant FragmentUniforms &uniforms, constant Light *lights, const device Material &material){
    
    switch(material.model){
        case 0:
            return phongLighting(interpolated, uniforms, lights, material);
        case 1:
            return lambertLighting(interpolated, uniforms, lights, material);
        case 2:
            return constantLighting(interpolated, uniforms, lights, material);
        default:
            return interpolated.color;
    }
    
    return float4(0,0,0,1);
}



//STANDARD SHADER:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


vertex VertexOut vertexShader(const device Vertex *vertexArray [[buffer(0)]],
                              const device Uniforms &uniforms [[buffer(1)]],
                              unsigned int vid [[vertex_id]])
{
    float4x4 mat = uniforms.modelMatrix;
    float4x4 p_mat = uniforms.projectionMatrix;
    Vertex in = vertexArray[vid];
    VertexOut out;
    
    //float3 off = (in.poly_centroid - in.pos) / 3;
    
    out.color = in.color;
    out.pos = p_mat*mat*float4(in.pos, 1);
    
    auto transp = transpose(uniforms.inverseModelMatrix);
    float3x3 normalMatrix = float3x3(transp.columns[0].xyz, transp.columns[1].xyz, transp.columns[2].xyz);
    
    out.worldNormal = normalMatrix * in.normal;
    
    
    
    out.primitiveType = in.primitiveType;
    out.worldPosition = (uniforms.worldMatrix*float4(in.pos,1)).xyz;
    out.worldPolyCentroid = (uniforms.worldMatrix*float4(in.polyCentroid,1)).xyz;
    out.uv = in.uv;
    
    //float off = distance(out.worldPolyCentroid,  out.worldPosition);

    return out;
}

constexpr sampler textureSampler;

fragment float4 fragmentShader(VertexOut interpolated [[stage_in]],
                               constant FragmentUniforms &uniforms [[buffer(4)]],
                               constant Light *lights [[buffer(5)]],
                               device Material &material [[buffer(3)]],
                               texture2d<float> ambient [[texture(0)]],
                               texture2d<float> diffuse [[texture(1)]],
                               texture2d<float> specular [[texture(2)]])
{
    
    float4 finalColor = interpolated.color;
    if (interpolated.primitiveType == 0){
        
        material.ambientColor = ambient.sample(textureSampler, interpolated.uv).xyz;
        material.diffuseColor = diffuse.sample(textureSampler, interpolated.uv).xyz;
        material.specularColor = specular.sample(textureSampler, interpolated.uv).xyz;
        
        
        finalColor = illuminate(interpolated, uniforms, lights, material);
    }
    //float off = distance(interpolated.worldPolyCentroid,  interpolated.worldPosition);
    
    //finalColor.w = interpolated.color.w;
    
    return finalColor;
    
    
}




//PICKING::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

vertex VertexOut pickVertexShader(const device Vertex *vertexArray [[buffer(0)]],
                                  const device Uniforms &uniforms [[buffer(1)]],
                                  const device int &identifier [[buffer(2)]],
                                  unsigned int vid [[vertex_id]])
{
    float4x4 mat = uniforms.modelMatrix;
    float4x4 p_mat = uniforms.projectionMatrix;
    Vertex in = vertexArray[vid];
    VertexOut out;
    
    out.color.r = in.pos.x;
    out.color.g = in.pos.y;
    out.color.b = in.pos.z;
    out.color.a = identifier;
    out.pos = p_mat*mat*float4(in.pos, 1);
    
    return out;
}

fragment float4 pickFragmentShader(VertexOut interpolated [[stage_in]])
{

    return interpolated.color;
}






