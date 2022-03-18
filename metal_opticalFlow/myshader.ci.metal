// MyKernels.ci.metal
#include <CoreImage/CoreImage.h> // includes CIKernelMetalLib.h
using namespace metal;

extern "C" {
    namespace coreimage {
        float4 HDRZebra (sampler image, float minLen, float maxLen, float size, float tipAngle){
       // float4 HDRZebra (sampler image){
            //return s.sample(s.coord());
            float4 s = image.sample(image.coord());
            float2 vector = s.rg - 0.5;
            float len = length(vector);
            float H = atan2(vector.y, vector.x);
            H *= 3.0/3.1415926;
            float i = floor(H);
            float f = H-i;
            float a = f;
            float d = 1.0 - a;
            float4 c;
            if (H<-3.0) c = float4(0, 1, 1, 1);
            else if (H<-2.0) c = float4(0, d, 1, 1);
                else if (H<-1.0) c = float4(a, 0, 1, 1);
                else if (H<0.0)  c = float4(1, 0, d, 1);
                else if (H<1.0)  c = float4(1, a, 0, 1);
                else if (H<2.0)  c = float4(d, 1, 0, 1);
                else if (H<3.0)  c = float4(0, 1, a, 1);
                else             c = float4(0, 1, 1, 1);
            c.rgb *= clamp((len-minLen)/(maxLen-minLen), 0.0,1.0);
            float tipAngleRadians = tipAngle * 3.1415/180.0;
            float2 dc = image.coord(); // current coordinate
            float2 dcm = floor((dc/size)+0.5)*size; // cell center coordinate
            float2 delta = dcm - dc; // coordinate relative to center of cell
                // sample the .xy vector from the center of each cell
                float4 sm = sample(image, samplerTransform(image, dcm));
                vector = sm.rg - 0.5;
                len = length(vector);
                H = atan2(vector.y,vector.x);
                float rotx, k, sideOffset, sideAngle;
                // these are the three sides of the arrow
                rotx = delta.x*cos(H) - delta.y*sin(H);
                sideOffset = size*0.5*cos(tipAngleRadians);
                k = 1.0 - clamp(rotx-sideOffset, 0.0, 1.0);
                c.rgb *= k;
                sideAngle = (3.14159 - tipAngleRadians)/2.0;
                sideOffset = 0.5 * sin(tipAngleRadians / 2.0);
                rotx = delta.x*cos(H-sideAngle) - delta.y*sin(H-sideAngle);
                k = clamp(rotx+size*sideOffset, 0.0, 1.0);
                c.rgb *= k;
                rotx = delta.x*cos(H+sideAngle) - delta.y*sin(H+sideAngle);
                k = clamp(rotx+ size*sideOffset, 0.0, 1.0);
                c.rgb *= k;

                c *= s.a;
                return c;
        }
        
        float4 rejig (sample_t s, destination dest)
        {
            
           // float4 s = dest.coord();
            float2 vector = s.rg - 0.5;
            float minLength = 1;
            float maxLength = 100;
            float len = length(vector);
            float H = atan2(vector.y, vector.x);
            H *= 3.0/3.1415926;
            float i = floor(H);
            float f = H-i;
            float a = f;
            float d = 1.0 - a;
            float4 c;
            if (H<-3.0) c = float4(0, 1, 1, 1);
            else if (H<-2.0) c = float4(0, d, 1, 1);
                else if (H<-1.0) c = float4(a, 0, 1, 1);
                else if (H<0.0)  c = float4(1, 0, d, 1);
                else if (H<1.0)  c = float4(1, a, 0, 1);
                else if (H<2.0)  c = float4(d, 1, 0, 1);
                else if (H<3.0)  c = float4(0, 1, a, 1);
                else             c = float4(0, 1, 1, 1);
            c.rgb *= clamp((len-minLength)/(maxLength-minLength), 0.0,1.0);
//            float diagLine = dest.coord().x + dest.coord().y;
//            float zebra = fract(diagLine/20.0 + time*2.0);
//            if ((zebra > 0.5) && (s.r > 1 || s.g > 1 || s.b > 1))
//                return float4(2.0, 0.0, 0.0, 1.0);
            return c;
        }
    
    
    }
    
    
}
