
//
//  SignatureView.swift
//  SwiftUI Recipes
//
//  Created by Gordan Glavaš on 28.06.2021..
//

import SwiftUI
import CoreGraphics
import UIKit

private let maxHeight: CGFloat = 160
private let lineWidth: CGFloat = 3

public struct SignatureView: View {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var drawing = DrawingPath()
    @State var image = UIImage()
    @State private var isImageSet = false
    
    public let onSignatureCompleted: (UIImage) -> Void
    
    public var body: some View {
        VStack {
            SignatureDrawView(drawing: $drawing)
            
            Text("Please Sign").font(.caption).fontWeight(.medium)
            
            HStack {
                HStack {
                    Spacer()
                    Button { self.clear() } label: { Text("Clear").fontWeight(.semibold).foregroundStyle(.white) }
                    Spacer()
                }
                .padding()
                .background(.gray)
                .clipShape(.rect(cornerRadius: 10))
                .padding()
                
                
                HStack {
                    Spacer()
                    Button { self.done(); print("done") } label: { Text("Done").fontWeight(.semibold).foregroundStyle(.white) }
                    Spacer()
                }
                .padding()
                .background(Color(red: 0, green: 60, blue: 200)) // blue ish
                .clipShape(.rect(cornerRadius: 10))
                .padding()
                
            } // h both
//            .onAppear {
//                UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
//                AppDelegate.orientationLock = .landscapeLeft
//            }
//            .onDisappear {
//                AppDelegate.orientationLock = .allButUpsideDown
//            }
//            
            Image(uiImage: self.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
        }
    }
    
    
    private func done() {
        let path = drawing.cgPath
        let maxX = drawing.points.map { $0.x }.max() ?? 0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: maxX, height: maxHeight))
        let uiImage = renderer.image { ctx in
            ctx.cgContext.setStrokeColor(CGColor(red: 220, green: 220, blue: 220, alpha: 1.0)) // white
            ctx.cgContext.setLineWidth(lineWidth)
            ctx.cgContext.beginPath()
            ctx.cgContext.addPath(path)
            ctx.cgContext.drawPath(using: .stroke)
        }
        self.image = uiImage
        self.onSignatureCompleted(self.image)
    }

    
    private func clear() {
        drawing = DrawingPath()
        image = UIImage()
        isImageSet = false
    }
    
}


struct FramePreferenceKey: PreferenceKey {
  static var defaultValue: CGRect = .zero

  static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
    value = nextValue()
  }
}


struct SignatureDrawView: View {
    @Binding var drawing: DrawingPath
    
    @State private var drawingBounds: CGRect = .zero
    
    var body: some View {
        ZStack {
            Color.clear
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: FramePreferenceKey.self,
                                           value: geometry.frame(in: .local))
                })
                .onPreferenceChange(FramePreferenceKey.self) { bounds in
                    drawingBounds = bounds
                }
            
            VStack {
                Spacer()
                HStack {
                    Image(systemName: "xmark")
                    VStack {
                        Divider()
                            .frame(height: 1)
                            .overlay(.white)
                    }
                } // h
                .padding(.horizontal)
                .padding(.bottom, 4)
            } // v
            
            if drawing.isEmpty {
                Image(systemName: "applepencil.and.scribble")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                    .fontWeight(.thin)
                    .font(.subheadline)
                
            } else {
                DrawShape(drawingPath: drawing)
                    .stroke(lineWidth: lineWidth)
                    .foregroundStyle(.white)
            }
            
        } // z
        .frame(height: maxHeight)
        .gesture(DragGesture(minimumDistance: 0.00001)
            .onChanged( { value in
                if drawingBounds.contains(value.location) {
                    drawing.addPoint(value.location)
                } else {
                    drawing.addBreak()
                }
            }).onEnded( { value in
                drawing.addBreak()
            }))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray))
            
    }
}

struct DrawingPath {
    private(set) var points = [CGPoint]()
    private var breaks = [Int]()
    
    var isEmpty: Bool {
        points.isEmpty
    }
    
    mutating func addPoint(_ point: CGPoint) {
        points.append(point)
    }
    
    
    mutating func addBreak() {
        breaks.append(points.count)
    }
    
    var cgPath: CGPath {
        let path = CGMutablePath()
        guard let firstPoint = points.first else { return path }
        path.move(to: firstPoint)
        for i in 1..<points.count {
            if breaks.contains(i) {
                path.move(to: points[i])
            } else {
                path.addLine(to: points[i])
            }
        }
        return path
    }
    
    var path: Path {
        var path = Path()
        guard let firstPoint = points.first else { return path }
        path.move(to: firstPoint)
        for i in 1..<points.count {
            if breaks.contains(i) {
                path.move(to: points[i])
            } else {
                path.addLine(to: points[i])
            }
            
        }
        return path
    }
}

struct DrawShape: Shape {
    let drawingPath: DrawingPath
    
    func path(in rect: CGRect) -> Path {
        drawingPath.path
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.allButUpsideDown
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

