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
    
    
    private func processVideoFrame(sample:CIImage){
        let ciFilter = OpticalFlowVisualizerFilter()
        ciFilter.inputImage = sample
        let fil = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputImageKey:ciFilter.outputImage!, kCIInputRadiusKey: 15])
        currentCIImage = fil?.outputImage?.cropped(to: sample.extent)
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

