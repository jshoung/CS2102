import React, { Component } from 'react'
import * as _ from 'lodash'
import axios from 'axios'
import {
  Col,
  Row,
  Card,
  Container,
  CardDeck,
  Button,
  Form,
} from 'react-bootstrap'

import { parseMDYLongDate } from '../util/moment'
import ErrorModal from './ErrorModal'
import CreateInterestGroup from './InterestGroupForm'

interface MyProps {
  selectedUser: object
  toggleLoading: (callback: () => void) => void
}

interface MyState {
  data: { rows: any }
  userId: string
  errorMessage: string
  isCreating: boolean
}

class UserInterestGroups extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      data: { rows: [] },
      userId: '',
      errorMessage: '',
      isCreating: false,
    }

    this.toggleCreateGroupForm = this.toggleCreateGroupForm.bind(this)
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
    await axios
      .delete('/joins', {
        params: {
          userId,
          groupName,
        },
      })
      .catch((error) => {
        this.setState({ errorMessage: error.response.data.errors.hint })
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
      const groupAdminId = _.get(row, 'groupadminid')

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
              {groupAdminId === userId
                ? `You created this group`
                : `Joined on ${parseMDYLongDate(groupJoinDate)}`}

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

  toggleCreateGroupForm() {
    this.setState({ isCreating: !this.state.isCreating })
  }

  render() {
    const { selectedUser, toggleLoading } = this.props
    const userId = _.get(selectedUser, 'userId')
    const { rows } = this.state.data

    // Hack to ensure data is updated when changing users
    if (userId != this.state.userId) {
      this.fetchInterestGroups()
    }

    return (
      <Container>
        <Row
          style={{
            display: 'flex',
            paddingBottom: '10px',
            justifyContent: 'space-around',
          }}
        >
          {this.state.isCreating ? (
            <CreateInterestGroup
              isEditing={false}
              toggleLoading={toggleLoading}
              selectedUser={selectedUser}
              cancelCreateGroup={this.toggleCreateGroupForm}
            />
          ) : (
            <Button
              className="text-center"
              style={{ flex: '1 1 100%' }}
              variant="outline-secondary"
              onClick={this.toggleCreateGroupForm}
            >
              Create New Group
            </Button>
          )}
        </Row>
        <ErrorModal
          message={this.state.errorMessage}
          closeModal={() => {
            this.setState({ errorMessage: '' })
          }}
        />
        <Row style={{ paddingBottom: '20px' }}>
          <Col>{this.renderUserInterestGroups(rows)}</Col>
        </Row>
      </Container>
    )
  }
}

export default UserInterestGroups
