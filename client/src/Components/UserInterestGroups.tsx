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

class UserInterestGroups extends Component<MyProps, MyState> {
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
    const userId = _.get(selectedUser, 'userId')

    const { data } = await axios.get('/users/interestgroups', {
      params: {
        userId,
      },
    })

    this.setState({
      ...data,
      userId,
    })
  }

  async leaveGroup(groupName: string, userId: string) {
    await axios.delete('/users/interestgroups', {
      params: {
        userId,
        groupName,
      },
    })

    this.fetchInterestGroups()
  }

  renderUserInterestGroups(groupList: any) {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')

    return groupList.map((row: any) => {
      const groupName = _.get(row, 'groupname')
      const groupDescription = _.get(row, 'groupdescription')
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
            <Card.Footer
              style={{ display: 'flex', justifyContent: 'space-between' }}
            >
              You joined this group on {parseMDYDate(groupJoinDate)}
              <Button
                onClick={() => this.leaveGroup(groupName, userId)}
                variant="outline-danger"
                size="sm"
              >
                Leave Group
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

    // Hack to ensure data is updated when changing users
    if (userId != this.state.userId) {
      this.fetchInterestGroups()
    }

    return (
      <Container>
        <Row style={{ paddingBottom: '20px' }}>
          <Col>{this.renderUserInterestGroups(rows)}</Col>
        </Row>
      </Container>
    )
  }
}

export default UserInterestGroups
