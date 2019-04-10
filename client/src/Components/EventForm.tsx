import React, { Component, FormEvent } from 'react'
import * as _ from 'lodash'
import { Form, Button } from 'react-bootstrap'
import axios from 'axios'

interface MyProps {
  selectedUser: object
  toggleLoading: (callback: () => void) => void
  toggleCreateEvent: Function
  isEditing: boolean
  rows: object
  showErrorModal: (string: string) => void
  fetchUserEvents: () => void
}

interface MyState {
  organizer: string
  eventName: string
  eventDate: string
  venue: string
  data: object
}

class EventForm extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      organizer: '',
      eventName: '',
      eventDate: '',
      venue: '',
      data: { rows: [] },
    }

    this.handleChange = this.handleChange.bind(this)
  }

  handleChange = (event: any) => {
    const target = event.target
    const value = target.value
    const name = target.name

    this.setState({
      [name]: value,
    } as any)
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
      organizer: data.data.rows[0].groupname,
    })
  }

  handleSubmit = async () => {
    try {
      await axios.post('/events', {
        organizer: this.state.organizer,
        eventName: this.state.eventName,
        eventDate: this.state.eventDate,
        venue: this.state.venue,
      })
    } catch (error) {
      this.props.showErrorModal(error.toString())
    }

    this.props.toggleCreateEvent()
    await this.props.fetchUserEvents()
  }

  renderInterestGroupOptions = () => {
    const rows = _.get(this.state.data, 'rows')

    return rows.map((row: any) => {
      return <option value={row.groupname}>{row.groupname}</option>
    })
  }

  render() {
    return (
      <Form style={{ flex: '1 1 100%' }} onSubmit={this.handleSubmit}>
        <Form.Group controlId="ControlSelect1">
          <Form.Label>Organizer</Form.Label>
          <Form.Control
            name="organizer"
            onChange={this.handleChange}
            value={`${this.state.organizer}`}
            required
            as="select"
          >
            {this.renderInterestGroupOptions()}
          </Form.Control>
        </Form.Group>
        <Form.Group controlId="ControlInput1">
          <Form.Label>Event Name</Form.Label>
          <Form.Control
            name="eventName"
            type="text"
            placeholder="Event Name"
            onChange={this.handleChange}
            value={this.state.eventName}
            required
          />
        </Form.Group>
        <Form.Group controlId="ControlInput2">
          <Form.Label>Event Date</Form.Label>
          <Form.Control
            name="eventDate"
            type="text"
            placeholder="MM-DD-YYYY"
            onChange={this.handleChange}
            value={`${this.state.eventDate}`}
            required
          />
        </Form.Group>
        <Form.Group controlId="ControlInput3">
          <Form.Label>Venue</Form.Label>
          <Form.Control
            name="venue"
            type="text"
            placeholder="Venue"
            onChange={this.handleChange}
            value={`${this.state.venue}`}
            required
          />
        </Form.Group>
        <Button variant="primary" onClick={this.handleSubmit}>
          {'Create'}
        </Button>
        <Button
          style={{ margin: '1em' }}
          onClick={() => this.props.toggleCreateEvent()}
          variant="primary"
        >
          {'Cancel'}
        </Button>
      </Form>
    )
  }
}

export default EventForm
