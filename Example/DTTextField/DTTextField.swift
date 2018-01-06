//
//  DTTextField.swift
//  Pods
//
//  Created by Dhaval Thanki on 03/04/17.
//
//

import Foundation
import UIKit
// MARK: - TextFieldCounterDelegate

// MARK: - TextFieldCounterDelegate

protocol TextFieldCounterDelegate : class {
    func didReachMaxLength(textField: DTTextField)
}
extension UIView {
    
    public func shakeTo(transform: CGAffineTransform, duration: TimeInterval) {
        
        self.transform = transform
        
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    var userInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        if #available(iOS 9.0, *) {
            return UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute)
        } else {
            return UIApplication.shared.userInterfaceLayoutDirection
        }
    }
    
}

public extension String {
    
    var isEmptyStr:Bool{
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces).isEmpty
    }
}

//public class DTTextField: UITextField {
public class DTTextField: UITextField, UITextFieldDelegate{
    //TextFieldCounter.swift
    lazy internal var counterLabel: UILabel = UILabel()
    
    weak var counterDelegate: TextFieldCounterDelegate?
    
    // MARK: IBInspectable: Limits and behaviors
    
    @IBInspectable public dynamic var animate : Bool = true
    @IBInspectable public dynamic var ascending : Bool = true
    @IBInspectable public var maxLength : Int = DTTextField.defaultLength {
        didSet {
            if (!isValidMaxLength(max: maxLength)) {
                maxLength = DTTextField.defaultLength
            }
        }
    }
    @IBInspectable public dynamic var counterColor : UIColor = .lightGray
    @IBInspectable public dynamic var limitColor: UIColor = .red
    
    // MARK: Enumerations and Constants
    
    enum AnimationType {
        case basic
        case didReachLimit
        case unknown
    }
    
    static let defaultLength = 30
    
