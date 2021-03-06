//
//  CustomRecurrenceViewController.swift
//  RecurrencePicker
//
//  Created by Xin Hong on 16/4/7.
//  Copyright © 2016年 Teambition. All rights reserved.
//

import UIKit
import EventKit
//import RRuleSwift

internal protocol CustomRecurrenceViewControllerDelegate: class {
    func customRecurrenceViewController(_ controller: CustomRecurrenceViewController, didPickRecurrence recurrenceRule: RecurrenceRule)
}

internal class CustomRecurrenceViewController: UITableViewController {

    internal weak var delegate: CustomRecurrenceViewControllerDelegate?
    internal var occurrenceDate: Date!
    internal var tintColor: UIColor!
	var recurrenceRule: RecurrenceRule!
	var initialStateRecurrenceRule: RecurrenceRule!
    internal var backgroundColor: UIColor?
    internal var separatorColor: UIColor?
    internal var supportedFrequencies = Constant.frequencies
    internal var maximumInterval = Constant.pickerMaxRowCount

    fileprivate var isShowingPickerView = false
    fileprivate var pickerViewStyle: PickerViewCellStyle = .frequency

	open var viewDidAppear = false
	open var interactionController: UIPercentDrivenInteractiveTransition?

    fileprivate var isShowingFrequencyPicker: Bool {
        return isShowingPickerView && pickerViewStyle == .frequency
    }
    fileprivate var isShowingIntervalPicker: Bool {
        return isShowingPickerView && pickerViewStyle == .interval
    }
    fileprivate var frequencyCell: UITableViewCell? {
        return tableView.cellForRow(at: IndexPath(row: 0, section: 0))
    }
    fileprivate var intervalCell: UITableViewCell? {
        return isShowingFrequencyPicker ? tableView.cellForRow(at: IndexPath(row: 2, section: 0)) : tableView.cellForRow(at: IndexPath(row: 1, section: 0))
    }

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
		self.view.backgroundColor = .clear
		self.tableView.backgroundColor = .clear
		self.tableView.separatorStyle = .singleLine
		self.tableView.separatorColor = UIColor.clear
		self.tableView.isHidden = true
		self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)

        let bundle = Bundle(identifier: "Teambition.RecurrencePicker") ?? Bundle.main
        tableView.register(UINib(nibName: "PickerViewCell", bundle: bundle), forCellReuseIdentifier: CellID.pickerViewCell)
        tableView.register(UINib(nibName: "MonthOrDaySelectorCell", bundle: bundle), forCellReuseIdentifier: CellID.monthOrDaySelectorCell)
		NTCTwoLAbelHorizonatalTableViewCell.registerCellForTableView(self.tableView, identifier: "NTCTwoLAbelHorizonatalTableViewCell")
		NTCNotifyMeTableViewCell.registerCellForTableView(self.tableView)
    }

	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated)
		if viewDidAppear == false {
			viewDidAppear = true
			setUIForOrientation()
			fadeOut()
		}
	}

	fileprivate func fadeOut() {
		self.tableView.isHidden = true
		let transitionOptions: UIViewAnimationOptions = [.curveEaseIn]

		UIView.transition(with: self.tableView, duration: 0.5, options: transitionOptions, animations: {
			self.tableView.isHidden = false
		})
	}

	final func setUIForOrientation()
	{
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			// iPhone
			self.tableView.backgroundColor = UIColor.clear
			self.tableView.layer.cornerRadius = 0.0
			self.tableView.separatorColor = UIColor.white.withAlphaComponent(0.08)
		}else {
			self.tableView.backgroundColor = CMViewUtilities.shared().ipadCalFormSheetColor
			self.tableView.layer.cornerRadius = 5.0
			self.tableView.separatorColor = UIColor.black.withAlphaComponent(0.08)

		}
		self.tableView.reloadData()
	}

	@objc func doneButtonTappedForParentVC() {
		delegate?.customRecurrenceViewController(self, didPickRecurrence: recurrenceRule)
	}
}

extension CustomRecurrenceViewController {
    // MARK: - Table view helper
    fileprivate func isPickerViewCell(at indexPath: IndexPath) -> Bool {
        guard indexPath.section == 0 && isShowingPickerView else {
            return false
        }
        return pickerViewStyle == .frequency ? indexPath.row == 1 : indexPath.row == 2
    }

    fileprivate func isSelectorViewCell(at indexPath: IndexPath) -> Bool {
        guard recurrenceRule.frequency == .monthly || recurrenceRule.frequency == .yearly else {
            return false
        }
        return indexPath == IndexPath(row: 0, section: 1)
    }

