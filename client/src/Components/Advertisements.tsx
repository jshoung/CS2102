import React, { Component } from 'react'
import { CardDeck, Card, Button, Form } from "react-bootstrap";
import Bid from './Bid';
import axios from 'axios';

class Adverisements extends Component<{ loadTabData:any, currentUser:any, items: any[], userList: any[], advertisements: any[] }> {
  placeBid = async (bid:any, advid:any) => {
    const borrowerId = this.props.currentUser.userId
    const advId = parseInt(advid)
    const bidPrice = parseInt(bid)
    await axios.post("/insertbid", {
      borrowerId,
      advId,
      bidPrice,
    })
    this.props.loadTabData()
  }
  render() {
    const { advertisements, userList, items, currentUser } = this.props;
    let content: any[] = [];
    advertisements.forEach(advertisement => {
      const currentDate = new Date()
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
      let bid = null;
      if (currentUser.userId == userid) {
        bid = <h3>You can't bid for your own items!</h3>
      } else if (currentDate < opening || currentDate > closing) {
        bid = <h3>Closed for bidding!</h3>
      } else {
        bid = <Bid advid={advertisement.advid} placeBid={this.placeBid} nextBid={advertisement.highestbid + advertisement.minimumincrease} />
      }
      
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
                <br />
                Bidding Time: {openingDate} to {closingDate}
              </Card.Text>
              <Card.Subtitle>Current Bid: ${advertisement.highestbid}</Card.Subtitle>
              <Card.Text>
                By: {highestBidder}
              </Card.Text>
              <Card.Subtitle>Next Possible Bid: ${advertisement.highestbid + advertisement.minimumincrease}</Card.Subtitle>
            </Card.Body>
            <Card.Footer>
              {bid}
            </Card.Footer>
          </Card>
        </CardDeck>)
    });
    return (
      <div>
        {content}
      </div>
    );
  }
}

export default Adverisements