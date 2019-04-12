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

class LoanHistory extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      data: { rows: [] },
      userId: '',
    }
  }

  async componentDidMount() {
    await this.fetchLoanHistory()
  }

  async fetchLoanHistory() {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')

    const { data } = await axios.get(`/users/loans`, {
      params: {
        userId: userId,
        isLoaner: true,
      },
    })

    this.setState({ userId: userId, ...data })
  }

  async handleDeclareReturn(invoiceId: string) {
    await axios.patch('users/loanreturn', {
      invoiceId: invoiceId,
      isReturned: true,
    })
    await this.fetchLoanHistory()
  }

  render() {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')

    // Hack to ensure data is updated when changing users
    if (userId != this.state.userId) {
      this.fetchLoanHistory()
    }
    const { rows } = this.state.data
    return rows.map((row: any) => (
      <CardDeck style={{ paddingBottom: '10px' }}>
        <Card
          className="text-center"
          bg="dark"
          text="white"
          border="dark"
          style={{ width: '18rem' }}
        >
          <Card.Body>
            <Card.Title>{`${_.get(row, 'itemname')}`}</Card.Title>
            <Card.Subtitle className={'mb-2'}>{`Loaned to ${_.get(
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
            </Card.Text>
          </Card.Body>
          <Card.Footer>
            {_.get(row, 'isreturned') ? (
              ' Item has been returned'
            ) : (
              <Button
                variant="light"
                size="sm"
                onClick={() =>
                  this.handleDeclareReturn(_.get(row, 'invoiceid'))
                }
              >
                Declare Item Return
              </Button>
            )}
          </Card.Footer>
        </Card>
      </CardDeck>
    ))
  }
}

export default LoanHistory