    fileprivate func unfoldPickerView() {
        switch pickerViewStyle {
        case .frequency:
            tableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .fade)
        case .interval:
            tableView.insertRows(at: [IndexPath(row: 2, section: 0)], with: .fade)
        }
    }

    fileprivate func foldPickerView() {
        switch pickerViewStyle {
        case .frequency:
            tableView.deleteRows(at: [IndexPath(row: 1, section: 0)], with: .fade)
        case .interval:
            tableView.deleteRows(at: [IndexPath(row: 2, section: 0)], with: .fade)
        }
    }

    fileprivate func updateSelectorSection(with newFrequency: RecurrenceFrequency) {
        tableView.beginUpdates()
        switch newFrequency {
        case .daily:
            if tableView.numberOfSections == 2 {
                tableView.deleteSections(IndexSet(integer: 1), with: .fade)
            }
        case .weekly, .monthly, .yearly:
            if tableView.numberOfSections == 1 {
                tableView.insertSections(IndexSet(integer: 1), with: .fade)
            } else {
                tableView.reloadSections(IndexSet(integer: 1), with: .fade)
            }
        default:
            break
        }
        tableView.endUpdates()
    }

    fileprivate func unitStringForIntervalCell() -> String {
        if recurrenceRule.interval == 1 {
            return Constant.unitStrings()[recurrenceRule.frequency.number]
        }
        return String(recurrenceRule.interval) + " " + Constant.pluralUnitStrings()[recurrenceRule.frequency.number]
    }

    fileprivate func updateFrequencyCellText() {
		if self.frequencyCell != nil && self.frequencyCell!.isKind(of: NTCTwoLAbelHorizonatalTableViewCell.self) {
			(self.frequencyCell as! NTCTwoLAbelHorizonatalTableViewCell).label2.text = Constant.frequencyStrings()[recurrenceRule.frequency.number]
		}
    }

    fileprivate func updateIntervalCellText() {
		if self.intervalCell != nil && self.intervalCell!.isKind(of: NTCTwoLAbelHorizonatalTableViewCell.self) {
			(self.intervalCell as! NTCTwoLAbelHorizonatalTableViewCell).label2.text = unitStringForIntervalCell()
		}
    }

    fileprivate func updateRecurrenceRuleText() {
        let footerView = tableView.footerView(forSection: 0)

        tableView.beginUpdates()
		if let ruleText = recurrenceRule.toText(occurrenceDate: occurrenceDate) {
			footerView?.textLabel?.text = "\n" + ruleText
		}else {
			footerView?.textLabel?.text = ""
		}
		if footerView != nil {
			var frameOfFooter = footerView!.bounds
			frameOfFooter.origin.x  = NTCLayoutDetector().currentLayout().shouldUseIphoneUI ? -5 : -20
			footerView!.bounds = frameOfFooter
		}
        tableView.endUpdates()
        footerView?.setNeedsLayout()
    }
}

