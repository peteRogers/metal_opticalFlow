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
    
    private let requestHandler = VNSequenceRequestHandler()
    var altitude = 0.5
    var darkness = 1.2
    var scattering = 0.5
    var incer = 0.00001
    var previousImage:CIImage?
    var sunDim =  0.1
    
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
    
    
    private func processVideoFrame(sample:CIImage){
        let ciFilter = OpticalFlowVisualizerFilter()
        ciFilter.inputImage = sample
       // let fil = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputImageKey:ciFilter.outputImage!, kCIInputRadiusKey: 15])
        //currentCIImage = fil?.outputImage?.cropped(to: sample.extent)
        let filter = SunVisualizerFilter()
        filter.inputHeight = sample.extent.width
        filter.inputHeight = sample.extent.height
        filter.inputSunAlitude = altitude
        filter.inputSkyDarkness = darkness
        filter.inputSunDiameter = sunDim
        let fil = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputImageKey:filter.outputImage!, kCIInputRadiusKey: 15])
        //filter.inputAlbedo = scattering
        currentCIImage = fil?.outputImage
        altitude += incer
        incer = incer * 1.01
        print(altitude)
        if(altitude > 1.3){
            if(darkness > 0.1){
            darkness = darkness - 0.005
            }
            scattering = scattering - 0.0001
            sunDim -= 0.0005
        }
        
    }
}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        let request = CIImage(cvPixelBuffer: pixelBuffer).oriented(.up)
        if (self.previousImage == nil)
        {
            self.previousImage = request
        }
        let visionRequest = VNGenerateOpticalFlowRequest(targetedCIImage: request, options: [:])
        visionRequest.computationAccuracy = .veryHigh
        do {
            try self.requestHandler.perform([visionRequest], on: self.previousImage!)
            
            if let pixelBufferObservation = visionRequest.results?.first{
                let sample = CIImage(cvImageBuffer: pixelBufferObservation.pixelBuffer)
                processVideoFrame(sample: sample)
            }
        } catch {
            print(error)
        }
        // store the previous image
        self.previousImage = request
    }
}

