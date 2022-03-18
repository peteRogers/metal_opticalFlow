//
//  ViewControllerAddons.swift
//  metalVideoFilter
//
//  Created by dt on 16/03/2022.
//

import Foundation
import MetalKit
import AVFoundation


extension ViewController{

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    func draw(in view: MTKView) {
        // grab command buffer so we can encode instructions to GPU
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
            return
        }
        
        // grab image
        guard let ciImage = currentCIImage else {
            return
        }
        
        // ensure drawable is free and not tied in the preivous drawing cycle
        guard let currentDrawable = view.currentDrawable else {
            return
        }
        
        // make sure the image is full screen
        let drawSize = cameraView.drawableSize
        let scaleX = drawSize.width / ciImage.extent.width
        let scaleY = drawSize.height / ciImage.extent.height
        
        let newImage = ciImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
        //render into the metal texture
        self.ciContext.render(newImage,
                              to: currentDrawable.texture,
                              commandBuffer: commandBuffer,
                              bounds: newImage.extent,
                              colorSpace: CGColorSpaceCreateDeviceRGB())
        
        // register drawwable to command buffer
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
    
    func setupMetal() {
        metalDevice = MTLCreateSystemDefaultDevice()
        metalCommandQueue = metalDevice.makeCommandQueue()
        //cameraView is a metal view!!!
        cameraView.device = metalDevice
        cameraView.isPaused = true
        cameraView.enableSetNeedsDisplay = false
        cameraView.delegate = self
        cameraView.framebufferOnly = false
    }
    
    func setupCoreImage() {
        ciContext = CIContext(mtlDevice: metalDevice)
    }
    
   
    func isiOSAppOnMac() -> Bool {
#if targetEnvironment(macCatalyst)
           return true
#else
        if UIDevice.current.model == "iPad" {

                return false

          }else{
               return false

          }
#endif
    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Delegate method not implemented.
        print("size changed some how")
    }
    
    
    
    func setupCaptureSession() {
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("Error getting AVCaptureDevice.")
        }
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            fatalError("Error getting AVCaptureDeviceInput")
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.session = AVCaptureSession()
            self.session?.sessionPreset = .medium
            
            self.session?.addInput(input)
            
            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.setSampleBufferDelegate(self, queue: .main)
            
            self.session?.addOutput(output)
            if(self.isiOSAppOnMac()){
                output.connections.first?.videoOrientation = .portrait
            }else{
                output.connections.first?.videoOrientation = .landscapeLeft
            }
            self.session?.startRunning()
            
        }
    }
    
}


class OpticalFlowVisualizerFilter: CIFilter {
    var inputImage: CIImage?
    
    let callback: CIKernelROICallback = {
            (index, rect) in
                return rect
            }
    
    static var kernel: CIColorKernel = { () -> CIColorKernel in
        let url = Bundle.main.url(forResource: "myshader",
                                  withExtension: "ci.metallib")!
        let data = try! Data(contentsOf: url)
        
        return try! CIColorKernel(functionName: "rejig",
                                  fromMetalLibraryData: data)
    }()

    override var outputImage : CIImage? {
        get {
            guard let input = inputImage else {return nil}
            return OpticalFlowVisualizerFilter.kernel.apply(extent: input.extent, arguments: [input])
        }
    }
    
   
    
}
