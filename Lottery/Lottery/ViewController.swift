//
//  ViewController.swift
//  Lottery
//
//  Created by benson on 12/26/16.
//  Copyright © 2016 Benson. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var countDownLabel: UILabel!
    @IBOutlet var winnerImageViews: [UIImageView]!
    @IBOutlet var winnerLabels: [UILabel]!
    @IBOutlet weak var highlightImageView: UIImageView!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet weak var roundLabel: UILabel!
    
    var participants = [String]()
    
    var winners = [String]()
    
    var isRolling = false
    
    var currentPage: Int = 0
    
    fileprivate var pageSize: CGSize {
        let layout = self.collectionView.collectionViewLayout as! UPCarouselFlowLayout
        var pageSize = layout.itemSize
        if layout.scrollDirection == .horizontal {
            pageSize.width += layout.minimumLineSpacing
        } else {
            pageSize.height += layout.minimumLineSpacing
        }
        return pageSize
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupLayout()
        self.refreshParticipants()
    }
    
    fileprivate func setupLayout() {
        let layout = self.collectionView.collectionViewLayout as! UPCarouselFlowLayout
        layout.spacingMode = UPCarouselFlowLayoutSpacingMode.overlap(visibleOffset: 30)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.participants.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CarouselCollectionViewCell.identifier, for: indexPath) as! CarouselCollectionViewCell
        let character = participants[(indexPath as NSIndexPath).row]
        cell.image.image = UIImage(named: character)
        return cell
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        let layout = self.collectionView.collectionViewLayout as! UPCarouselFlowLayout
        let pageSide = (layout.scrollDirection == .horizontal) ? self.pageSize.width : self.pageSize.height
        let offset = (layout.scrollDirection == .horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
        currentPage = Int(floor((offset - pageSide / 2) / pageSide) + 1)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let layout = self.collectionView.collectionViewLayout as! UPCarouselFlowLayout
        let pageSide = (layout.scrollDirection == .horizontal) ? self.pageSize.width : self.pageSize.height
        let offset = (layout.scrollDirection == .horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
        currentPage = Int(floor((offset - pageSide / 2) / pageSide) + 1)
    }
    
    @IBAction func startRolling(_ sender: Any) {
        if !self.isRolling {
            self.isRolling = true
            self.roundLabel.isHidden = false
            self.roundLabel.text = "Round \(self.winners.count + 1)"
            self.collectionView.isUserInteractionEnabled = false
            self.startButton.isUserInteractionEnabled = false
            self.startButton.setTitle("抽奖中", for: .normal)
            // 抽奖倒计时随机
            let countDownSeconds = Double(arc4random_uniform(5) + 15)
            print("倒计时时间:\(countDownSeconds)s")
            var countDownTime = countDownSeconds
            self.countDownLabel.isHidden = false
            self.countDownLabel.text = "\(Int(countDownSeconds))s"
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self](timer) in
                countDownTime -= 1
                self?.countDownLabel.text = "\(Int(countDownTime))s"
                if countDownTime == 0 {
                    timer.invalidate()
                    self?.countDownLabel.isHidden = true
                }
            })
            var elapsedTime = 0.0
            // 转动轮盘
            Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true, block: { [weak self](timer) in
                elapsedTime += 0.8
                if elapsedTime >= countDownSeconds {
                    // 时间到,产生中奖者
                    timer.invalidate()
                    self?.roundLabel.isHidden = true
                    let winnerName = self!.participants[self!.currentPage]
                    self?.winners.append(winnerName)
                    // 展示中奖者
                    self?.highlightImageView.image = UIImage(named: winnerName)
                    UIView.animate(withDuration: 1.5, animations: {
                        self?.highlightImageView.alpha = 1
                    }, completion: { (flag) in
                        self?.delay(3, closure: {
                            UIView.animate(withDuration: 1.5, animations: {
                                self?.highlightImageView.alpha = 0
                            }, completion:{ (flag) in
                                let imageView = self!.winnerImageViews[self!.winners.count - 1]
                                UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                                    imageView.image = UIImage(named: winnerName)
                                }, completion: nil)
                                self?.winnerLabels[self!.winners.count - 1].text = "\(5 - self!.winners.count)等奖\n\(winnerName)"
                                
                                // 刷新数据
                                self?.refreshParticipants()
                            })
                        })
                        
                    })
                    self?.collectionView.isUserInteractionEnabled = true
                    self?.startButton.isUserInteractionEnabled = true
                    self?.isRolling = false
                    if self?.winners.count == 4 {
                        self?.startButton.setTitle("抽奖结束", for: .normal)
                        self?.startButton.isUserInteractionEnabled = false
                        self?.retryButton.isHidden = false
                    } else {
                        self?.startButton.setTitle("下一轮", for: .normal)
                    }
                    return
                }
                let indexPath = IndexPath(item: self!.currentPage + 1, section: 0)
                self?.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
            })
        }
    }
    
    @IBAction func retry(_ sender: UIButton!) {
        sender.isHidden = true
        self.refreshParticipants()
        self.winners.removeAll()
        for (index,iv) in self.winnerImageViews.enumerated() {
            iv.image = UIImage(named: "placeholder\(index + 1)")
        }
        for (index, element) in self.winnerLabels.enumerated() {
            element.text = "\(4 - index)等奖\n?"
        }
        self.startButton.setTitle("开始抽奖", for: .normal)
        self.startButton.isUserInteractionEnabled = true
    }
}

extension ViewController {
    
    func readParticipants() {
        self.participants.removeAll()
        if let list = NSArray(contentsOfFile: Bundle.main.path(forResource: "Roll", ofType: "plist")!) as? [String] {
            // ①-排除已获奖同学
            var newList = list.filter({ (name) -> Bool in
                if self.winners.contains(name) {
                    return false
                } else {
                    return true
                }
            })
            
            for _ in 0...100 {
                var group = [String]()
                for _ in 0...6 {
                    var randomIndex = Int(arc4random_uniform(UInt32(newList.count)))
                    while group.contains(newList[randomIndex]) {
                        randomIndex = Int(arc4random_uniform(UInt32(newList.count)))
                    }
                    group.append(newList[randomIndex])
                }
                self.participants.append(contentsOf: group)
            }
        }
    }
    
    func refreshParticipants() {
        self.readParticipants()
        self.currentPage = 0
        self.collectionView.reloadData()
        self.collectionView.contentOffset = CGPoint.zero
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
}
