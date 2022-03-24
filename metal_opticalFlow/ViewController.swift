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
    }
    
    
    func processVideoFrame(sample:CIImage){
        let ciFilter = OpticalFlowVisualizerFilter()
        ciFilter.inputImage = sample
        
        let fil = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputImageKey:ciFilter.outputImage!, kCIInputRadiusKey: 8])
        currentCIImage = fil?.outputImage?.cropped(to: sample.extent)

        
    }
}



