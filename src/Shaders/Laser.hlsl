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
float hash(float n)
{
    return frac(sin(n) * 43758.5453123);
}
//--------------------------------------------------------------------------------------
float beatPulse(float beat)
{
    float adjustCoeff = 25.0; // or 20.0 or 30.0
    
    const float PI = 3.14159265;
    float pulse = pow(max(0.0, sin(beat * PI)), adjustCoeff);
    
    return pulse;
}
//--------------------------------------------------------------------------------------
float4 Laser_Club_v1(float2 texcoord, float time, float beat)
{
    float2 uv = texcoord;
    float2 center = float2(0.5f, 0.5f);
    float2 p = uv - center;
    
    // ultra sharp flash
    float pulse = beatPulse(beat);
    
    // glow burst (simulate a light explosition from the center)
    float dist = length(p);
    float burst = exp(-dist * 8.0);
    
    // rotating beams (creates rotating club-style rays)
    float angle = atan2(p.y, p.x);
    float beams = sin(angle * 16.0 + time * 8.0);
    beams = pow(abs(beams), 6.0);


    // we combine pulse, burst and beams
    float flash = pulse * 1.5 + burst * pulse * 2.5 + beams * pulse * 1.5;
    float3 col = float3(flash, flash, flash);
    
    // distorsion during flash
    float2 distort = p * (1.0 + pulse * 0.3);
    float distorsion = length(distort);
    col.r += pulse * 0.2 * distorsion;
    col.b -= pulse * 0.2 * distorsion;
    
    // flicker boost
    float flicker = hash(floor(time * 40.0));
    col *= 1.0 + flicker * 0.2 * pulse;
    
    float4 color = float4(col.r, col.g, col.b, 1.0);
    
    // green
    color *= float4(0.0, 1.0, 0.0, 1.0f);
    
    return color;
}
//--------------------------------------------------------------------------------------
float4 Laser_Club_v2(float2 texcoord, float time, float beat)
{
    float2 uv = texcoord;
    float2 center = float2(0.5f, 0.5f);
    float2 p = uv - center;
    
    float pulse = beatPulse(beat);

    float dist = length(p);
    float angle = atan2(p.y, p.x);

    angle += sin(time * 0.8) * 0.4;

    float beamCount = lerp(12.0, 40.0, pulse);

    float beam = abs(sin(angle * beamCount + time * 5.0));
    beam = smoothstep(0.985, 1.0, beam);

    float glow = exp(-dist * 10.0);

    float beams = beam * 2.0 + glow * 0.6;

    float fog = exp(-dist * 3.5);
    beams *= fog;

    float flicker = hash(floor(time * 90.0));
    beams *= 1.0 + flicker * 0.15 * pulse;

    float3 col = beams * float3(0.1, 1.4, 0.2);
    
    float4 color = float4(col.r, col.g, col.b, 1.0);
    
    // green
    color *= float4(0.0, 1.0, 0.0, 1.0f);
    
    return color;
}
//--------------------------------------------------------------------------------------
float4 Laser_Club_v2_1(float2 texcoord, float time, float beat)
{
    float3 color_laser = float3(0.1, 1.4, 0.2);
    float beamCount = 12;
    
    float2 uv = texcoord;
    float2 center = float2(0.5f, 0.5f);
    float2 p = uv - center;
    
    float angle = atan2(p.y, p.x);
    float beams = abs(sin(angle * beamCount));
    beams = smoothstep(0.985, 1.0, beams);

    float3 col = color_laser * beams;
    
    float4 color = float4(col,1.0);
    
    return color;
}
//--------------------------------------------------------------------------------------
float4 Laser_Club_v3(float2 texcoord, float time, float beat)
{
    float2 uv = texcoord;
    float2 center = float2(0.5, 0.5);

    float pulse = beatPulse(beat);

    //----------------------------------
    // Up / Down sweep motion
    //----------------------------------

    float sweepSlow = sin(time * 1.5) * 0.35;
    float sweepFast = sin(time * 6.0) * 0.05;

    float2 p = uv - center;
    p.y += sweepSlow + sweepFast * pulse;

    //----------------------------------
    // Polar coordinates
    //----------------------------------

    float dist = length(p);
    float angle = atan2(p.y, p.x);

    //----------------------------------
    // Scanner rotation
    //----------------------------------

    angle += sin(time * 0.8) * 0.5;

    //----------------------------------
    // Beam count changes on beat
    //----------------------------------

    float beamCount = lerp(12.0, 40.0, pulse);

    //----------------------------------
    // Main laser beams
    //----------------------------------

    float beam = abs(sin(angle * beamCount + time * 5.0));
    beam = smoothstep(0.985, 1.0, beam);

    //----------------------------------
    // Additional layered beams
    //----------------------------------

    float beam2 = abs(sin(angle * 18.0 - time * 4.0));
    beam2 = smoothstep(0.98, 1.0, beam2);

    float beams = beam * 2.0 + beam2 * 1.2;

    //----------------------------------
    // Laser glow
    //----------------------------------

    float glow = exp(-dist * 10.0);
    beams += glow * 0.6;

    //----------------------------------
    // Fog falloff
    //----------------------------------

    float fog = exp(-dist * 3.5);
    beams *= fog;

    //----------------------------------
    // Random flicker
    //----------------------------------

    float flicker = hash(floor(time * 90.0));
    beams *= 1.0 + flicker * 0.15 * pulse;

    //----------------------------------
    // Laser color
    //----------------------------------

    float3 laserGreen = float3(0.1, 1.4, 0.2);

    float3 col = beams * laserGreen;

    return float4(col, 1.0);
}
//--------------------------------------------------------------------------------------
float4 Laser_Club_v4(float2 texcoord, float time, float beat)
{
    float2 uv = texcoord;
    float2 center = float2(0.5, 0.5);

    float2 p = uv - center;

    float pulse = beatPulse(beat);

    float dist = length(p);
    float angle = atan2(p.y, p.x);

    //----------------------------------
    // VERTICAL LASER SWEEP (center fixed)
    //----------------------------------

    float verticalSweep = sin(time * 1.5) * 1.2;
    angle += verticalSweep;

    //----------------------------------
    // additional fast jitter
    //----------------------------------

    angle += sin(time * 6.0) * 0.2 * pulse;

    //----------------------------------
    // Beam density changes with beat
    //----------------------------------

    float beamCount = lerp(16.0, 40.0, pulse);

    //----------------------------------
    // Laser beams
    //----------------------------------

    float beam = abs(sin(angle * beamCount));
    beam = smoothstep(0.985, 1.0, beam);

    //----------------------------------
    // Secondary beams
    //----------------------------------

    float beam2 = abs(sin(angle * 18.0 - time * 4.0));
    beam2 = smoothstep(0.98, 1.0, beam2);

    float beams = beam * 2.0 + beam2 * 1.2;

    //----------------------------------
    // Glow
    //----------------------------------

    float glow = exp(-dist * 10.0);
    beams += glow * 0.5;

    //----------------------------------
    // Fog attenuation
    //----------------------------------

    float fog = exp(-dist * 3.5);
    beams *= fog;

    //----------------------------------
    // Flicker
    //----------------------------------

    float flicker = hash(floor(time * 90.0));
    beams *= 1.0 + flicker * 0.15 * pulse;

    //----------------------------------
    // Laser color
    //----------------------------------

    float3 laserGreen = float3(0.1, 1.4, 0.2);

    float3 col = beams * laserGreen;

    return float4(col, 1.0);
}
//--------------------------------------------------------------------------------------
float4 Laser_Club_v5(float2 texcoord, float time, float beat)
{
    float2 center = float2(0.5, 0.5);
    float2 p = texcoord - center;

    float dist = length(p);

    // base polar angle
    float angle = atan2(p.y, p.x);

    //--------------------------------
    // LASER FAN SWEEP (global rotation)
    //--------------------------------

    float sweep = sin(time * 1.5) * 1.0;
    angle += sweep;

    //--------------------------------
    // beam density
    //--------------------------------

    float pulse = beatPulse(beat);
    float beamCount = 24.0;

    //--------------------------------
    // thin beams
    //--------------------------------

    float beam = abs(sin(angle * beamCount));
    beam = smoothstep(0.985, 1.0, beam);

    //--------------------------------
    // glow
    //--------------------------------

    float glow = exp(-dist * 8.0);

    float intensity = beam * 2.0 + glow * 0.5;

    //--------------------------------
    // fog falloff
    //--------------------------------

    intensity *= exp(-dist * 3.0);

    //--------------------------------
    // flicker
    //--------------------------------

    float flicker = hash(floor(time * 80.0));
    intensity *= 1.0 + flicker * 0.1;

    //--------------------------------
    // green laser
    //--------------------------------

    float3 laserColor = float3(0.0, 1.2, 0.1);

    float3 col = intensity * laserColor;

    return float4(col, 1.0);
}
//--------------------------------------------------------------------------------------
float4 Laser_Club_v6(float2 texcoord, float time, float beat)
{
    float2 center = float2(0.5, 0.5);
    float2 p = texcoord - center;

    float pulse = beatPulse(beat);

    //--------------------------------
    // SPLIT vertical motion
    //--------------------------------

    float sweep = sin(time * 1.8) * 0.5;

    if (texcoord.y > 0.5)
        p.y += abs(sweep); // top moves toward center
    else
        p.y -= abs(sweep); // bottom moves toward center

    //--------------------------------
    // polar coordinates
    //--------------------------------

    float dist = length(p);
    float angle = atan2(p.y, p.x);

    //--------------------------------
    // beam count
    //--------------------------------

    float beamCount = 28.0;

    //--------------------------------
    // thin laser beams
    //--------------------------------

    float beam = abs(sin(angle * beamCount));
    beam = smoothstep(0.985, 1.0, beam);

    //--------------------------------
    // glow
    //--------------------------------

    float glow = exp(-dist * 9.0);

    float intensity = beam * 2.0 + glow * 0.5;

    //--------------------------------
    // fog attenuation
    //--------------------------------

    intensity *= exp(-dist * 3.0);

    //--------------------------------
    // flicker
    //--------------------------------

    float flicker = hash(floor(time * 80.0));
    intensity *= 1.0 + flicker * 0.15 * pulse;

    //--------------------------------
    // laser color
    //--------------------------------

    float3 laserGreen = float3(0.0, 1.3, 0.15);

    float3 col = intensity * laserGreen;

    return float4(col, 1.0);
}
//--------------------------------------------------------------------------------------
float4 Laser_Club_v7(float2 uv, float time, float beat)
{
    float2 center = float2(0.5, 0.5);
    float2 p = uv - center;

    float dist = length(p);

    // Base polar angle
    float angle = atan2(p.y, p.x);

    //--------------------------------
    // clean vertical scanner
    //--------------------------------

    float sweep = sin(time * 1.5) * 0.9;

    float signHalf = (uv.y > 0.5) ? -1.0 : 1.0;
    angle += sweep * signHalf;

    //--------------------------------
    // beam generation
    //--------------------------------

    float beamCount = 28.0;

    float beam = abs(sin(angle * beamCount));
    beam = smoothstep(0.985, 1.0, beam);

    //--------------------------------
    // glow
    //--------------------------------

    float glow = exp(-dist * 8.0);

    float intensity = beam * 2.0 + glow * 0.6;

    //--------------------------------
    // fog
    //--------------------------------

    intensity *= exp(-dist * 3.0);

    //--------------------------------
    // beat flicker
    //--------------------------------

    float pulse = beatPulse(beat);
    float flicker = hash(floor(time * 90.0));

    intensity *= 1.0 + flicker * 0.1 * pulse;

    //--------------------------------
    // laser green
    //--------------------------------

    float3 laserGreen = float3(0.05, 1.3, 0.1);

    float3 col = intensity * laserGreen;

    return float4(col, 1.0);
}
//--------------------------------------------------------------------------------------
float4 Laser_Club_v8(float2 uv, float time, float beat)
{
    float2 center = float2(0.5, 0.5);
    float2 p = uv - center;

    float dist = length(p);
    float angle = atan2(p.y, p.x);

    //--------------------------------
    // VERTICAL LASER MOTION
    //--------------------------------

    float sweep = sin(time * 1.5) * 2.0;

    float signHalf = (uv.y > 0.5) ? -1.0 : 1.0;

    float verticalOffset = sweep * signHalf;

    //--------------------------------
    // laser beams
    //--------------------------------

    float beamCount = 28.0;

    float beam = abs(sin(angle * beamCount + verticalOffset));
    beam = smoothstep(0.985, 1.0, beam);

    //--------------------------------
    // glow
    //--------------------------------

    float glow = exp(-dist * 8.0);

    float intensity = beam * 2.0 + glow * 0.5;

    //--------------------------------
    // fog
    //--------------------------------

    intensity *= exp(-dist * 3.0);

    //--------------------------------
    // flicker
    //--------------------------------

    float pulse = beatPulse(beat);
    float flicker = hash(floor(time * 90.0));

    intensity *= 1.0 + flicker * 0.1 * pulse;

    //--------------------------------
    // laser green
    //--------------------------------

    float3 laserGreen = float3(0.05, 1.3, 0.1);

    float3 col = intensity * laserGreen;

    return float4(col, 1.0);
}

