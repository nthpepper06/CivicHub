import apiClient from './apiClient'
import { cleanParams, unwrapData, unwrapPage } from './apiUtils'

export const getCategories = async (params) =>
  unwrapPage(await apiClient.get('/api/admin/categories', { params: cleanParams(params) }))

export const getCategory = async (id) =>
  unwrapData(await apiClient.get(`/api/admin/categories/${id}`))

export const createCategory = async (payload) =>
  unwrapData(await apiClient.post('/api/admin/categories', payload))

export const updateCategory = async (id, payload) =>
  unwrapData(await apiClient.put(`/api/admin/categories/${id}`, payload))

export const updateCategoryStatus = async (id, isActive) =>
  unwrapData(await apiClient.patch(`/api/admin/categories/${id}/status`, { isActive }))
