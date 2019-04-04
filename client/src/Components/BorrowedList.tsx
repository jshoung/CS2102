import React, { Component } from 'react'
import axios from 'axios'
import _ from 'lodash'
import { Card, CardDeck, Button, OverlayTrigger } from 'react-bootstrap'

import { parseMDYDate } from '../util/moment'

interface MyProps {
  selectedUser: object
  toggleLoading: (callback: () => void) => void
  loadTabData: () => Promise<void>
}

interface MyState {
  data: { rows: any }
}

class BorrowedList extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      data: { rows: [] },
    }
  }

  async componentDidMount() {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')

    const { data } = await axios.get(`/users/loans`, {
      params: {
        userId: userId,
        isLoaner: false,
      },
    })

    this.setState({ ...data })
  }

  async componentDidUpdate() {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')

    const { data } = await axios.get(`/users/loans`, {
      params: {
        userId: userId,
        isLoaner: false,
      },
    })

    this.setState({ ...data })
  }

  renderLoans() {
    return
  }
  render() {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')
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
            <Card.Subtitle />
            <Card.Subtitle>{`Item Owner: ${_.get(row, 'name')}`}</Card.Subtitle>
            <Card.Text>
              {`Start Date: ${parseMDYDate(
                _.get(row, 'startdate'),
              )} End Date: ${parseMDYDate(_.get(row, 'enddate'))}`}{' '}
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
            <div>
              <Button variant="light" size="sm">
                Return Item
              </Button>
            </div>
          </Card.Footer>
        </Card>
      </CardDeck>
    ))
  }
}

export default BorrowedList
