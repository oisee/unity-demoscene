Shader "Raymarching/Sandwich"
{

Properties
{
    [Header(GBuffer)]
    _Diffuse("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
    _Specular("Specular", Color) = (0.0, 0.0, 0.0, 0.0)
    _Emission("Emission", Color) = (0.0, 0.0, 0.0, 0.0)

    [Header(Raymarching Settings)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowLoop("Shadow Loop", Range(1, 100)) = 10
    _ShadowMinDistance("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowExtraBias("Shadow Extra Bias", Range(0.0, 1.0)) = 0.01

// @block Properties
[HDR] _SlideEmission("Slide Emission", Color) = (2.0, 2.0, 5.0, 1.0)
// @endblock
}

SubShader
{

Tags
{
    "RenderType" = "Opaque"
    "DisableBatching" = "True"
}

Cull Off

CGINCLUDE

#define WORLD_SPACE

#define DISTANCE_FUNCTION DistanceFunction
#define POST_EFFECT PostEffect
#define PostEffectOutput GBufferOut

#include "Assets/uRaymarching/Shaders/Include/Common.cginc"
#include "Assets/Demoscene/Shaders/Includes/Common.cginc"

// @block DistanceFunction
float _LocalTime;

float dFloor(float3 pos)
{
    float3 p = pos;
    p.xz = Repeat(p.xz, 1);
    float w = 0.4;
    return sdBox(p, float3(w, w, w));
}

inline float DistanceFunction(float3 pos)
{
    float height = 4;
    pos.y += 0.1 * sin(PI * _LocalTime + 5.0 * Rand(floor(pos.xz)));
    float d = dFloor(pos - float3(0, -height, 0));
    d = min(d, dFloor(pos - float3(0, height, 0)));
    return d;
}
// @endblock

// @block PostEffect
float4 _SlideEmission;

inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
    float width = 0.2;
    float byPosY = frac(4 * abs(ray.endPos.y) + 1.0 / 16 * _LocalTime);
    byPosY = step(byPosY, width);

    float byTime = abs(sin(PI * 1.0 / 4 * _LocalTime));
    float intensity = byPosY * byTime;

    o.emission = _SlideEmission * intensity;
}
// @endblock

#include "Assets/uRaymarching/Shaders/Include/Raymarching.cginc"

ENDCG

Pass
{
    Tags { "LightMode" = "Deferred" }

    Stencil
    {
        Comp Always
        Pass Replace
        Ref 128
    }

    CGPROGRAM
    #include "Assets/uRaymarching/Shaders/Include/VertFragDirectScreen.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma exclude_renderers nomrt
    #pragma multi_compile_prepassfinal
    #pragma multi_compile ___ UNITY_HDR_ON
    #pragma multi_compile OBJECT_SHAPE_CUBE OBJECT_SHAPE_SPHERE ___
    ENDCG
}

Pass
{
    Tags { "LightMode" = "ShadowCaster" }

    CGPROGRAM
    #include "Assets/uRaymarching/Shaders/Include/VertFragShadowObject.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma fragmentoption ARB_precision_hint_fastest
    #pragma multi_compile_shadowcaster
    #pragma multi_compile OBJECT_SHAPE_CUBE OBJECT_SHAPE_SPHERE ___
    ENDCG
}

}

Fallback "Diffuse"

CustomEditor "uShaderTemplate.MaterialEditor"

}
