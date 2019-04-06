import React, { Component } from 'react'
import * as _ from 'lodash'
import axios from 'axios'
import { Col, Row, Card, Container, CardDeck, Button } from 'react-bootstrap'

import { parseMDYDate } from '../util/moment'

interface MyProps {
  selectedUser: object
  toggleLoading: (callback: () => void) => void
}

interface MyState {
  data: { rows: any }
  userId: string
}

class InterestGroups extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      data: { rows: [] },
      userId: '',
    }
  }

  async componentDidMount() {
    await this.fetchInterestGroups()
  }

  async fetchInterestGroups() {
    const { selectedUser } = this.props
    const selectedUserId = _.get(selectedUser, 'userId')
    const { data } = await axios.get(`/interestgroups`, {
      params: {
        userId: selectedUserId,
      },
    })

    this.setState({
      ...data,
      userId: selectedUserId,
    })
  }

  renderInterestGroups(groupList: any) {
    const { selectedUser } = this.props
    const selectedUserId = _.get(selectedUser, 'userId')
    if (selectedUserId != this.state.userId) {
      this.fetchInterestGroups()
    }

    return groupList.map((row: any) => {
      const groupName = _.get(row, 'groupname')
      const groupDescription = _.get(row, 'groupdescription')
      const userId = _.get(row, 'userid')
      const groupJoinDate = _.get(row, 'joindate')

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
              <Card.Title>{groupName}</Card.Title>
              <Card.Text>
                {groupDescription
                  ? groupDescription
                  : 'This group likes to be mysterious...'}
              </Card.Text>
            </Card.Body>
            <Card.Footer>
              {userId === selectedUserId ? (
                `Joined on ${parseMDYDate(groupJoinDate)}`
              ) : (
                <Button variant="light" size="sm">
                  Join Group
                </Button>
              )}
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
          <Col>{this.renderInterestGroups(rows)}</Col>
        </Row>
      </Container>
    )
  }
}

export default InterestGroups
