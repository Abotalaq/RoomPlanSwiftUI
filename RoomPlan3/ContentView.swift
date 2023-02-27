//
//  ContentView.swift
//  RoomPlan3
//
//  Created by ahmed alharbi and Abbdullah Aloufi on 27/07/1444 AH.
//

import SwiftUI
import RoomPlan


class RoomCaptureController : ObservableObject, RoomCaptureViewDelegate, RoomCaptureSessionDelegate
{
  static var instance = RoomCaptureController()
  
  @Published var roomCaptureView: RoomCaptureView
  @Published var showExportButton = false
  @Published var showShareSheet = false
  @Published var exportUrl: URL?
  
  var sessionConfig: RoomCaptureSession.Configuration
  var finalResult: CapturedRoom?
  
  init() {
    roomCaptureView = RoomCaptureView(frame: CGRect(x: 0, y: 0, width: 42, height: 42))
    sessionConfig = RoomCaptureSession.Configuration()
    roomCaptureView.captureSession.delegate = self
    roomCaptureView.delegate = self
  }
  
  func startSession() {
    roomCaptureView.captureSession.run(configuration: sessionConfig)
  }
  
  func stopSession() {
    roomCaptureView.captureSession.stop()
  }
  
  func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
    return true
  }
  
  func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
    finalResult = processedResult
  }
  
  func export() {
    exportUrl = FileManager.default.temporaryDirectory.appending(path: "scan.usdz")
    do {
      try finalResult?.export(to: exportUrl!)
    } catch {
      print("Error exporting usdz scan.")
      return
    }
    showShareSheet = true
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not needed.")
  }
  
  func encode(with coder: NSCoder) {
    fatalError("Not needed.")
  }
}









struct RoomCaptureViewRep : UIViewRepresentable
{
  func makeUIView(context: Context) -> some UIView {
    RoomCaptureController.instance.roomCaptureView
  }
  
  func updateUIView(_ uiView: UIViewType, context: Context) {}
}

struct ActivityViewControllerRep: UIViewControllerRepresentable {
  var items: [Any]
  var activities: [UIActivity]? = nil
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewControllerRep>) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: items, applicationActivities: activities)
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewControllerRep>) {}
}

struct ScanningView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject var captureController = RoomCaptureController.instance
  
  var body: some View {
    ZStack(alignment: .bottom) {
      RoomCaptureViewRep()
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button("Cancel") {
          captureController.stopSession()
          dismiss()
        })
        .navigationBarItems(trailing: Button("Done") {
          captureController.stopSession()
          captureController.showExportButton = true
        }.opacity(captureController.showExportButton ? 0 : 1)).onAppear() {
          captureController.showExportButton = false
          captureController.startSession()
        }
      Button(action: {
        captureController.export()
        dismiss()
      }, label: {
        Text("Export").font(.title2)
      }).buttonStyle(.borderedProminent).cornerRadius(40).opacity(captureController.showExportButton ? 1 : 0).padding().sheet(isPresented: $captureController.showShareSheet, content:{
        ActivityViewControllerRep(items: [captureController.exportUrl!])
      })
    }
  }
}

struct ContentView: View {
  var body: some View {
    NavigationStack {
      VStack {
        Image(systemName: "camera.metering.matrix")
          .imageScale(.large)
          .foregroundColor(.accentColor)
        Text("Roomscanner").font(.title)
        Spacer().frame(height: 40)
        Text("Scan the room by pointing the camera at all surfaces. Model export supports usdz and obj format.")
        Spacer().frame(height: 40)
        NavigationLink(destination: ScanningView(), label: {Text("Start Scan")}).buttonStyle(.borderedProminent).cornerRadius(40).font(.title2)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
