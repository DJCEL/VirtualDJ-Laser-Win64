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
// Improved beam function with better distance calculation
float beam(float2 texcoord, float angle, float thickness)
{
    float a = atan2(texcoord.y, texcoord.x);
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
// Beat-reactive color based on intensity
float3 getBeatColor(float beatIntensity, float hueShift)
{
    // Create color variation based on beat - oscillates between green and cyan
    float3 colorBase = float3(0.0, 1.0, 0.5 + 0.5 * sin(hueShift));
    return colorBase * (0.7 + 0.3 * beatIntensity);
}
//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
PS_OUTPUT ps_main(PS_INPUT input)
{
    // Use beat information if available, otherwise use time
    float time = g_FX_Beats_on ? g_FX_SongPosBeats : g_FX_Time;
    
    //--- Shader Parameters ---
    float beamCount = 12.0;           // Number of laser beams
    float spread = 1.5;               // Angular spread (radians)
    float thickness = 0.01;           // Base beam thickness
    float glowIntensity = 3.0;        // Glow intensity
    float glowFalloff = 2.0;          // Glow falloff power (higher = sharper)
    float rotationSpeed = 0.5;        // Rotation speed factor
    float thicknessPulse = 0.003;     // Beat-based thickness variation
    
    if (beamCount <= 1) beamCount=2;

    //--- Texture Coordinates ---
    float2 texcoord = input.TexCoord;
    float2 origin = float2(0.5f, 0.5f);
    float2 texcoord2 = texcoord - origin;
    float dist = length(texcoord2);

    // Rotate coordinates for animation
    texcoord2 = float2(-texcoord2.y, texcoord2.x);
    
    //--- Beat Reactivity ---
    // Calculate beat intensity (0 to 1)
    float beatPhase = frac(time);
    float beatIntensity = smoothstep(0.8, 0.0, beatPhase); // Sharp attack, slow decay
    
    // Modulate thickness based on beats
    float pulsingThickness = thickness + (thicknessPulse * beatIntensity);
    
    // Modulate glow based on beats
    float pulsingGlow = glowIntensity * (1.0 + 0.5 * beatIntensity);
    
    //--- Beam Rotation Animation ---
    float rotation = time * rotationSpeed;
    
    //--- Accumulate Beam Colors ---
    float3 col = float3(0.0, 0.0, 0.0);

    
    
    for (int i = 0; i < beamCount; i++)
    {
        float t = (float)i / (beamCount - 1.0);
        
        // Apply rotation to spread
        float angle = lerp(-spread * 0.5, spread * 0.5, t) + rotation;
        
        // Calculate beam contribution
        float b = beam(texcoord2, angle, pulsingThickness);
        
        // Calculate glow with improved falloff
        float g = calculateGlow(dist, pulsingGlow, glowFalloff);
        
        // Combine beam and glow
        float intensity = b * g;
        
        // Get beat-reactive color with hue variation based on beam index
        float3 beamColor = getBeatColor(beatIntensity, float(i) * 0.5 + rotation);
        
        // Accumulate color
        col += intensity * beamColor;
    }

    // Final output with input color modulation
    float4 color = float4(col, 1.0);
    PS_OUTPUT output;
    output.Color = color * input.Color;
    return output;
}