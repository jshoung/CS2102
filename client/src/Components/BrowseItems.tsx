import React, { Component } from 'react'
import axios from 'axios'
import _ from 'lodash'
import { Col, Row, Card, Container, CardDeck, Button } from 'react-bootstrap'

import ErrorModal from './ErrorModal'

interface MyProps {
  selectedUser: object
  toggleLoading: (callback: () => void) => void
}

interface MyState {
  data: { rows: any }
  errorMessage: string
}

class BrowseItems extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      data: { rows: [] },
      errorMessage: '',
    }
  }

  async componentDidMount() {
    await this.fetchAvailableItems()
  }

  async fetchAvailableItems() {
    const { selectedUser } = this.props

    const { data } = await axios.get(`/items`, {
      params: {
        isListAvailable: true,
      },
    })

    this.setState({ ...data })
  }

  showErrorModal(errorMessage: string) {
    this.setState({ errorMessage: errorMessage })
  }

  async handleBorrowItem(row: any) {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')
    const loanerId = _.get(row, 'userid')
    const itemId = _.get(row, 'itemid')

    await axios
      .post('/users/loans', {
        loanerId: loanerId,
        borrowerId: userId,
        itemId: itemId,
      })
      .catch((error) => {
        this.showErrorModal(error.toString())
      })

    await this.fetchAvailableItems()
  }

  renderAvailableItems(rows: any) {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userid')
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
            <Card.Footer>
              <Button
                variant="light"
                size="sm"
                onClick={() => this.handleBorrowItem(row)}
              >
                Borrow Item
              </Button>
            </Card.Footer>
          </Card>
        </CardDeck>
      )
    })
  }
  render() {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')
    const { rows } = this.state.data

    return (
      <Container>
        <Row style={{ paddingBottom: '20px' }}>
          <Col>{this.renderAvailableItems(rows)}</Col>
        </Row>
        <ErrorModal
          message={this.state.errorMessage}
          closeModal={() => {
            this.setState({ errorMessage: '' })
          }}
        />
      </Container>
    )
  }
}

export default BrowseItems
