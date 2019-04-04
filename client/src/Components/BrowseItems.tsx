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

class BrowseItems extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      data: { rows: [] },
    }
  }

  async componentDidMount() {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')

    const { data } = await axios.post(`/users/items`, {
      userId: userId,
      isListAvailable: true,
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
    return rows.map((row: any) => {
      const itemDescription = _.get(row, 'itemdescription')

      return (
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
              <Card.Subtitle>
                {`Item Owner: ${_.get(row, 'ownername')}`} <br />
                Price: ${_.get(row, 'value')}
              </Card.Subtitle>
              <Card.Text>
                Item Description: {itemDescription ? itemDescription : ' - '}
              </Card.Text>
            </Card.Body>
          </Card>
        </CardDeck>
      )
    })
  }
}

export default BrowseItems