extension CustomRecurrenceViewController {
    // MARK: - Table view data source and delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        if recurrenceRule.frequency == .daily {
            return 1
        }
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return isShowingPickerView ? 3 : 2
        } else {
            switch recurrenceRule.frequency {
            case .weekly: return Constant.weekdaySymbols().count
            case .monthly, .yearly: return 1
            default: return 0
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isPickerViewCell(at: indexPath) {
            return Constant.pickerViewCellHeight
        } else if isSelectorViewCell(at: indexPath) {
            let style: MonthOrDaySelectorStyle = recurrenceRule.frequency == .monthly ? .day : .month
            let itemHeight = GridSelectorLayout.itemSize(with: style, selectorViewWidth: tableView.frame.width).height
            let itemCount: CGFloat = style == .day ? 5 : 3
            return ceil(itemHeight * itemCount) + Constant.selectorVerticalPadding * CGFloat(2)
        }
        return Constant.defaultRowHeight
    }


	open override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if section == 0 {
			return 121
		}
		return 0
	}

	 override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView:UIView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 121))
		if section != 0 {
			headerView.frame = CGRect.zero
			return headerView
		}

		return headerView;
	}

	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if section == 0 {
			if let ruleText = recurrenceRule.toText(occurrenceDate: occurrenceDate) {
				return "\n" + ruleText
			}else {
				return nil
			}
		}
		return nil
	}

	override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
	{
		let footer : UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
		if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
			footer.textLabel?.textColor = UIColor.white.withAlphaComponent(0.8)
			footer.textLabel?.font = NTCFont.systemFont(ofSize: 13, weight: .Regular)
		}else {
			footer.textLabel?.textColor = UIColor.black.withAlphaComponent(0.8)
			footer.textLabel?.font = NTCFont.systemFont(ofSize: 15, weight: .Regular)
		}
		// patch for origin -x
		var frameOfFooter = footer.bounds
		frameOfFooter.origin.x  = NTCLayoutDetector().currentLayout().shouldUseIphoneUI ? -5 : -20
		footer.bounds = frameOfFooter

		if let ruleText = recurrenceRule.toText(occurrenceDate: occurrenceDate) {
			footer.textLabel?.text = "\n" + ruleText + "\n"
		}else {
			footer.textLabel?.text = ""
		}
	}
    

    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath)
        cell!.contentView.backgroundColor = UIColor.black.withAlphaComponent(0.1)

    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath)
        cell!.contentView.backgroundColor = .clear
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isPickerViewCell(at: indexPath) {
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.pickerViewCell, for: indexPath) as! PickerViewCell
            cell.delegate = self

            cell.style = pickerViewStyle
            cell.frequency = recurrenceRule.frequency
            cell.interval = recurrenceRule.interval
            let supportedFrequencies: [RecurrenceFrequency] = {
                let frequencies = self.supportedFrequencies.filter { Constant.frequencies.contains($0) }.sorted { $0.number < $1.number }
                return frequencies.isEmpty ? Constant.frequencies : frequencies
            }()
            cell.supportedFrequencies = supportedFrequencies
            cell.maximumInterval = max(maximumInterval, 1)

            return cell
        } else if isSelectorViewCell(at: indexPath) {
            let cell = tableView.dequeueReusableCell(withIdentifier: CellID.monthOrDaySelectorCell, for: indexPath) as! MonthOrDaySelectorCell
            cell.delegate = self

            cell.tintColor = tintColor
            cell.style = recurrenceRule.frequency == .monthly ? .day : .month
            cell.bymonthday = recurrenceRule.bymonthday
            cell.bymonth = recurrenceRule.bymonth

            return cell
        } else if indexPath.section == 0 {

			let cell = NTCTwoLAbelHorizonatalTableViewCell.reusableCellForTableView(tableView, indexPath: indexPath)
			if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
				cell.backgroundColor = UIColor.white.withAlphaComponent(0.04)
			}else{
				cell.backgroundColor = UIColor.black.withAlphaComponent(0.04)
			}

			cell.accessoryType = .none
			cell.selectionStyle = .none

            if indexPath.row == 0 {
                cell.label1.text = LocalizedString("CustomRecurrenceViewController.textLabel.frequency")
                cell.label2.text = Constant.frequencyStrings()[recurrenceRule.frequency.number]
            } else {
                cell.label1.text = LocalizedString("CustomRecurrenceViewController.textLabel.interval")
                cell.label2.text = unitStringForIntervalCell()
            }
			cell.label1.backgroundColor = UIColor.clear
			cell.label2.backgroundColor = UIColor.clear
            return cell
        } else {

			let cell = NTCNotifyMeTableViewCell.reusableCellForTableView(tableView, indexPath: indexPath)
			if NTCLayoutDetector().currentLayout().shouldUseIphoneUI {
				cell.backgroundColor = UIColor.white.withAlphaComponent(0.04)
			}else{
				cell.backgroundColor = UIColor.black.withAlphaComponent(0.04)
			}

			cell.accessoryType = .none
			cell.titleLabel.text = Constant.weekdaySymbols()[indexPath.row]

			if recurrenceRule.byweekday.contains(Constant.weekdays[indexPath.row]) {
				cell.tickIcon.isHidden = false
			} else {
				cell.tickIcon.isHidden = true
			}

			return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isPickerViewCell(at: indexPath) else {
            return
        }
        guard !isSelectorViewCell(at: indexPath) else {
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.section == 0 {
            
            if indexPath.row == 0 {
                if isShowingFrequencyPicker {
                    tableView.beginUpdates()
                    isShowingPickerView = false
                    foldPickerView()
                    tableView.endUpdates()
                } else {
                    tableView.beginUpdates()
                    if isShowingIntervalPicker {
                        foldPickerView()
                    }
                    isShowingPickerView = true
                    pickerViewStyle = .frequency
                    unfoldPickerView()
                    tableView.endUpdates()
                }
            } else {
                if isShowingIntervalPicker {
                    tableView.beginUpdates()
                    isShowingPickerView = false
                    foldPickerView()
                    tableView.endUpdates()
                } else {
                    tableView.beginUpdates()
                    if isShowingFrequencyPicker {
                        foldPickerView()
                    }
                    isShowingPickerView = true
                    pickerViewStyle = .interval
                    unfoldPickerView()
                    tableView.endUpdates()
                }
            }
        } else if indexPath.section == 1 {
            if isShowingPickerView {
                tableView.beginUpdates()
                isShowingPickerView = false
                foldPickerView()
                tableView.endUpdates()
            }

            let weekday = Constant.weekdays[indexPath.row]
            if recurrenceRule.byweekday.contains(weekday) {
                if recurrenceRule.byweekday == [weekday] {
                    return
                }
                let index = recurrenceRule.byweekday.index(of: weekday)!
                recurrenceRule.byweekday.remove(at: index)
				(cell as! NTCNotifyMeTableViewCell).tickIcon.isHidden = true
                updateRecurrenceRuleText()
            } else {
                recurrenceRule.byweekday.append(weekday)
				(cell as! NTCNotifyMeTableViewCell).tickIcon.isHidden = false

                updateRecurrenceRuleText()
            }
        }
    }
}

