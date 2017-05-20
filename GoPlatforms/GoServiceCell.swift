//
//  GoServiceCell.swift
//  GoPlatforms
//
//  Created by Kevin Stewart on 2017-05-20.
//  Copyright © 2017 Kevin Stewart. All rights reserved.
//

import UIKit

class GoServiceCell: UITableViewCell {
    
    @IBOutlet weak var departureTimeLabel: UILabel!
    @IBOutlet weak var routeLabel: UILabel!
    @IBOutlet weak var vehicleTypeLabel: UILabel!
    @IBOutlet weak var platformLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(service: GoService) {
        departureTimeLabel.text = DateFormatter.timeFormatter.string(from: service.departureTime)
        routeLabel.text = service.route
        vehicleTypeLabel.text = service.vehicleType == .bus ? "🚍" : "🚂"
        if let platform = service.platform {
            platformLabel.text = String(describing: platform)
        } else {
            platformLabel.text = "-"
        }
    }
    
}
