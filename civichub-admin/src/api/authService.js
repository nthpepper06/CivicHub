import apiClient from './apiClient'
import { unwrapData } from './apiUtils'

export const getCurrentUser = async () => unwrapData(await apiClient.get('/api/auth/me'))

export const updateCurrentUser = async (payload) =>
  unwrapData(await apiClient.patch('/api/auth/me', payload))

export const changePassword = async (payload) =>
  unwrapData(await apiClient.patch('/api/auth/change-password', payload))
