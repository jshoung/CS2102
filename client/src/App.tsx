import React, { Component } from 'react'
import { Route } from 'react-router-dom'
import './index.css'
import NavBar from './NavBar/NavBar'
import Main from './Main/Main'

class App extends Component {
  render() {
    return (
      <div>
        <NavBar />
        <Route exact path="/" component={Main} />
      </div>
    )
  }
}

export default App
