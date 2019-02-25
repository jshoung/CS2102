import React from 'react'
import { Link } from 'react-router-dom'

const NavBar = () => {
  return (
    <nav className="navbar navbar-dark bg-primary fixed-top">
      <Link className="navbar-brand" to="/">
        Stuff Sharing App
      </Link>
    </nav>
  )
}

export default NavBar
