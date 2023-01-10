//
//  ViewController.swift
//  metalVideoFilter
//
//  Created by dt on 14/03/2022.
//

import Foundation
import UIKit
import MetalKit
import AVFoundation
import CoreImage.CIFilterBuiltins
import Vision

class ViewController: UIViewController, MTKViewDelegate{
    
    let requestHandler = VNSequenceRequestHandler()
   
    var previousImage:CIImage?
    var back:CIImage!
   
    @IBOutlet weak var cameraView: MTKView!{
        
        didSet {
            guard metalDevice == nil else { return }
            setupMetal()
            setupCoreImage()
            setupCaptureSession()
            
        }
    }
    
    // The Metal pipeline.
    public var metalDevice: MTLDevice!
    public var metalCommandQueue: MTLCommandQueue!
    
    // The Core Image pipeline.
    public var ciContext: CIContext!
    public var currentCIImage: CIImage? {
        didSet {
            cameraView.draw()
        }
    }
    
    public var session: AVCaptureSession?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let i1 = UIImage(named: "beachBack.png")
        back = CIImage(image: i1!)
        print("foofoof")
    }
    
    
    func processVideoFrame(sample:CIImage, orig: CIImage){
       // let ciFilter = OpticalFlowVisualizerFilter()
       // ciFilter.inputImage = sample
        let maskScaleX = sample.extent.width / orig.extent.width
        let maskScaleY = sample.extent.height / orig.extent.height
        let backScaleX = sample.extent.width / back.extent.width
        let backScaleY = sample.extent.height / back.extent.height
        let maskScaled = orig.transformed(
          by: __CGAffineTransformMake(maskScaleX, 0, 0, maskScaleY, 0, 0))
        let backScaled = back.transformed(
          by: __CGAffineTransformMake(backScaleX, 0, 0, backScaleY, 0, 0))
        //print(sample.extent.size)
        //print("orig: \(maskScaled.extent.size)")
       // let fil = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputImageKey:ciFilter.outputImage!, kCIInputRadiusKey: 8])
        print(backScaled.extent.width)
        let blendFilter = CIFilter.blendWithMask()
        blendFilter.maskImage = sample
        blendFilter.backgroundImage = backScaled
        blendFilter.inputImage = maskScaled
        currentCIImage = blendFilter.outputImage

        
    }
}



