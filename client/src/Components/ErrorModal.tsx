import React, { Component, FormEvent } from 'react'
import { Modal, Button } from 'react-bootstrap'

interface MyProps {
  message: string
  closeModal: Function
}

class ErrorModal extends Component<MyProps> {
  constructor(props: any) {
    super(props)
    this.state = {
      show: true,
    }
  }

  render() {
    return (
      <>
        <Modal show={this.props.message ? true : false}>
          <Modal.Header closeButton>
            <Modal.Title>Error</Modal.Title>
          </Modal.Header>
          <Modal.Body>{this.props.message}</Modal.Body>
          <Modal.Footer>
            <Button variant="secondary" onClick={() => this.props.closeModal()}>
              Okay
            </Button>
          </Modal.Footer>
        </Modal>
      </>
    )
  }
}

export default ErrorModal