extension CustomRecurrenceViewController: PickerViewCellDelegate {
    func pickerViewCell(_ cell: PickerViewCell, didSelectFrequency frequency: RecurrenceFrequency) {
        recurrenceRule.frequency = frequency

        updateFrequencyCellText()
        updateIntervalCellText()
        updateSelectorSection(with: frequency)
        updateRecurrenceRuleText()
    }

    func pickerViewCell(_ cell: PickerViewCell, didSelectInterval interval: Int) {
        recurrenceRule.interval = interval

        updateIntervalCellText()
        updateRecurrenceRuleText()
    }
}

extension CustomRecurrenceViewController: MonthOrDaySelectorCellDelegate {
    func monthOrDaySelectorCell(_ cell: MonthOrDaySelectorCell, didSelectMonthday monthday: Int) {
        if isShowingPickerView {
            tableView.beginUpdates()
            isShowingPickerView = false
            foldPickerView()
            tableView.endUpdates()
        }
        recurrenceRule.bymonthday.append(monthday)
        updateRecurrenceRuleText()
    }

    func monthOrDaySelectorCell(_ cell: MonthOrDaySelectorCell, didDeselectMonthday monthday: Int) {
        if isShowingPickerView {
            tableView.beginUpdates()
            isShowingPickerView = false
            foldPickerView()
            tableView.endUpdates()
        }
        if let index = recurrenceRule.bymonthday.index(of: monthday) {
            recurrenceRule.bymonthday.remove(at: index)
            updateRecurrenceRuleText()
        }
    }

    func monthOrDaySelectorCell(_ cell: MonthOrDaySelectorCell, shouldDeselectMonthday monthday: Int) -> Bool {
        return recurrenceRule.bymonthday.count > 1
    }

    func monthOrDaySelectorCell(_ cell: MonthOrDaySelectorCell, didSelectMonth month: Int) {
        if isShowingPickerView {
            tableView.beginUpdates()
            isShowingPickerView = false
            foldPickerView()
            tableView.endUpdates()
        }
        recurrenceRule.bymonth.append(month)
        updateRecurrenceRuleText()
    }

    func monthOrDaySelectorCell(_ cell: MonthOrDaySelectorCell, didDeselectMonth month: Int) {
        if isShowingPickerView {
            tableView.beginUpdates()
            isShowingPickerView = false
            foldPickerView()
            tableView.endUpdates()
        }
        if let index = recurrenceRule.bymonth.index(of: month) {
            recurrenceRule.bymonth.remove(at: index)
            updateRecurrenceRuleText()
        }
    }

    func monthOrDaySelectorCell(_ cell: MonthOrDaySelectorCell, shouldDeselectMonth month: Int) -> Bool {
        return recurrenceRule.bymonth.count > 1
    }

	func checkIfDiscardAlertNeedsToBeshown() {
		let initialrRuleString = initialStateRecurrenceRule.toRRuleString()
		let currentrRuleString = recurrenceRule.toRRuleString()

		if initialrRuleString != currentrRuleString {

			let cancel = NTAlert.Action.cancel()
			let ok = NTAlert.Action(title: "OK".localizedUppercaseString, action: {
				self.navigationController?.popViewController(animated: false)
			}, isDestructive: false, isCancel: false)
			NTAlert(title: "Discard Changes?", message: "Are you sure you want to discard the changes?", actions: [cancel, ok], showAsSheet: false).show(on: self)
		}else {
			self.navigationController?.popViewController(animated: false)
		}
	}
}

extension CustomRecurrenceViewController {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
			self.setUIForOrientation()
            }) { (_) in
                let frequency = self.recurrenceRule.frequency
                if frequency == .monthly || frequency == .yearly {
                    if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? MonthOrDaySelectorCell {
                        cell.style = frequency == .monthly ? .day : .month
                    }
                }
        }
    }
}
