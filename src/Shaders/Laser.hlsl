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
float hash(float2 p)
{
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5454);
}
//--------------------------------------------------------------------------------------
float noise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
   
    float a = hash(i);
    float b = hash(i + float2(1, 0));
    float c = hash(i + float2(0, 1));
    float d = hash(i + float2(1, 1));
    
    float2 u = f * f * (3.0 - 2.0 * f);
    
    return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
//--------------------------------------------------------------------------------------
// Improved beam function with better distance calculation
float getBeam(float2 p, float angle, float thickness)
{
    float a = atan2(p.y, p.x);
    float d = abs(a - angle);

    const float TWO_PI = 6.28318530718;

    // Wrap angle difference to shortest path
    d = min(d, TWO_PI - d);

    // Smooth step for soft beam edges
    return smoothstep(thickness, 0.0, d);
}
//--------------------------------------------------------------------------------------
// Glow function with configurable falloff
float calculateGlow(float distance, float glowIntensity, float falloffPower)
{
    // Use power function for more natural glow falloff
    return exp(-distance * falloffPower) * glowIntensity;
}
//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
PS_OUTPUT ps_main(PS_INPUT input)
{
    // Use beat information if available, otherwise use time
    float time = g_FX_Beats_on ? g_FX_SongPosBeats : g_FX_Time;
    
    //--- Shader Parameters ---
    int beamCount = 24;           // Number of laser beams
    float spread = 3.14;               // Angular spread (radians)
    float thickness = 0.01;           // Base beam thickness
    float glowIntensity = 4.0;        // Glow intensity
    float glowFalloff = 2.0;          // Glow falloff power (higher = sharper)
    float Speed = 0.5;        // Rotation speed factor
    float thicknessPulse = 0.003;     // Beat-based thickness variation
    float noiseAmount = 0.01;
    
    if (beamCount <= 1) beamCount = 2;

    //--- Texture Coordinates ---
    float2 texcoord = input.TexCoord;
    float2 origin = float2(0.5f, 0.5f);
    float2 p = texcoord - origin;
    float dist = length(p);

    // Rotate coordinates for animation
    p = float2(-p.y, p.x);
    
    // Smoke
    //float n = noise(p * 3.0 + time * Speed);
    //p += (n - 0.5) * noiseAmount;
    
    //--- Beat Reactivity ---
    // Calculate beat intensity (0 to 1)
    float beatPhase = frac(time);
    float beatIntensity = smoothstep(0.8, 0.0, beatPhase); // Sharp attack, slow decay
    
    // Modulate thickness based on beats
    float pulsingThickness = thickness + (thicknessPulse * beatIntensity);
    
    // Modulate glow based on beats
    float pulsingGlow = glowIntensity * (1.0 + 0.5 * beatIntensity);
    
    //--- Beam Rotation Animation ---
    float rotation = 0; // time * Speed;
    
    //--- Accumulate Beam Colors ---
    float3 col = float3(0.0, 0.0, 0.0);

    float idxf = 0.0f;
    float angle = 0.0f;
    float beam = 0.0f;
    float glow = 0.0f;
    float intensity = 0.0f;
    float3 beamColor = float3(0.0, 1.0, 0.0);

    for (int i = 0; i < beamCount; i++)
    {
        idxf = (float)i / (beamCount - 1);
        
        // Apply rotation to spread
        angle = lerp(-spread * 0.5, spread * 0.5, idxf) + rotation;
        
        // Calculate beam contribution
        beam = getBeam(p, angle, pulsingThickness);
        
        glow = exp(-dist * glowFalloff) * pulsingGlow;

        
        // Combine beam and glow
        intensity = beam * glow;
        
        // Accumulate color
        col += intensity * beamColor;
    }
    
    // Strong central core (white-hot)
    float core = exp(- dist * 20.0);
    col += core * float3(0.3, 1.0, 0.2) * 1.0;
    
    
    // volumetric fog
    float fog = noise(texcoord * 2.0 * time * 0.2);
    float fogMask = smoothstep(0.2, 1.0, fog);
    col += fogMask * 0.2;
    
    
    // fade to black background
    float intensity2 = max(col.r, max(col.g, col.b));
    col *= smoothstep(0.01, 0.1, intensity2);
    

    // Final output with input color modulation
    float4 color = float4(col, 1.0);
    PS_OUTPUT output;
    output.Color = color * input.Color;
    return output;
}