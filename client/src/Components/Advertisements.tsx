import React, { Component } from 'react'
import * as _ from 'lodash'
import moment from 'moment'
import { CardDeck, Card, Table, Button } from 'react-bootstrap'
import Bid from './Bid'
import axios from 'axios'
import { parseMDYLongDate } from '../util/moment'
import ErrorModal from './ErrorModal'
class Advertisements extends Component<{
  loadTabData: any
  currentUser: any
  items: any
  userList: any
  advertisements: any[]
}> {
  state = {
    bids: [],
    chooses: [],
    errorMessage: '',
  }

  componentDidMount() {
    this.loadData()
  }

  async loadData() {
    const bids = (await axios.get('/bids')).data.data.rows
    const chooses = (await axios.get('/chooses')).data.data.rows
    this.setState({ bids, chooses })
  }

  placeBid = async (bid: any, advid: any) => {
    const borrowerId = this.props.currentUser.userId
    const advId = parseInt(advid)
    const bidPrice = parseInt(bid)
    await axios.post('/insertbid', {
      borrowerId,
      advId,
      bidPrice,
    })
    await this.props.loadTabData()
  }

  showErrorModal(errorMessage: string) {
    this.setState({ errorMessage })
  }

  handleChoose = (
    bidid: any,
    userid: any,
    advid: any,
    existingChoose: any,
  ) => async () => {
    if (existingChoose) {
      await axios.delete('/chooses', {
        data: {
          bidid: existingChoose.bidid,
          userid: existingChoose.userid,
          advid: existingChoose.advid,
        },
      })
    } else {
      await axios
        .post('/chooses', {
          bidid,
          userid,
          advid,
        })
        .catch((error) => {
          this.showErrorModal('Decline your currently chosen bid first!')
        })
    }

    await this.loadData()
    await this.props.loadTabData()
  }

  getChoose = (bidid: any) => {
    const matchingChoose = this.state.chooses.filter(
      (choose) => _.get(choose, 'bidid') === bidid,
    )

    if (!matchingChoose.length) {
      return
    }

    return matchingChoose[0]
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

      if (currentDate.isBefore(opening) || currentDate.isAfter(closing)) {
        return
      }

      if (currentUser.userId === userid) {
        let rows: any[] = []
        this.state.bids.forEach((bid) => {
          const borrowerid: any = _.get(bid, 'borrowerid')
          const existingChoose = this.getChoose(_.get(bid, 'bidid'))
          if (_.get(bid, 'advid') === advertisement.advid) {
            rows.push(
              <tr>
                <td>{userList[borrowerid]}</td>
                <td>{_.get(bid, 'price')}</td>
                <td>{parseMDYLongDate(_.get(bid, 'biddate'))}</td>
                <td>
                  <Button
                    variant={existingChoose ? 'warning' : undefined}
                    onClick={this.handleChoose(
                      _.get(bid, 'bidid'),
                      userid,
                      advertisement.advid,
                      existingChoose,
                    )}
                  >
                    {existingChoose ? 'Decline Bid' : 'Choose Bid'}
                  </Button>
                </td>
              </tr>,
            )
          }
        })

        content.push(
          <CardDeck style={{ paddingBottom: '10px' }}>
            <Card
              className="text-center"
              bg="primary"
              text="white"
              border="dark"
              style={{ width: '18rem' }}
            >
              <Card.Body>
                <Card.Title>{itemName}</Card.Title>
                <Card.Subtitle className={'mb-4'}>
                  Bidding Period: {parseMDYLongDate(opening)} to{' '}
                  {parseMDYLongDate(closing)}
                </Card.Subtitle>
                <Table
                  style={{ borderRadius: '6px' }}
                  variant={'dark'}
                  responsive
                  hover
                >
                  <thead>
                    <tr>
                      <th>Bidder</th>
                      <th>Bid Amount</th>
                      <th>Bid Date</th>
                      <th>Bid Action</th>
                    </tr>
                  </thead>
                  <tbody>{rows}</tbody>
                </Table>
              </Card.Body>
            </Card>
          </CardDeck>,
        )
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
                Advertised By: {username}
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

    return (
      <div>
        {content}
        <ErrorModal
          message={this.state.errorMessage}
          closeModal={() => {
            this.setState({ errorMessage: '' })
          }}
        />
      </div>
    )
  }
}

export default Advertisements
