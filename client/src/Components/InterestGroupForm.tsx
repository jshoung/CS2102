import React, { Component, FormEvent } from 'react'
import * as _ from 'lodash'
import { Form, Button } from 'react-bootstrap'
import axios from 'axios'

interface MyProps {
  selectedUser: object
  toggleLoading: (callback: () => void) => void
  toggleCreateGroup: Function
  isEditing: boolean
}

interface MyState {
  groupName: string
  groupDescription: string
}

class InterestGroupForm extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      groupName: '',
      groupDescription: '',
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

    axios.post('/interestgroups', {
      userId: userId,
      groupDescription: this.state.groupDescription,
      groupName: this.state.groupName,
    })

    this.props.toggleCreateGroup()

    event.preventDefault()
  }

  render() {
    return (
      <Form style={{ flex: '1 1 100%' }} onSubmit={this.handleSubmit}>
        <Form.Group controlId="ControlInput1">
          <Form.Label>Group Name</Form.Label>
          <Form.Control
            name="groupName"
            type="text"
            placeholder="Group Name"
            onChange={this.handleChange}
            value={this.state.groupName}
            required
          />
        </Form.Group>
        <Form.Group controlId="ControlInput2">
          <Form.Label>Group Description</Form.Label>
          <Form.Control
            name="groupDescription"
            type="text"
            placeholder="Group Description"
            onChange={this.handleChange}
            value={`${this.state.groupDescription}`}
            required
          />
        </Form.Group>
        <Button variant="primary" type="submit">
          {'Create'}
        </Button>
        <Button
          style={{ margin: '1em' }}
          onClick={() => this.props.toggleCreateGroup()}
          variant="primary"
        >
          {'Cancel'}
        </Button>
      </Form>
    )
  }
}

export default InterestGroupForm
