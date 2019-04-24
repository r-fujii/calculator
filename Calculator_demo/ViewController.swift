//
//  ViewController.swift
//  Calculator_demo
//
//  Created by Ryo Fujii on 2019/03/28.
//  Copyright © 2019 Ryo Fujii. All rights reserved.
//

import UIKit
import Expression

class TableViewButton: UITableViewCell {
    @IBOutlet weak var hist_button: UIButton!
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var formula_label: UILabel!
    @IBOutlet weak var ans_label: UILabel!
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var history_table: UITableView!
    
    var userDefaults = UserDefaults.standard
    var formula_history: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        formula_label.text = "0"
        ans_label.text = ""
        for button in buttons {
            button.layer.cornerRadius = 5.0
        }
        
        // formula_historyが存在している場合に読み込む
        if UserDefaults.standard.object(forKey: "formula_history") != nil {
            formula_history = UserDefaults.standard.array(forKey: "formula_history") as! [String]
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func update_hist(_ formula: String) {
        formula_history.append(formula)
        history_table.reloadData()
        userDefaults.set(formula_history, forKey: "formula_history")
    }

    @IBAction func input_formula(_ sender: UIButton) {
        // guard文はfalse条件でearly returnさせる
        // 式ラベルの表示テキストを得る
        guard let formula_text = formula_label.text else {
            return
        }
        // ボタンが押されたときにそのラベルの値を得る
        guard let sent_text = sender.titleLabel?.text else {
            return
        }
        
        if formula_text == "0" && sent_text != "." {
            formula_label.text = sent_text
        } else {
            formula_label.text = formula_text + sent_text
        }
    }
    
    @IBAction func undo_formula(_ sender: UIButton) {
        guard let formula_text = formula_label.text else {
            return
        }
        
        if formula_text != "0" {
            formula_label.text = String(formula_text.prefix(formula_text.count - 1))
        }
    }
    
    @IBAction func clear_ans(_ sender: UIButton) {
        formula_label.text = "0"
        ans_label.text = ""
    }
    
    @IBAction func calc_ans(_ sender: UIButton) {
        guard let formula_text = formula_label.text else {
            return
        }
        let formula: String = format_formula(formula_text)
        let ans = eval_formula(formula)
        ans_label.text = ans
        
        // update history
        if ans != "式を正しく入力してください" {
            update_hist(formula_text)
        }
    }
    
    private func format_formula(_ formula: String) -> String {
        // 正規表現を用いてString.replacingOccurrences (replace)
        // 後方参照(pythonでいうところの\1) -> $1
        let formula_w_float: String = formula.replacingOccurrences(of: "(?<=^|[÷×\\+\\-\\(])([0-9]+)(?=[÷×\\+\\-\\)]|$)", with: "$1.0", options: NSString.CompareOptions.regularExpression)
        
        let formatted_formula: String = formula_w_float.replacingOccurrences(of: "÷", with: "/").replacingOccurrences(of: "×", with: "*")
        
        return formatted_formula
    }
    
    private func eval_formula(_ formula: String, round: Bool = false) -> String {
        // 例外処理 (try, except的な)
        do {
            let expression = Expression(formula)
            var ans = try expression.evaluate()
            if round {
                ans.round()
            }
            
            return format_ans(String(ans))
        }
        catch {
            return "式を正しく入力してください"
        }
    }
    
    private func format_ans(_ answer: String) -> String {
        
        let formatted_ans: String = answer.replacingOccurrences(of: "\\.0+", with: "", options: NSString.CompareOptions.regularExpression)
        
        return formatted_ans
    }
    
    @IBAction func calc_tax(_ sender: UIButton) {
        
        // まずその段階での額を計算
        guard let formula_text = formula_label.text else {
            return
        }
        let formula: String = format_formula(formula_text)
        ans_label.text = eval_formula(formula)
        
        // 税込み税抜き処理ここから
        guard let ans_text: String = ans_label.text else {
            return
        }
        switch ans_text {
        case "式を正しく入力してください":
            break // do nothing
        default:
            guard var formula_text: String = formula_label.text else {
                return
            }
            
            // どちらのボタンが押されたか判別
            guard let sent_text = sender.titleLabel?.text else {
                return
            }
            
            if sent_text == "税込" {
                formula_text = "(\(formula_text))×1.08"
            } else {
                formula_text = "(\(formula_text))÷1.08"
            }
            
            let formula: String = format_formula(formula_text)
            
            ans_label.text = eval_formula(formula, round: true)
            formula_label.text = formula_text
            
            update_hist(formula_text)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return formula_history.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TableViewButton = tableView.dequeueReusableCell(withIdentifier: "history", for: indexPath) as! TableViewButton
//        cell.textLabel!.text = formula_history[indexPath.row]
        cell.hist_button.setTitle(formula_history[indexPath.row], for: UIControl.State.normal)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            formula_history.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        userDefaults.set(formula_history, forKey: "formula_history")
    }
    
    @IBAction func read_formula(_ sender: UIButton) {
        guard let formula = sender.titleLabel?.text else {
            return
        }
        
        formula_label.text = formula
    }
    
}

