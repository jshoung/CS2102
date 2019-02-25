import React, { Component } from 'react'
import axios from 'axios'

class Main extends Component {
  state = {
    data: { title: '', description: '' },
  }

  async componentDidMount() {
    const payload = (await axios.get(`/api/hello`)).data
    console.log(payload)

    this.setState({
      ...payload,
    })
  }

  render() {
    const { data } = this.state
    if (data === null) return <p>Loading ...</p>

    return (
      <div className="container">
        <div className="row">
          <div className="jumbotron col-12 text-center">
            <h1 className="display-3">{data.title}</h1>
            <p className="lead">{data.description}</p>
          </div>
        </div>
      </div>
    )
  }
}

export default Main
