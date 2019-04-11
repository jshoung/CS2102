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
  Popover,
  OverlayTrigger,
} from 'react-bootstrap'
import * as Icon from 'react-feather'

import { parseMDYLongDate } from '../util/moment'
import ErrorModal from './ErrorModal'
import CreateGroupForm from './CreateGroupForm'
import EditGroupForm from './EditGroupForm'

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
    this.showErrorModal = this.showErrorModal.bind(this)
    this.fetchInterestGroups = this.fetchInterestGroups.bind(this)
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
        this.showErrorModal(error.response.data.errors.hint)
      })

    this.fetchInterestGroups()
  }

  showErrorModal(errorMessage: string) {
    this.setState({ errorMessage: errorMessage })
  }

  renderUserInterestGroups(groupList: any) {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')

    return groupList.map((row: any) => {
      const groupName = _.get(row, 'groupname')
      const groupDescription = _.get(row, 'groupdescription')
      const groupJoinDate = _.get(row, 'joindate')
      const groupCreationDate = _.get(row, 'creationdate')
      const groupAdminId = _.get(row, 'groupadminid')

      const popover = (
        <Popover
          id="popover-basic"
          title="Edit Group Details"
          style={{ width: '18rem' }}
        >
          <EditGroupForm
            groupDescription={groupDescription}
            groupName={groupName}
            groupAdminId={groupAdminId}
            selectedUser={selectedUser}
            showErrorModal={this.showErrorModal}
            fetchInterestGroups={this.fetchInterestGroups}
          />
        </Popover>
      )

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
              <Card.Title>
                {groupName}{' '}
                <OverlayTrigger
                  rootClose={true}
                  trigger="click"
                  placement="auto"
                  overlay={popover}
                >
                  <Icon.Edit style={{ cursor: 'pointer' }} />
                </OverlayTrigger>
              </Card.Title>
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
                ? `You created this group on ${parseMDYLongDate(
                    groupCreationDate,
                  )}`
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
    this.fetchInterestGroups()
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
            <CreateGroupForm
              isEditing={false}
              toggleLoading={toggleLoading}
              selectedUser={selectedUser}
              toggleCreateGroup={this.toggleCreateGroupForm}
            />
          ) : (
            <Button
              className="text-center"
              style={{ width: '97%' }}
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
