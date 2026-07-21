import apiClient from './apiClient'
import { cleanParams, unwrapData, unwrapPage } from './apiUtils'

export const getDepartments = async (params) =>
  unwrapPage(await apiClient.get('/api/admin/departments', { params: cleanParams(params) }))

export const getDepartment = async (id) =>
  unwrapData(await apiClient.get(`/api/admin/departments/${id}`))

export const createDepartment = async (payload) =>
  unwrapData(await apiClient.post('/api/admin/departments', payload))

export const updateDepartment = async (id, payload) =>
  unwrapData(await apiClient.put(`/api/admin/departments/${id}`, payload))

export const updateDepartmentStatus = async (id, isActive) =>
  unwrapData(await apiClient.patch(`/api/admin/departments/${id}/status`, { isActive }))
