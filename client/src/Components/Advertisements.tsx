import React, { Component } from 'react'
import * as _ from 'lodash'
import moment from 'moment'
import { CardDeck, Card } from 'react-bootstrap'
import Bid from './Bid'
import axios from 'axios'
import { parseMDYLongDate } from '../util/moment'

class Advertisements extends Component<{
  loadTabData: any
  currentUser: any
  items: any
  userList: any
  advertisements: any[]
}> {
  placeBid = async (bid: any, advid: any) => {
    const borrowerId = this.props.currentUser.userId
    const advId = parseInt(advid)
    const bidPrice = parseInt(bid)
    await axios.post('/insertbid', {
      borrowerId,
      advId,
      bidPrice,
    })
    this.props.loadTabData()
  }
  render() {
    const { advertisements, userList, items, currentUser } = this.props
    let content: any[] = []
    advertisements.forEach((advertisement) => {
      const currentDate = moment()
      const userid = _.get(advertisement, 'advertiser')
      const username = userList[userid]
      const itemid = advertisement.itemid
      const itemName = items[itemid].itemname
      const highestBidderId = advertisement.highestbidder
      const highestBidder = userList[highestBidderId]
      const opening = moment(advertisement.openingdate)
      const closing = moment(advertisement.closingdate)
      if (
        currentUser.userId === userid ||
        currentDate.isBefore(opening) ||
        currentDate.isAfter(closing)
      ) {
        return
      }
      let currentBid = null
      if (advertisement.highestbid !== null) {
        currentBid = (
          <Card.Subtitle className={'mb-2'}>
            Current Bid: ${advertisement.highestbid}
          </Card.Subtitle>
        )
      }
      let nextBid = advertisement.minimumprice
      let currentBidder = null
      if (advertisement.highestbidder !== null) {
        currentBidder = <Card.Text>By: {highestBidder}</Card.Text>
        nextBid = advertisement.highestbid + advertisement.minimumincrease
      }
      const bid = (
        <Bid
          advid={advertisement.advid}
          placeBid={this.placeBid}
          nextBid={nextBid}
        />
      )

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
              <Card.Title>{itemName}</Card.Title>
              <Card.Subtitle className={'mb-2'}>
                Minimum Bid: ${advertisement.minimumprice}
              </Card.Subtitle>
              <Card.Text>
                Advertised by: {username}
                <br />
                Bidding Period: {parseMDYLongDate(opening)} to{' '}
                {parseMDYLongDate(closing)}
              </Card.Text>
              {currentBid}
              {currentBidder}
              <Card.Subtitle className={'mb-2'}>
                Next Possible Bid: ${nextBid}
              </Card.Subtitle>
            </Card.Body>
            <Card.Footer>{bid}</Card.Footer>
          </Card>
        </CardDeck>,
      )
    })

    return <div>{content}</div>
  }
}

export default Advertisements
