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
import EventForm from './EventForm'
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

class UserEvents extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      data: { rows: [] },
      userId: '',
      errorMessage: '',
      isCreating: false,
    }

    this.toggleEventForm = this.toggleEventForm.bind(this)
    this.showErrorModal = this.showErrorModal.bind(this)
    this.fetchUserEvents = this.fetchUserEvents.bind(this)
  }

  async componentDidMount() {
    await this.fetchUserEvents()
  }

  async fetchUserEvents() {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')

    const { data } = await axios.get('/users/events', {
      params: {
        userId,
      },
    })

    this.setState({
      ...data,
      userId,
    })
  }

  async handleDeleteGroup(groupName: string) {
    await axios
      .delete('/interestgroups', {
        params: {
          groupName,
        },
      })
      .catch((error) => {
        this.showErrorModal(error.response.data.errors.hint)
      })

    this.fetchUserEvents()
  }

  showErrorModal(errorMessage: string) {
    this.setState({ errorMessage: errorMessage })
  }

  renderUserEvents(eventList: any) {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')

    return eventList.map((row: any) => {
      const eventName = _.get(row, 'eventname')
      const organizer = _.get(row, 'organizer')
      const eventDate = _.get(row, 'eventdate')
      const venue = _.get(row, 'venue')

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
                {eventName} <Icon.Edit style={{ cursor: 'pointer' }} />
              </Card.Title>
              <Card.Subtitle>{`Organized by ${organizer} `}</Card.Subtitle>
              <Card.Text>
                {`Date of Event: ${parseMDYLongDate(eventDate)}`} <br />
                {`Venue: ${venue}`}
              </Card.Text>
            </Card.Body>
            <Card.Footer
              style={{ display: 'inline-flex', justifyContent: 'flex-end' }}
            >
              <Button
                onClick={() => this.handleDeleteGroup(eventName)}
                variant="danger"
                size="sm"
              >
                Delete Event
              </Button>
            </Card.Footer>
          </Card>
        </CardDeck>
      )
    })
  }

  toggleEventForm() {
    this.setState({ isCreating: !this.state.isCreating })
    this.fetchUserEvents()
  }

  render() {
    const { selectedUser, toggleLoading } = this.props
    const userId = _.get(selectedUser, 'userId')
    const { rows } = this.state.data

    // Hack to ensure data is updated when changing users
    if (userId != this.state.userId) {
      this.fetchUserEvents()
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
            <EventForm
              isEditing={false}
              toggleLoading={toggleLoading}
              selectedUser={selectedUser}
              toggleCreateEvent={this.toggleEventForm}
              rows={rows}
            />
          ) : (
            <Button
              className="text-center"
              style={{ flex: '1 1 100%' }}
              variant="outline-secondary"
              onClick={this.toggleEventForm}
            >
              Create New Event
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
          <Col>{this.renderUserEvents(rows)}</Col>
        </Row>
      </Container>
    )
  }
}

export default UserEvents
