import React, { Component } from 'react'
import { Route } from 'react-router-dom'
import './index.css'
import Main from './Main/Main'

class App extends Component {
  render() {
    return (
      <div>
        <Route exact path="/" component={Main} />
      </div>
    )
  }
}

export default App
