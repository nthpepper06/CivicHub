import React, { createContext, useCallback, useEffect, useMemo, useState } from 'react'
import PropTypes from 'prop-types'
import { useNavigate } from 'react-router-dom'

import apiClient from '../api/apiClient'
import {
  clearAuthStorage,
  getAccessToken,
  getStoredUser,
  setAccessToken,
  setStoredUser,
} from '../utils/authStorage'

export const AuthContext = createContext(null)

const isTokenExpired = (token) => {
  try {
    const base64Url = token.split('.')[1]
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/')
    const paddedBase64 = base64.padEnd(base64.length + ((4 - (base64.length % 4)) % 4), '=')
    const payload = JSON.parse(atob(paddedBase64))
    return payload.exp ? payload.exp * 1000 <= Date.now() : false
  } catch {
    return true
  }
}

const normalizeAuthError = (error) => {
  if (!error.response) {
    return 'Server unavailable.'
  }

  const message = error.response.data?.message

  if (error.response.status === 401) {
    return 'Invalid email or password.'
  }

  if (error.response.status === 403 && message === 'Account is disabled or blocked') {
    return 'Account inactive.'
  }

  if (error.response.status >= 500) {
    return 'Server unavailable.'
  }

  return message || 'Unable to login.'
}

export const AuthProvider = ({ children }) => {
  const navigate = useNavigate()
  const [user, setUser] = useState(null)
  const [token, setToken] = useState(null)
  const [restored, setRestored] = useState(false)

  const restoreSession = useCallback(() => {
    const storedToken = getAccessToken()
    const storedUser = getStoredUser()

    if (!storedToken || !storedUser || isTokenExpired(storedToken)) {
      clearAuthStorage()
      setUser(null)
      setToken(null)
      setRestored(true)
      return
    }

    setUser(storedUser)
    setToken(storedToken)
    setRestored(true)
  }, [])

  useEffect(() => {
    const restoreTimer = window.setTimeout(() => {
      restoreSession()
    }, 0)

    return () => window.clearTimeout(restoreTimer)
  }, [restoreSession])

  const logout = useCallback(
    (redirectToLogin = true, state) => {
      clearAuthStorage()
      setUser(null)
      setToken(null)

      if (redirectToLogin) {
        navigate('/login', { replace: true, state })
      }
    },
    [navigate],
  )

  const login = useCallback(
    async ({ email, password, rememberMe }) => {
      try {
        const response = await apiClient.post('/api/auth/login', {
          email,
          password,
        })
        const nextToken = response.data?.data?.accessToken
        const nextUser = response.data?.data?.user

        if (!nextToken || !nextUser) {
          throw new Error('Invalid login response.')
        }

        if (nextUser.role !== 'ADMIN') {
          clearAuthStorage()
          setUser(null)
          setToken(null)
          throw new Error('Admin access required.')
        }

        setAccessToken(nextToken, rememberMe)
        setStoredUser(nextUser, rememberMe)
        setUser(nextUser)
        setToken(nextToken)
        navigate('/dashboard', { replace: true })
      } catch (error) {
        if (error.message === 'Admin access required.') {
          throw error
        }

        throw new Error(normalizeAuthError(error))
      }
    },
    [navigate],
  )

  const value = useMemo(
    () => ({
      user,
      token,
      login,
      logout,
      restoreSession,
      isAuthenticated: Boolean(token && user),
      isAdmin: user?.role === 'ADMIN',
      restored,
    }),
    [login, logout, restoreSession, restored, token, user],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

AuthProvider.propTypes = {
  children: PropTypes.node.isRequired,
}