//--------------------------------------------------------------------------------------
float4 Laser_RaveTunnel(float2 texcoord, float time)
{
    float2 uv = texcoord;
    float2 center = float2(0.5f, 0.5f);
    float2 p = uv - center;
    
    float dist = length(p);
    float angle = atan2(p.y, p.x);
    
    float pattern = sin(dist * 20.0 - time * 6.0 + angle * 5.0);
    
    float v = abs(pattern);
    
    float4 color = float4(v, v, v, 1.0);
    
    // green
    color *= float4(0.0, 1.0, 0.0, 1.0f);
    
    return color;
}
//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
PS_OUTPUT ps_main(PS_INPUT input)
{
    float iTime = g_FX_Time;
    float iBeat = g_FX_SongPosBeats;
   
    float2 texcoord = input.TexCoord;
    float4 color = float4(0, 0, 0, 0);
    
    //color = Laser_Club_v1(texcoord, iTime, iBeat);
    //color = Laser_Club_v2(texcoord, iTime, iBeat);
    color = Laser_Club_v2_1(texcoord, iTime, iBeat);
    //color = Laser_Club_v3(texcoord, iTime, iBeat);
    //color = Laser_Club_v4(texcoord, iTime, iBeat);
    //color = Laser_Club_v5(texcoord, iTime, iBeat);
    //color = Laser_Club_v6(texcoord, iTime, iBeat);
    //color = Laser_Club_v7(texcoord, iTime, iBeat);
    //color = Laser_Club_v8(texcoord, iTime, iBeat);
    
    //color = Laser_RaveTunnel(texcoord, iTime);


    PS_OUTPUT output;
    output.Color = color * input.Color;
    return output;
}
