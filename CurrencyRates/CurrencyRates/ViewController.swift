//
//  ViewController.swift
//  CurrencyRates
//
//  Created by Taimuraz Tibilov on 02/06/2020.
//  Copyright © 2020 Taimuraz Tibilov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var firstCurrency: UILabel!
    @IBOutlet weak var secondCurrency: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var firstAmount: UITextField!
    @IBOutlet weak var secondAmount: UITextField!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    var currencies: [String: Double] = [:]
    var lastUpdateDate: String?
    var baseCurr: String?
    var first: String?
    var second: String?
    var isFirst: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        loadData()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        loadingIndicator.stopAnimating()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func updateInfo(_ sender: Any) {
        loadingIndicator.startAnimating()
        updateData()
        loadingIndicator.stopAnimating()
    }
    
    @IBAction func firstAmountChanged(_ sender: Any) {
        guard let fS = first else { return }
        guard let sS = second else { return }
        guard let f = currencies[fS] else { return }
        guard let s = currencies[sS] else { return }
        if let fVal = Double(firstAmount.text!) {
            secondAmount.text = String(fVal * f / s)
        } else {
            secondAmount.text = ""
        }
    }
    
    @IBAction func secondAmountChanged(_ sender: Any) {
        guard let fS = first else { return }
        guard let sS = second else { return }
        guard let f = currencies[fS] else { return }
        guard let s = currencies[sS] else { return }
        if let sVal = Double(secondAmount.text!) {
            firstAmount.text = String(sVal * s / f)
        } else {
            firstAmount.text = ""
        }
    }
    
    @IBAction func firtsTouched(_ sender: Any) {
        isFirst = true
    }
    
    @IBAction func secondTouched(_ sender: Any) {
        isFirst = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let chooserController = segue.destination as! ChooserViewController
        chooserController.update = isFirst ? setFirst : setSecond
        chooserController.pickerData = Array(currencies.keys)
    }
    
    func updateRate() {
        guard let fS = first else { return }
        guard let sS = second else { return }
        guard let f = currencies[fS] else { return }
        guard let s = currencies[sS] else { return }
        rateLabel.text = "Rate for \(first!) to \(second!) is \(f / s)"
        firstAmount.text = ""
        secondAmount.text = ""
    }
    
    func setFirst(_ f: String?) {
        if f == nil { return }
        first = f;
        firstCurrency.text = f
        updateRate()
    }
    
    func setSecond(_ f: String?) {
        if f == nil { return }
        second = f;
        secondCurrency.text = f
        updateRate()
    }
    
    func updateData() {
        currencies = [:]
        loadData()
    }
    
    func loadData() {
        let url = URL(string: "https://api.ratesapi.io/api/latest/")!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            
            if let httpResponse = response as? HTTPURLResponse {
                if (httpResponse.statusCode == 500) {
                    self.displayErrorMessage(message: "Unable to load information")
                }
                else if (httpResponse.statusCode == 200) {
                    var responseJSON: (Any)? = nil
                    do {
                        responseJSON = try JSONSerialization.jsonObject(with: data, options: [])
                    }
                    catch {
                        print("Error: \(error)")
                        self.displayErrorMessage(message: "Something went wrong...")
                    }
                    if let resp = responseJSON as? [String: Any] {
                        self.currencies[resp["base"] as! String] = 1
                        self.baseCurr = (resp["base"] as? String)
                        self.baseCurr = (resp["date"] as? String)
                        if let otherCurr = resp["rates"] as? [String: Any] {
                            for (curr, rate) in otherCurr {
                                self.currencies[curr] = (rate as! Double)
                            }
                        }
                    }
                }
            }
        }

        task.resume()
    }
 
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func displayErrorMessage(message:String) {
        DispatchQueue.main.async {
            let alertView = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            }
            alertView.addAction(OKAction)
            if let presenter = alertView.popoverPresentationController {
                presenter.sourceView = self.view
                presenter.sourceRect = self.view.bounds
            }
            self.present(alertView, animated: true, completion:nil)
        }
    }
    
}