    // MARK: Init
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        super.delegate = self
        counterLabel = setupCounterLabel()
        commonInit()
    }
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        rightView = counterLabel
        rightViewMode = .whileEditing
    }
    
    // MARK: Public Methods
    
    /**
     Initializes a new beautiful *TextFieldCounter*.
     
     - parameter frame: The frame of view.
     - parameter animate: Default is `true`.
     - parameter ascending: Default is `true`.
     - parameter limit: By default, if the number is not greater than 0, the limit will be `30`.
     - parameter counterColor: Default color is `UIColor.lightGray`.
     - parameter limitColor: Default color is `UIColor.red`.
     */
    
    public init(frame: CGRect, limit: Int, animate: Bool = true, ascending: Bool = true, counterColor: UIColor = .lightGray, limitColor: UIColor = .red) {
        
        super.init(frame: frame)
        
        if !isValidMaxLength(max: limit) {
            maxLength = DTTextField.defaultLength
        } else {
            maxLength = limit
        }
        
        self.animate = animate
        self.ascending = ascending
        self.counterColor = counterColor
        self.limitColor = limitColor
        
        self.backgroundColor = .white
        self.layer.borderWidth = 0.35
        self.layer.cornerRadius = 5.0
        self.layer.borderColor = UIColor.lightGray.cgColor
        
        super.delegate = self
        counterLabel = setupCounterLabel()
    }
    
    // MARK: Private Methods
    
    private func isValidMaxLength(max: Int) -> Bool {
        return max > 0
    }
    
    private func setupCounterLabel() -> UILabel {
        
        let fontFrame : CGRect = CGRect(x: 0, y: 0, width: counterLabelWidth(), height: Int(frame.height))
        let label : UILabel = UILabel(frame: fontFrame)
        
        if let currentFont : UIFont = font {
            label.font = currentFont
            label.textColor = counterColor
            label.textAlignment = label.userInterfaceLayoutDirection == .rightToLeft ? .right : .left
            label.lineBreakMode = .byWordWrapping
            label.numberOfLines = 1
        }
        
        return label
    }
    
    private func localizedString(of number: Int) -> String {
        return String.localizedStringWithFormat("%i", number)
    }
    
    private func counterLabelWidth() -> Int {
        let biggestText = localizedString(of: maxLength)
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byWordWrapping
        
        var size : CGSize = CGSize()
        
        if let currentFont = font {
            size = biggestText.size(attributes: [NSFontAttributeName: currentFont, NSParagraphStyleAttributeName: paragraph])
        }
        
        return Int(size.width) + 15
    }
    
    private func updateCounterLabel(count: Int) {
        if count <= maxLength {
            if (ascending) {
                counterLabel.text = localizedString(of: count)
            } else {
                counterLabel.text = localizedString(of: maxLength - count)
            }
        }
        
        prepareToAnimateCounterLabel(count: count)
    }
    
    private func textFieldCharactersCount(textField: UITextField, string: String, changeCharactersIn range: NSRange) -> Int {
        
        var textFieldCharactersCount = 0
        
        if let textFieldText = textField.text {
            
            if !string.isEmpty {
                textFieldCharactersCount = textFieldText.characters.count + string.characters.count - range.length
            } else {
                textFieldCharactersCount = textFieldText.characters.count - range.length
            }
        }
        
        return textFieldCharactersCount
    }
    
    private func checkIfNeedsCallDidReachMaxLengthDelegate(count: Int) {
        if (count >= maxLength) {
            counterDelegate?.didReachMaxLength(textField: self)
        }
    }
    
    // MARK: - Animations
    
    private func prepareToAnimateCounterLabel(count: Int) {
        
        var animationType : AnimationType = .unknown
        
        if (count >= maxLength) {
            animationType = .didReachLimit
        } else if (count <= maxLength) {
            animationType = .basic
        }
        
        animateTo(type: animationType)
    }
    
    private func animateTo(type: AnimationType) {
        
        switch type {
        case .basic:
            animateCounterLabelColor(color: counterColor)
        case .didReachLimit:
            animateCounterLabelColor(color: limitColor)
            
            if #available(iOS 10.0, *) {
                fireHapticFeedback()
            }
            
            if (animate) {
                counterLabel.shakeTo(transform: CGAffineTransform(translationX: 5, y: 0), duration: 0.3)
            }
        default:
            break
        }
    }
    
    private func animateCounterLabelColor(color: UIColor) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.counterLabel.textColor = color
        }, completion: nil)
    }
    
    // MARK: - Haptic Feedback
    
    private func fireHapticFeedback() {
        if #available(iOS 10.0, *) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        var shouldChange = false
        let charactersCount = textFieldCharactersCount(textField: textField, string: string, changeCharactersIn: range)
        
        if string.isEmpty {
            shouldChange = true
        } else {
            shouldChange = charactersCount <= maxLength
        }
        
        updateCounterLabel(count: charactersCount)
        checkIfNeedsCallDidReachMaxLengthDelegate(count: charactersCount)
        
        return shouldChange
    }
    
    //--->
    
    public enum FloatingDisplayStatus{
        case always
        case never
        case defaults
    }
    
    fileprivate var lblFloatPlaceholder:UILabel             = UILabel()
    fileprivate var lblError:UILabel                        = UILabel()
    
    fileprivate let paddingX:CGFloat                        = 5.0
    
    fileprivate let paddingHeight:CGFloat                   = 10.0
    
    public var dtLayer:CALayer                              = CALayer()
    public var floatPlaceholderColor:UIColor                = UIColor.black
    public var floatPlaceholderActiveColor:UIColor          = UIColor.black
    public var floatingLabelShowAnimationDuration           = 0.3
    public var floatingDisplayStatus:FloatingDisplayStatus  = .defaults
    
    public var errorMessage:String = ""{
        didSet{ lblError.text = errorMessage }
    }
    
    public var animateFloatPlaceholder:Bool = true
    public var hideErrorWhenEditing:Bool   = true
    
    public var errorFont = UIFont.systemFont(ofSize: 10.0){
        didSet{ invalidateIntrinsicContentSize() }
    }
    
    public var floatPlaceholderFont = UIFont.systemFont(ofSize: 10.0){
        didSet{ invalidateIntrinsicContentSize() }
    }
    
    public var paddingYFloatLabel:CGFloat = 3.0{
        didSet{ invalidateIntrinsicContentSize() }
    }
    
    public var paddingYErrorLabel:CGFloat = 3.0{
        didSet{ invalidateIntrinsicContentSize() }
    }
    
    public var borderColor:UIColor = UIColor(red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0){
        didSet{ dtLayer.borderColor = borderColor.cgColor }
    }
    
    public var canShowBorder:Bool = true{
        didSet{ dtLayer.isHidden = !canShowBorder }
    }
    
    public var placeholderColor:UIColor?{
        didSet{
            guard let color = placeholderColor else { return }
            attributedPlaceholder = NSAttributedString(string: placeholderFinal,
                                                       attributes: [NSForegroundColorAttributeName:color])
        }
    }
    
    fileprivate var x:CGFloat {
        
        if let leftView = leftView {
            return leftView.frame.origin.x + leftView.bounds.size.width + paddingX
        }
        
        return paddingX
    }
    
    fileprivate var fontHeight:CGFloat{
        return ceil(font!.lineHeight)
    }
    
    fileprivate var dtLayerHeight:CGFloat{
        return showErrorLabel ? floor(bounds.height - lblError.bounds.size.height - paddingYErrorLabel) : bounds.height
    }
    
    fileprivate var floatLabelWidth:CGFloat{
        
        var width = bounds.size.width
        
        if let leftViewWidth = leftView?.bounds.size.width{
            width -= leftViewWidth
        }
        
        if let rightViewWidth = rightView?.bounds.size.width {
            width -= rightViewWidth
        }
        
        return width - (self.x * 2)
    }
    
    fileprivate var placeholderFinal:String{
        if let attributed = attributedPlaceholder { return attributed.string }
        return placeholder ?? " "
    }
    
    fileprivate var isFloatLabelShowing:Bool = false
    
    fileprivate var showErrorLabel:Bool = false{
        didSet{
            
            guard showErrorLabel != oldValue else { return }
            
            guard showErrorLabel else {
                hideErrorMessage()
                return
            }
            
            guard !errorMessage.isEmptyStr else { return }
            showErrorMessage()
        }
    }
    
    override public var borderStyle: UITextBorderStyle{
        didSet{
            guard borderStyle != oldValue else { return }
            borderStyle = .none
        }
    }
    
    public override var text: String?{
        didSet{ self.textFieldTextChanged() }
    }
    
    override public var placeholder: String?{
        didSet{
            
            guard let color = placeholderColor else {
                lblFloatPlaceholder.text = placeholderFinal
                return
            }
            attributedPlaceholder = NSAttributedString(string: placeholderFinal,
                                                       attributes: [NSForegroundColorAttributeName:color])
        }
    }
    
    override public var attributedPlaceholder: NSAttributedString?{
        didSet{ lblFloatPlaceholder.text = placeholderFinal }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
//    required public init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        commonInit()
//    }
    
    public func showError(message:String? = nil) {
        if let msg = message { errorMessage = msg }
        showErrorLabel = true
    }
    
    public func hideError()  {
        showErrorLabel = false
    }
    
    fileprivate func commonInit() {
        
        dtLayer.cornerRadius        = 4.5
        dtLayer.borderWidth         = 0.5
        dtLayer.borderColor         = borderColor.cgColor
        dtLayer.backgroundColor     = UIColor.white.cgColor
        
        floatPlaceholderColor       = UIColor(red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
        floatPlaceholderActiveColor = tintColor
        lblFloatPlaceholder.frame   = CGRect.zero
        lblFloatPlaceholder.alpha   = 0.0
        lblFloatPlaceholder.font    = floatPlaceholderFont
        lblFloatPlaceholder.text    = placeholderFinal
        
        addSubview(lblFloatPlaceholder)
        
        lblError.frame              = CGRect.zero
        lblError.font               = errorFont
        lblError.textColor          = UIColor.red
        lblError.numberOfLines      = 0
        lblError.isHidden           = true
        
        addTarget(self, action: #selector(textFieldTextChanged), for: .editingChanged)
        
        addSubview(lblError)
        
        layer.insertSublayer(dtLayer, at: 0)
    }
    
    fileprivate func showErrorMessage(){
        
        lblError.text = errorMessage
        lblError.isHidden = false
        let boundWithPadding = CGSize(width: bounds.width - (x * 2), height: bounds.height)
        let errorLabelSize =  lblError.sizeThatFits(boundWithPadding)
        lblError.frame = CGRect(x: paddingX, y: 0, width: errorLabelSize.width, height: errorLabelSize.height)
        invalidateIntrinsicContentSize()
    }
    
    fileprivate func hideErrorMessage(){
        lblError.text = ""
        lblError.isHidden = true
        lblError.frame = CGRect.zero
        invalidateIntrinsicContentSize()
    }
    
    fileprivate func showFloatingLabel(_ animated:Bool) {
        
        let animations:(()->()) = {
            self.lblFloatPlaceholder.alpha = 1.0
            self.lblFloatPlaceholder.frame = CGRect(x: self.lblFloatPlaceholder.frame.origin.x,
                                                    y: self.paddingYFloatLabel,
                                                    width: self.lblFloatPlaceholder.bounds.size.width,
                                                    height: self.lblFloatPlaceholder.bounds.size.height)
        }
        
        if animated && animateFloatPlaceholder {
            UIView.animate(withDuration: floatingLabelShowAnimationDuration,
                           delay: 0.0,
                           options: [.beginFromCurrentState,.curveEaseOut],
                           animations: animations){ status in
                            DispatchQueue.main.async {
                                self.layoutIfNeeded()
                            }
            }
        }else{
            animations()
        }
    }
    
    fileprivate func hideFlotingLabel(_ animated:Bool) {
        
        let animations:(()->()) = {
            self.lblFloatPlaceholder.alpha = 0.0
            self.lblFloatPlaceholder.frame = CGRect(x: self.lblFloatPlaceholder.frame.origin.x,
                                                    y: self.lblFloatPlaceholder.font.lineHeight,
                                                    width: self.lblFloatPlaceholder.bounds.size.width,
                                                    height: self.lblFloatPlaceholder.bounds.size.height)
        }
        
        if animated && animateFloatPlaceholder {
            UIView.animate(withDuration: floatingLabelShowAnimationDuration,
                           delay: 0.0,
                           options: [.beginFromCurrentState,.curveEaseOut],
                           animations: animations){ status in
                            DispatchQueue.main.async {
                                self.layoutIfNeeded()
                            }
            }
        }else{
            animations()
        }
    }
    
    fileprivate func insetRectForEmptyBounds(rect:CGRect) -> CGRect{
        
        guard showErrorLabel else { return CGRect(x: x, y: 0, width: rect.width - paddingX, height: rect.height) }
        
        let topInset = (rect.size.height - lblError.bounds.size.height - paddingYErrorLabel - fontHeight) / 2.0
        let textY = topInset - ((rect.height - fontHeight) / 2.0)
        
        return CGRect(x: x, y: floor(textY), width: rect.size.width - paddingX, height: rect.size.height)
    }
    
    fileprivate func insetRectForBounds(rect:CGRect) -> CGRect {
        
        guard let placeholderText = lblFloatPlaceholder.text,!placeholderText.isEmptyStr  else {
            return insetRectForEmptyBounds(rect: rect)
        }
        
        if floatingDisplayStatus == .never {
            return insetRectForEmptyBounds(rect: rect)
        }else{
            
            if let text = text,text.isEmptyStr && floatingDisplayStatus == .defaults {
                return insetRectForEmptyBounds(rect: rect)
            }else{
                let topInset = paddingYFloatLabel + lblFloatPlaceholder.bounds.size.height + (paddingHeight / 2.0)
                let textOriginalY = (rect.height - fontHeight) / 2.0
                var textY = topInset - textOriginalY
                
                if textY < 0 && !showErrorLabel { textY = topInset }
                
                return CGRect(x: x, y: ceil(textY), width: rect.size.width - paddingX, height: rect.height)
            }
        }
    }
    
    @objc fileprivate func textFieldTextChanged(){
        guard hideErrorWhenEditing && showErrorLabel else { return }
        showErrorLabel = false
    }
    
    override public var intrinsicContentSize: CGSize{
        self.layoutIfNeeded()
        
        let textFieldIntrinsicContentSize = super.intrinsicContentSize
        
        lblError.sizeToFit()
        
        if showErrorLabel {
            lblFloatPlaceholder.sizeToFit()
            return CGSize(width: textFieldIntrinsicContentSize.width,
                          height: textFieldIntrinsicContentSize.height + paddingYFloatLabel + paddingYErrorLabel + lblFloatPlaceholder.bounds.size.height + lblError.bounds.size.height + paddingHeight)
        }else{
            return CGSize(width: textFieldIntrinsicContentSize.width,
                          height: textFieldIntrinsicContentSize.height + paddingYFloatLabel + lblFloatPlaceholder.bounds.size.height + paddingHeight)
        }
    }
    
    override public func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return insetRectForBounds(rect: rect)
    }
    
    override public func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return insetRectForBounds(rect: rect)
    }
    
    fileprivate func insetForSideView(forBounds bounds: CGRect) -> CGRect{
        var rect = bounds
        rect.origin.y = 0
        rect.size.height = dtLayerHeight
        return rect
    }
    
    override public func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.leftViewRect(forBounds: bounds)
        return insetForSideView(forBounds: rect)
    }
    
    override public func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.rightViewRect(forBounds: bounds)
        return insetForSideView(forBounds: rect)
    }
    
    override public func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.clearButtonRect(forBounds: bounds)
        rect.origin.y = (dtLayerHeight - rect.size.height) / 2
        return rect
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dtLayer.frame = CGRect(x: bounds.origin.x,
                               y: bounds.origin.y,
                               width: bounds.width,
                               height: dtLayerHeight)
        CATransaction.commit()
        
        if showErrorLabel {
            
            var lblErrorFrame = lblError.frame
            lblErrorFrame.origin.y = dtLayer.frame.origin.y + dtLayer.frame.size.height + paddingYErrorLabel
            lblError.frame = lblErrorFrame
        }
        
        let floatingLabelSize = lblFloatPlaceholder.sizeThatFits(lblFloatPlaceholder.superview!.bounds.size)
        
        lblFloatPlaceholder.frame = CGRect(x: x, y: lblFloatPlaceholder.frame.origin.y,
                                           width: floatingLabelSize.width,
                                           height: floatingLabelSize.height)
        
        lblFloatPlaceholder.textColor = isFirstResponder ? floatPlaceholderActiveColor : floatPlaceholderColor
        
        switch floatingDisplayStatus {
        case .never:
            hideFlotingLabel(isFirstResponder)
        case .always:
            showFloatingLabel(isFirstResponder)
        default:
            if let enteredText = text,!enteredText.isEmptyStr{
                showFloatingLabel(isFirstResponder)
            }else{
                hideFlotingLabel(isFirstResponder)
            }
        }
    }
}
