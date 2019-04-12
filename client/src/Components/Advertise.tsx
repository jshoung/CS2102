import React, { Component, FormEvent } from 'react'
import * as _ from 'lodash'
import { Form, Button } from 'react-bootstrap'
import axios from 'axios'
import moment from 'moment'

class Advertise extends Component<
  { item: any; loadTabData: any },
  {
    availability: any
    minIncrease: any
    adDuration: any
    minPrice: any
    itemDescription: any
  }
> {
  constructor(props: any) {
    super(props)
    this.state = {
      availability: moment(),
      minIncrease: 0,
      adDuration: 0,
      minPrice: 0,
      itemDescription: _.get(this.props.item, 'itemdescription'),
    }
  }

  advertise = async (event: any) => {
    const { item } = this.props
    const { availability } = this.state
    const { minIncrease, adDuration, minPrice, itemDescription } = this.state
    const duration = _.get(item, 'loanduration')
    const itemid = _.get(item, 'itemid')
    const userid = _.get(item, 'userid')

    if (itemDescription !== _.get(item, 'itemdescription')) {
      _.set(item, 'itemdescription', itemDescription)
      await axios.patch('/add-item', item)
    }
    await axios.post('/insertad', {
      minPrice,
      duration,
      availability,
      minIncrease,
      adDuration,
      itemid,
      userid,
    })
    await this.props.loadTabData()
    event.preventDefault()
  }

  handleChange = (event: any) => {
    const target = event.target
    const value = target.value
    const name = target.name

    this.setState({
      [name]: value,
    } as any)
  }

  render() {
    return (
      <Form onSubmit={this.advertise}>
        <Form.Group>
          <Form.Label>Start Of Advertisement</Form.Label>
          <Form.Control
            name="availability"
            type="date"
            onChange={this.handleChange}
            value={this.state.availability}
            required
          />
          <Form.Label>Duration of Advertisment (Days)</Form.Label>
          <Form.Control
            name="adDuration"
            type="number"
            onChange={this.handleChange}
            value={this.state.adDuration}
            required
          />
          <Form.Label>Minimum Bid</Form.Label>
          <Form.Control
            name="minPrice"
            type="number"
            onChange={this.handleChange}
            value={this.state.minPrice}
            required
          />
          <Form.Label>Minimum Increase in Bid</Form.Label>
          <Form.Control
            name="minIncrease"
            type="number"
            onChange={this.handleChange}
            value={this.state.minIncrease}
            required
          />
          <Form.Label>Item Description</Form.Label>
          <Form.Control
            name="itemDescription"
            as="textarea"
            rows="3"
            onChange={this.handleChange}
            value={this.state.itemDescription}
            required
          />
          <br />
          <Button variant="primary" type="submit">
            Advertise
          </Button>
        </Form.Group>
      </Form>
    )
  }
}

export default Advertise
