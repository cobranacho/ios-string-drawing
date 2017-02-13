// Copyright © 2016 C4
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions: The above copyright
// notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

import ReplayKit

open class ScreenRecorder: NSObject, RPPreviewViewControllerDelegate {
    public typealias PreviewControllerFinishedAction = (_ activities: Set<String>?) -> ()
    public typealias RecorderStoppedAction = () -> ()

    let recorder = RPScreenRecorder.shared()
    var preview: RPPreviewViewController?
    var activities: Set<String>?

    open var previewFinishedAction: PreviewControllerFinishedAction?
    open var recordingEndedAction: RecorderStoppedAction?
    open var enableMicrophone = false

    open func start() {
        preview = nil
        recorder.startRecording(withMicrophoneEnabled: enableMicrophone) { error in
            if let error = error {
                print("Start Recording Error: \(error.localizedDescription)")
            }
        }
    }

    open func start(_ duration: Double) {
        start()
        wait(duration) {
            self.stop()
        }
    }

    open func stop() {
        recorder.stopRecording { previewViewController, error in
            self.preview = previewViewController
            self.preview?.previewControllerDelegate = self
            self.recordingEndedAction?()
        }
    }

    open func showPreviewInController(_ controller: UIViewController) {
        guard let preview = preview else {
            print("Recorder has no preview to show.")
            return
        }

        controller.present(preview, animated: true, completion: nil)
    }

    open func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
        activities = activityTypes
    }

    open func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewFinishedAction?(activities)
        preview?.parent?.dismiss(animated: true, completion: nil)
    }
}
