import React, { Component, FormEvent } from 'react'
import * as _ from 'lodash'
import { Form, Button } from 'react-bootstrap'
import axios from 'axios'

interface MyProps {
  selectedUser: object
  toggleLoading: (callback: () => void) => void
  selectedItem?: object
  isEditing: boolean
  loadTabData: () => Promise<void>
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

  componentDidMount() {
    const { selectedItem } = this.props

    if (selectedItem) {
      this.setState({
        itemName: _.get(selectedItem, 'itemname'),
        itemValue: _.get(selectedItem, 'value'),
        itemDesc: _.get(selectedItem, 'itemdescription'),
      })
    }
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
    const {
      selectedUser,
      toggleLoading,
      isEditing,
      selectedItem,
      loadTabData,
    } = this.props
    const userId = _.get(selectedUser, 'userId')
    const itemId = _.get(selectedItem, 'itemid')

    toggleLoading(async () => {
      isEditing
        ? await axios.patch(`/add-item`, {
            itemId,
            userId,
            ...this.state,
          })
        : await axios.post(`/add-item`, {
            userId,
            ...this.state,
          })

      await loadTabData()
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
            placeholder="Item Price ($)"
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
          {this.props.isEditing ? 'Save' : 'Add'}
        </Button>
      </Form>
    )
  }
}

export default AddItem
