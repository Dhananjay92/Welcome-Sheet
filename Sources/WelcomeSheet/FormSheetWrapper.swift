// Source: https://stackoverflow.com/a/64839306

import SwiftUI

class ModalUIHostingController<Content>: UIHostingController<Content>, UIPopoverPresentationControllerDelegate where Content : View {
    
    var onDismiss: (() -> Void)
    
    required init?(coder: NSCoder) { fatalError("") }
    
    init(onDismiss: @escaping () -> Void, rootView: Content) {
        self.onDismiss = onDismiss
        super.init(rootView: rootView)
        preferredContentSize = CGSize(width: iPadSheetDimensions.width, height: iPadSheetDimensions.height)
        modalPresentationStyle = .formSheet
        presentationController?.delegate = self
//        isModalInPresentation = true 
    }
    
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        onDismiss()
    }
}

class ModalUIViewController<Content: View>: UIViewController {
    var isPresented: Bool
    var content: () -> Content
    var onDismiss: (() -> Void)
    private var hostVC: ModalUIHostingController<Content>
    
    private var isViewDidAppear = false
    
    required init?(coder: NSCoder) { fatalError("") }
    
    init(isPresented: Bool = false, onDismiss: @escaping () -> Void, content: @escaping () -> Content) {
        self.isPresented = isPresented
        self.onDismiss = onDismiss
        self.content = content
        self.hostVC = ModalUIHostingController(onDismiss: onDismiss, rootView: content())
        super.init(nibName: nil, bundle: nil)
    }
    
    func show() {
        guard isViewDidAppear else { return }
        self.hostVC = ModalUIHostingController(onDismiss: onDismiss, rootView: content())
        present(hostVC, animated: true)
    }
    
    func hide() {
        guard !hostVC.isBeingDismissed else { return }
        dismiss(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        isViewDidAppear = true
        if isPresented {
            show()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isViewDidAppear = false
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        show()
    }
}

struct FormSheet<Content: View> : UIViewControllerRepresentable {
    
    @Binding var show: Bool
    
    let content: () -> Content
    let onDismiss: () -> Void
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<FormSheet<Content>>) -> ModalUIViewController<Content> {
    
        let onDismiss = {
            self.onDismiss()
            self.show = false
        }
        
        let vc = ModalUIViewController(isPresented: show, onDismiss: onDismiss, content: content)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ModalUIViewController<Content>, context: UIViewControllerRepresentableContext<FormSheet<Content>>) {
        if show {
            uiViewController.show()
        }
        else {
            uiViewController.hide()
        }
    }
}

extension View {
    public func formSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View {
        self.background(FormSheet(show: isPresented, content: content, onDismiss: {}))
    }
    
    public func formSheet<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content, onDismiss: @escaping () -> Void) -> some View {
        self.background(FormSheet(show: isPresented, content: content, onDismiss: onDismiss))
    }
}
