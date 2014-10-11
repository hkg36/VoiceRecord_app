//
//  NotifyCell.swift
//  test_swift
//
//  Created by xinchen on 14-10-8.
//  Copyright (c) 2014年 co.po. All rights reserved.
//

import UIKit

class NotifyCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var title: UILabel!
}
