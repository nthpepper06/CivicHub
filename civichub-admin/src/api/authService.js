import apiClient from './apiClient'
import { unwrapData } from './apiUtils'

export const getCurrentUser = async () => unwrapData(await apiClient.get('/api/auth/me'))
