import React, { Component, FormEvent } from 'react'
import * as _ from 'lodash'
import { Form, Button } from 'react-bootstrap'
import axios from 'axios'

interface MyProps {
  selectedUser: object
  toggleLoading: (callback: () => void) => void
}

interface MyState {
  itemName: string
  itemValue: number
  itemDesc: string
}

class AddItem extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      itemName: '',
      itemValue: 0,
      itemDesc: '',
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
    const { selectedUser, toggleLoading } = this.props
    const userId = _.get(selectedUser, 'userId')

    toggleLoading(async () => {
      await axios.post(`/add-item`, {
        userId,
        ...this.state,
      })
      toggleLoading(() => {})
    })
    event.preventDefault()
  }

  render() {
    return (
      <Form onSubmit={this.handleSubmit}>
        <Form.Group controlId="ControlInput1">
          <Form.Label>Item Name</Form.Label>
          <Form.Control
            name="itemName"
            type="text"
            placeholder="Item Name"
            onChange={this.handleChange}
            value={this.state.itemName}
            required
          />
        </Form.Group>
        <Form.Group controlId="ControlInput2">
          <Form.Label>Item Price</Form.Label>
          <Form.Control
            name="itemValue"
            min="0"
            type="number"
            placeholder="Item Price"
            onChange={this.handleChange}
            value={`${this.state.itemValue}`}
            required
          />
        </Form.Group>
        <Form.Group controlId="ControlTextarea1">
          <Form.Label>Item Description</Form.Label>
          <Form.Control
            name="itemDesc"
            as="textarea"
            rows="3"
            onChange={this.handleChange}
            value={this.state.itemDesc}
            placeholder="Item Description (Optional)"
          />
        </Form.Group>
        <Button variant="primary" type="submit">
          Add
        </Button>
      </Form>
    )
  }
}

export default AddItem
