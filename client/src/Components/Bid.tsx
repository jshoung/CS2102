import React, { Component, FormEvent } from 'react'
import { Form, Button, Col, Row } from 'react-bootstrap'

class Bid extends Component<{advid: any, placeBid: any, nextBid: any }, { nextBid: any, nextPossibleBid:any }> {
	constructor(props: any) {
		super(props)
		this.state = {
			nextBid: this.props.nextBid,
			nextPossibleBid: this.props.nextBid
		}
		this.handleChange = this.handleChange.bind(this)
	}
	componentDidUpdate(oldProps: any) {
		const newProps = this.props
		if (oldProps.nextBid !== newProps.nextBid) {
			this.setState({nextBid:this.props.nextBid, nextPossibleBid: this.props.nextBid})
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
		event.preventDefault()
		if (this.state.nextBid < this.state.nextPossibleBid) {
			alert("Your bid needs to be higher than $" + this.state.nextPossibleBid + "!")
		} else {			
			this.props.placeBid(this.state.nextBid, this.props.advid);
		}
	}

	render() {
		return (
			<div>
				<Form onSubmit={this.handleSubmit}>
					<Form.Group style={{ marginTop: "1rem" }}>
						<Row>
							<Col sm={{ span: 2, offset: 2 }}>
								<Form.Label style={{ marginTop: "0.5rem" }}>Place Bid</Form.Label>
							</Col>
							<Col sm="4">
								<Form.Control
									name="nextBid"
									type="number"
									placeholder="Bid Price"
									onChange={this.handleChange}
									value={this.state.nextBid}
									required
								/>
							</Col>
							<Button variant="light" size="sm" type="submit">
								Place Bid
							</Button>
						</Row>
					</Form.Group>
				</Form>
			</div>
		)
	}
}

export default Bid