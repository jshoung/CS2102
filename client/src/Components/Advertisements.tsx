import React, { Component } from 'react'
import { CardDeck, Card } from "react-bootstrap";

class Adverisements extends Component<{items: any[], userList:any[], advertisements: any[]}> {
	render() {
		const { advertisements, userList, items } = this.props;
		let content:any[] = [];
		advertisements.forEach(advertisement => {
			const userid = advertisement.advertiser
			const username = userList[userid - 1].props.children
			const itemid = advertisement.itemid
			const itemName = items[itemid - 1].itemname
			const highestBidderId = advertisement.highestbidder
			const highestBidder = userList[highestBidderId - 1].props.children
			const opening = new Date(advertisement.openingdate)
			const closing = new Date(advertisement.closingdate)
			const openingDate = opening.getDate() + "/" + (opening.getMonth() + 1) + "/" + opening.getFullYear()
			const closingDate = closing.getDate() + "/" + (closing.getMonth() + 1) + "/" + closing.getFullYear()
			content.push(
			<CardDeck style={{ paddingBottom: '10px' }}>
              <Card
                className="text-center"
                bg="dark"
                text="white"
                border="dark"
                style={{ width: '18rem' }}
              >
                <Card.Body>
                  <Card.Title>
                    {itemName}
                  </Card.Title>
                  <Card.Subtitle>Minimum Price: ${advertisement.minimumprice}</Card.Subtitle>
                  <Card.Text>
					Advertised by: {username}
					<br/>
					Bidding Time: {openingDate} to {closingDate}
                  </Card.Text>
                  <Card.Subtitle>Current Bid: ${advertisement.highestbid}</Card.Subtitle>
				  <Card.Text>
                    By: {highestBidder}
                  </Card.Text>
                  <Card.Subtitle>Next Bid: ${advertisement.highestbid + advertisement.minimumincrease}</Card.Subtitle>
                </Card.Body>
                <Card.Footer>
                  <div>
                    {/* <Button variant="light" size="sm">
                      Put Up For Loan
                    </Button> */}
                  </div>
                </Card.Footer>
              </Card>
            </CardDeck>)
		});
		return(
			<div>
				{content}
			</div>
		);
	}
}

export default Adverisements