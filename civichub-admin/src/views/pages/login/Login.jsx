import React, { useEffect, useState } from 'react'
import { useLocation } from 'react-router-dom'
import {
  CAlert,
  CButton,
  CCard,
  CCardBody,
  CCol,
  CContainer,
  CForm,
  CFormCheck,
  CFormFeedback,
  CFormInput,
  CInputGroup,
  CInputGroupText,
  CRow,
  CSpinner,
} from '@coreui/react'
import CIcon from '@coreui/icons-react'
import { cilLockLocked, cilUser } from '@coreui/icons'

import useAuth from '../../../hooks/useAuth'

const Login = () => {
  const location = useLocation()
  const { login, isAuthenticated, isAdmin } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [rememberMe, setRememberMe] = useState(false)
  const [validated, setValidated] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(location.state?.authError || '')

  useEffect(() => {
    if (isAuthenticated && isAdmin) {
      window.location.hash = '#/dashboard'
    }
  }, [isAdmin, isAuthenticated])

  const handleSubmit = async (event) => {
    event.preventDefault()

    if (loading) {
      return
    }

    setValidated(true)
    setError('')

    if (!email.trim() || !password) {
      return
    }

    setLoading(true)

    try {
      await login({ email: email.trim(), password, rememberMe })
    } catch (loginError) {
      setError(loginError.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="bg-body-tertiary min-vh-100 d-flex flex-row align-items-center">
      <CContainer>
        <CRow className="justify-content-center">
          <CCol sm={10} md={7} lg={5}>
            <CCard className="p-4">
              <CCardBody>
                <CForm noValidate validated={validated} onSubmit={handleSubmit}>
                  <h1>CivicHub Admin</h1>
                  <p className="text-body-secondary">Admin sign in</p>
                  {error && (
                    <CAlert color="danger" className="mb-3">
                      {error}
                    </CAlert>
                  )}
                  <CInputGroup className="mb-3">
                    <CInputGroupText>
                      <CIcon icon={cilUser} />
                    </CInputGroupText>
                    <CFormInput
                      type="email"
                      placeholder="Email"
                      autoComplete="email"
                      value={email}
                      onChange={(event) => setEmail(event.target.value)}
                      required
                      disabled={loading}
                    />
                    <CFormFeedback invalid>Email is required.</CFormFeedback>
                  </CInputGroup>
                  <CInputGroup className="mb-3">
                    <CInputGroupText>
                      <CIcon icon={cilLockLocked} />
                    </CInputGroupText>
                    <CFormInput
                      type="password"
                      placeholder="Password"
                      autoComplete="current-password"
                      value={password}
                      onChange={(event) => setPassword(event.target.value)}
                      required
                      disabled={loading}
                    />
                    <CFormFeedback invalid>Password is required.</CFormFeedback>
                  </CInputGroup>
                  <CFormCheck
                    id="rememberMe"
                    className="mb-4"
                    label="Remember Me"
                    checked={rememberMe}
                    onChange={(event) => setRememberMe(event.target.checked)}
                    disabled={loading}
                  />
                  <CButton color="primary" className="px-4" type="submit" disabled={loading}>
                    {loading && <CSpinner component="span" size="sm" className="me-2" />}
                    Login
                  </CButton>
                </CForm>
              </CCardBody>
            </CCard>
          </CCol>
        </CRow>
      </CContainer>
    </div>
  )
}

export default Login
