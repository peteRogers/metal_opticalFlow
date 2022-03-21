// MyKernels.ci.metal
#include <CoreImage/CoreImage.h> // includes CIKernelMetalLib.h
using namespace metal;

extern "C" {
    
    namespace coreimage {
        
    #define pi 3.14
        
        
        float2 rot(float2 p, float a) {
            return p*float2x2(sin(a),cos(a),-cos(a),sin(a));
        }

        float3 rott(float3 p, float2 a) {
            float3 rp = p;
            rp.yz = rot(rp.yz,a.y);
            rp.xz = rot(rp.xz,a.x);
            return rp;
        }
        
        
        float4 skyShader(float width, float height, float sunDiameter, float albedo, float sunAzimuth,  float sunAlitude, float skyDarkness, float scattering, destination dest)
        {
            
            
//            width = 600;
//            height = 600;
//            sunDiameter = 0.1;
//            albedo = 0.5;
//            skyDarkness = 0.5;
//            //sunAzimuth = 0.5;
//            sunAlitude = 8;
            float x = (dest.coord().x / width) - 0.5;
            float y = (dest.coord().y / height) - 0.5;

            float3 rd = normalize(float3(x, y, 1.0));
            
           
            rd = rott(rd, float2(0.0, pi / 2.5));
            
            float3 sunDirection;

            sunDirection = normalize(float3(sunAlitude, 0.5, sunAzimuth));

            float sun = max(1.0 - (1.0 + scattering * max(0.0, sunDirection.y) + 1.0 * rd.y) * max(0.0, length(rd - sunDirection) - sunDiameter),0.0)
                + albedo * pow(1.0 - rd.y, 12.0) * (1.6-max(0.,sunDirection.y));

            float4 pixelColor = float4(mix(float3(0.3984,0.5117,0.7305), float3(0.7031,0.4687,0.1055), sun)
                      * ((0.5 + 1.0 * pow(max(0.,sunDirection.y),0.4)) * (skyDarkness - abs(sunDirection.y))+ pow(sun, 5.2)
                      * max(0.0,sunDirection.y) * (5.0 + 15.0 * max(0.,sunDirection.y))),1.0);

            pixelColor = mix(pixelColor,
                            float4(.0),
                            clamp((-rd.y+.01) * 100.0, 0.0, 1.0));
            
            return float4(pixelColor.rgb, 1.0);
        }

    
      
    }
     
    
}
