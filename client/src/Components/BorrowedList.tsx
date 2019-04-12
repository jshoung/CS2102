import React, { Component } from 'react'
import axios from 'axios'
import _ from 'lodash'
import { Card, CardDeck, Button, OverlayTrigger } from 'react-bootstrap'

import { parseMDYLongDate } from '../util/moment'

interface MyProps {
  selectedUser: object
  toggleLoading: (callback: () => void) => void
  loadTabData: () => Promise<void>
}

interface MyState {
  data: { rows: any }
  userId: string
}

class BorrowedList extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      data: { rows: [] },
      userId: '',
    }
  }

  async componentDidMount() {
    await this.fetchBorrowedItems()
  }

  async fetchBorrowedItems() {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')

    const { data } = await axios.get(`/users/loans`, {
      params: {
        userId: userId,
        isLoaner: false,
      },
    })

    this.setState({ userId: userId, ...data })
  }

  render() {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')

    // Hack to ensure data is updated when changing users
    if (userId != this.state.userId) {
      this.fetchBorrowedItems()
    }
    const { rows } = this.state.data
    return rows.map((row: any) => (
      <CardDeck style={{ paddingBottom: '10px' }}>
        <Card
          className="text-center"
          bg="primary"
          text="white"
          border="dark"
          style={{ width: '18rem' }}
        >
          <Card.Body>
            <Card.Title>{`${_.get(row, 'itemname')}`}</Card.Title>
            <Card.Subtitle className={'mb-2'}>{`Borrowed from ${_.get(
              row,
              'name',
            )}`}</Card.Subtitle>
            <Card.Text>
              {`Start Date: ${parseMDYLongDate(
                _.get(row, 'startdate'),
              )} End Date: ${parseMDYLongDate(_.get(row, 'enddate'))}`}{' '}
              <br />
              {`Loan Fee: ${_.get(row, 'loanfee')} Penalty: ${_.get(
                row,
                'penalty',
              )}`}{' '}
              <br />
              Item Description: {_.get(row, 'itemdescription')}
            </Card.Text>
          </Card.Body>
          <Card.Footer>
            {_.get(row, 'isreturned') ? (
              'Item has been returned'
            ) : (
              <strong>You have yet to return this item!</strong>
            )}
          </Card.Footer>
        </Card>
      </CardDeck>
    ))
  }
}

export default BorrowedList
