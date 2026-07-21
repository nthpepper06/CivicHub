import apiClient from './apiClient'
import { cleanParams, unwrapData, unwrapPage } from './apiUtils'

export const getAuditLogs = async (params) =>
  unwrapPage(await apiClient.get('/api/admin/audit-logs', { params: cleanParams(params) }))

export const getAuditLog = async (id) =>
  unwrapData(await apiClient.get(`/api/admin/audit-logs/${id}`))
