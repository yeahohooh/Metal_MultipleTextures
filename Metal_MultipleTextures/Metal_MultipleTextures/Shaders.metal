//
//  Shaders.metal
//  Metal_manyTexture
//
//  Created by 李博 on 2021/6/29.
//

#include <metal_stdlib>
#import "ShaderTypes.h"
using namespace metal;

typedef struct
{
    float4 clipSpacePosition [[position]];
    float2 textureCoordinate;
}RasterizerData;

vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                                   constant Vertex *vertexArray [[buffer(0)]],
                                   constant vector_uint2 *viewportSize [[buffer(1)]]) {
    RasterizerData out;
    out.clipSpacePosition = vector_float4(0.0, 0.0, 0.0, 1.0);
    
    float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
    vector_float2 viewSize = vector_float2(*viewportSize);
    
    out.clipSpacePosition.xy = pixelSpacePosition / (viewSize / 2.0); // 坐标转换
    out.clipSpacePosition.z = 0.0f;
    out.clipSpacePosition.w = 1.0f;
    
    out.textureCoordinate = vertexArray[vertexID].texture;
    
    return out;
}

fragment half4 fragmentShader(RasterizerData in [[stage_in]],
                               texture2d<half> colorTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    const half4 colorSampler = colorTexture.sample(textureSampler, in.textureCoordinate);
    
    return colorSampler;
}
