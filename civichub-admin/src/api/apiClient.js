import axios from 'axios'

import { clearAuthStorage, getAccessToken } from '../utils/authStorage'

const apiBaseUrl = import.meta.env.DEV
  ? ''
  : import.meta.env.VITE_API_URL || 'http://localhost:8080'

const apiClient = axios.create({
  baseURL: apiBaseUrl,
})

apiClient.interceptors.request.use((config) => {
  const token = getAccessToken()

  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }

  return config
})

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      clearAuthStorage()

      if (window.location.hash !== '#/login') {
        window.location.hash = '#/login'
      }
    }

    return Promise.reject(error)
  },
)

export default apiClient
