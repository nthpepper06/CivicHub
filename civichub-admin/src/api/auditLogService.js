import apiClient from './apiClient'
import { cleanParams, downloadBlobResponse, unwrapData, unwrapPage } from './apiUtils'

export const getAuditLogs = async (params) =>
  unwrapPage(await apiClient.get('/api/admin/audit-logs', { params: cleanParams(params) }))

export const getAuditLog = async (id) =>
  unwrapData(await apiClient.get(`/api/admin/audit-logs/${id}`))

export const exportAuditLogs = async (params) => {
  const response = await apiClient.get('/api/admin/audit-logs/export', {
    params: cleanParams(params),
    responseType: 'blob',
  })

  downloadBlobResponse(response, 'civichub-audit-logs.csv')
}
