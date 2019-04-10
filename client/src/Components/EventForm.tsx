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
}

interface MyState {
  interestGroup: string
  eventName: string
  eventDate: string
  venue: string
}

class EventForm extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      interestGroup: '',
      eventName: '',
      eventDate: '',
      venue: '',
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

  handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    const { selectedUser, toggleLoading, isEditing } = this.props
    const userId = _.get(selectedUser, 'userId')

    this.props.toggleCreateEvent()

    event.preventDefault()
  }

  renderInterestGroupOptions = (rows: any) => {
    return rows.map((row: any) => {
      return <option value={row.organizer}>{row.organizer}</option>
    })
  }

  render() {
    return (
      <Form style={{ flex: '1 1 100%' }} onSubmit={this.handleSubmit}>
        <Form.Group controlId="ControlSelect1">
          <Form.Label>Interest Group</Form.Label>
          <Form.Control
            name="interestGroup"
            onChange={this.handleChange}
            value={`${this.state.interestGroup}`}
            required
            as="select"
          >
            {this.renderInterestGroupOptions(this.props.rows)}
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
        <Button variant="primary" type="submit">
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
