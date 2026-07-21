import apiClient from './apiClient'
import { cleanParams, downloadBlobResponse, unwrapData, unwrapPage } from './apiUtils'

export const getUsers = async (params) =>
  unwrapPage(await apiClient.get('/api/admin/users', { params: cleanParams(params) }))

export const getUser = async (id) => unwrapData(await apiClient.get(`/api/admin/users/${id}`))

export const updateUserStatus = async (id, isActive) =>
  unwrapData(await apiClient.patch(`/api/admin/users/${id}/status`, { isActive }))

export const assignUserDepartment = async (id, departmentId) =>
  unwrapData(await apiClient.patch(`/api/admin/users/${id}/department`, { departmentId }))

export const exportUsers = async (params) => {
  const response = await apiClient.get('/api/admin/users/export', {
    params: cleanParams(params),
    responseType: 'blob',
  })

  downloadBlobResponse(response, 'civichub-users.csv')
}
