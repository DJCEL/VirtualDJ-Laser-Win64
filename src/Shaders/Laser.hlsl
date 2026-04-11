////////////////////////////////
// File: Laser.hlsl
////////////////////////////////

//--------------------------------------------------------------------------------------
// Textures and Samplers
//--------------------------------------------------------------------------------------
Texture2D g_Texture2D : register(t0);
SamplerState g_SamplerState : register(s0);
//--------------------------------------------------------------------------------------
// Constant Buffer
//--------------------------------------------------------------------------------------
cbuffer PS_CONSTANTBUFFER : register(b0)
{
    float g_FX_Time;
    float g_FX_SongPosBeats;
    float g_FX_Width;
    float g_FX_Height;
    float g_FX_Beats_on;
};
//--------------------------------------------------------------------------------------
// Input structure
//--------------------------------------------------------------------------------------
struct PS_INPUT
{
	float4 Position : SV_Position;
	float4 Color : COLOR0;
	float2 TexCoord : TEXCOORD0;
};
//--------------------------------------------------------------------------------------
// Output structure
//--------------------------------------------------------------------------------------
struct PS_OUTPUT
{
    float4 Color : SV_TARGET;
};
//--------------------------------------------------------------------------------------
// Additional Functions
//--------------------------------------------------------------------------------------
float beam(float2 texcoord, float angle, float thickness)
{
    float a = atan2(texcoord.y, texcoord.x);
    float d = abs(a - angle);

    // wrap angle
    d = min(d, 6.28318 - d);

    return smoothstep(thickness, 0.0, d);
}
//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
PS_OUTPUT ps_main(PS_INPUT input)
{
    float iTime = g_FX_Time;
    float iBeat = g_FX_SongPosBeats;
    float time = g_FX_Beats_on ? g_FX_SongPosBeats : g_FX_Time;
        
    float beamCount = 12; // number of lasers
    float spread = 1.5; // angular spread (radians)
    float thickness = 0.01; // beam thickness [0.01-0.03]
    float glow = 3.0; // glow intensity [2.0-5.0]
    float noiseAmount = 0.02; // distortion [0.02-0.08]
    float3 colorLaser = float3(0.0, 1.0, 0.0); // green laser
   
    float2 texcoord = input.TexCoord;

    float2 origin = float2(0.5f, 0.5f);
    float2 texcoord2 = texcoord - origin;
    float dist = length(texcoord2);

    texcoord2 = float2(-texcoord2.y, texcoord2.x);
    
    float3 col = 0;
    float t = 0;
    float angle = 0;
    float b = 0;
    float g = 0;
    float intensity = 0;
   
    for (int i = 0; i < beamCount; i++)
    {
        t = (float) i / (beamCount - 1);
        angle = lerp(-spread * 0.5, spread * 0.5, t);
        b = beam(texcoord2, angle, thickness);
        g = exp(-dist * 2.0) * glow;
        intensity = b * g;
        col += intensity * colorLaser;
    }

    float4 color = float4(col, 1.0);
    
    PS_OUTPUT output;
    output.Color = color * input.Color;
    return output;
}
