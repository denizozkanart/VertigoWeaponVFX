Shader "URP/Custom/WindFlow"
{
    Properties
    {
        _MainTex("Flow Texture", 2D) = "white" {}
        _NoiseTex("Noise Mask", 2D) = "gray" {}
        _Color("Tint", Color) = (1, 0.84, 0.3, 1)
        _FlowDirection("Flow Direction", Vector) = (1, 0, 0, 0)
        _FlowSpeed("Flow Speed", Float) = 0.6
        _Distortion("Distortion", Float) = 0.1
        _Intensity("Intensity", Float) = 2.5
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100
        Blend One One
        ZWrite Off
        Cull Back

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _NoiseTex_ST;
                float4 _Color;
                float4 _FlowDirection;
                float _FlowSpeed;
                float _Distortion;
                float _Intensity;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            Varyings vert(Attributes input)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                o.uv = TRANSFORM_TEX(input.uv, _MainTex);
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float time = _Time.y * _FlowSpeed;
                float2 flowDir = normalize(_FlowDirection.xy + float2(1e-5, 0));

                float2 uvMain = i.uv + flowDir * time;
                float2 uvNoise = TRANSFORM_TEX(i.uv, _NoiseTex) - flowDir * time * 0.5;

                float noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvNoise).r;
                float2 distortion = (noise - 0.5) * _Distortion;
                uvMain += distortion;

                float3 mainSample = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvMain).rgb;
                float mask = saturate(mainSample.r * 0.7 + noise);

                float3 color = _Color.rgb * mask * _Intensity;
                float alpha = mask * _Color.a;

                return float4(color, alpha);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
