//
//  ViewController.swift
//  Make It Rain
//
//  Created by Timothy on 4/13/19.
//  Copyright © 2019 Timothy. All rights reserved.
//

import UIKit
import HGCircularSlider

class SelectionViewController: UIViewController, UITextFieldDelegate, BanknoteViewControllerDelegate {
    
    func updateView(ratio: Double) {
        /*
        guard let newVal = Double(cashTextField.text!.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789").inverted)) else {
            print("error")
            return
        }
        // NEED TO CONVERT CURRENCIES
        let convertedVal = Int((Double(newVal)*ratio).rounded(.up))
        */
        let convertedVal = Int(Double(Currency.dollarValue) / Currency.selectedCurrency.ratio)
        cashTextField.text = Currency.selectedCurrency.sign + "\(convertedVal)"
        slider.maximumValue = CGFloat(10000/Currency.selectedCurrency.ratio)
        slider.endPointValue = convertedVal < Int(slider.maximumValue) ? CGFloat(convertedVal) : slider.maximumValue - 1
    }
    

    @IBOutlet weak var slider: CircularSlider!
    @IBOutlet weak var playBarButton: UIBarButtonItem!
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    @IBOutlet weak var cashTextField: CashTextField!

    var banknoteVC: BanknoteViewController!
    var topBar: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSlider(slider: slider)
        //view.backgroundColor = UIColor(patternImage: UIImage(named: "money.jpg")!)
         view.backgroundColor = UIColor.themeColor.secondary
        topBar = UIApplication.shared.statusBarFrame.size.height +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
        //navigationController?.navigationBar.backgroundColor = UIColor.themeColor.main
        navigationController?.navigationBar.barTintColor = UIColor.themeColor.main
        navigationController?.navigationBar.isTranslucent = false
        playBarButton.tintColor = UIColor.themeColor.extra
        menuBarButton.tintColor = UIColor.themeColor.extra
        menuBarButton.image = UIImage(named: "list.png")
        
        cashTextField.layer.masksToBounds = false
        cashTextField.layer.shadowRadius = 3.0
        cashTextField.layer.shadowColor = UIColor.black.cgColor
        cashTextField.layer.shadowOffset = CGSize(width: 1, height: 1)
        cashTextField.layer.shadowOpacity = 1.0
        
        cashTextField.delegate = self
        slider.addTarget(self, action: #selector(updateCashValue), for: .valueChanged)
        
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: nil)
        cancelButton.tintColor = UIColor.themeColor.extra
        let navigationFont = UIFont(name: "Montserrat Medium", size: 24)
        cancelButton.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.themeColor.extra, NSAttributedString.Key.font: navigationFont!], for: .normal)
        self.navigationItem.backBarButtonItem = cancelButton
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeybordNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    func setupSlider(slider: CircularSlider){
        slider.minimumValue = 0
        slider.maximumValue = 10000
        slider.diskColor = .clear
        slider.trackFillColor = UIColor.themeColor.main
        slider.thumbRadius = 16
        slider.trackColor = UIColor.themeColor.gray
        slider.backtrackLineWidth = 6
        slider.lineWidth = 14
        slider.endThumbStrokeColor = UIColor.themeColor.main
        slider.endThumbTintColor = UIColor.themeColor.extra
        slider.thumbLineWidth = 7
        slider.endPointValue = 1000
        slider.endThumbStrokeHighlightedColor = UIColor.themeColor.main
        slider.backgroundColor = .clear
    }
    
    @objc func updateCashValue(){
        let newValue = Int(slider.endPointValue)
        Currency.dollarValue = Int(Double(newValue)*Currency.selectedCurrency.ratio)
        cashTextField.text = Currency.selectedCurrency.sign + "\(newValue)"
    }
    
    func updateSlider(num: Int){
        Currency.dollarValue = Int(Double(num) * Currency.selectedCurrency.ratio)
        slider.endPointValue = num < Int(slider.maximumValue) ? CGFloat(num) : slider.maximumValue - 1
    }
    
    // MARK: TextField Delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let oldText = textField.text! as NSString
        let newText = oldText.replacingCharacters(in: range, with: string)
        let modifiedText = newText.replacingOccurrences(of: Currency.selectedCurrency.sign, with: "")
        
        guard let num = Int(modifiedText) else {
            if (modifiedText == ""){
                textField.text = Currency.selectedCurrency.sign
                updateSlider(num: 0)
            }
            return false
        }
        
        textField.text = Currency.selectedCurrency.sign + "\(num)"
        updateSlider(num: num)
        
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.text == Currency.selectedCurrency.sign){
            textField.text = Currency.selectedCurrency.sign + "0"
            Currency.dollarValue = 0
        }
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Keyboard Notifications
    
    func subscribeToKeybordNotifications(){
        
        //Initiation of notification observation
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    @objc func keyboardWillShow(_ notification: Notification){
        
        //changes y-coordinate of the view above the keyboard if bottom text is selected
        if (cashTextField.isFirstResponder){
            let keyboardHeight = getKeyboardHeight(notification)
            /* Real calculations accounting for navBar, but too much movement
            let realOrigin = slider.superview!.convert(slider.frame.origin, to: self.view)
            let bottomAnchor = view.frame.maxY - (slider.frame.height + realOrigin.y)
            */
            
            let bottomAnchor = view.frame.maxY - slider.frame.maxY*1.02 // Not a great solution but works
        
            if (bottomAnchor < keyboardHeight){
                view.frame.origin.y += bottomAnchor - keyboardHeight
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification){
        view.frame.origin.y = topBar
    }
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        
        //Gets keyboard height
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    func unsubscribeFromKeyboardNotifications() {
        
        //Removes this control view as observer for notifications
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        cashTextField.resignFirstResponder()
        
        if segue.identifier == "containerBanknoteSegue" {
            banknoteVC = segue.destination as? BanknoteViewController
            banknoteVC!.banknoteViewControllerDelegate = self
        }
    }
}

