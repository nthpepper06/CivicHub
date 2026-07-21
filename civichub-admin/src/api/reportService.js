import apiClient from './apiClient'
import { cleanParams, unwrapData, unwrapPage } from './apiUtils'

export const getReports = async (params) =>
  unwrapPage(await apiClient.get('/api/admin/reports', { params: cleanParams(params) }))

export const getReport = async (id) => unwrapData(await apiClient.get(`/api/admin/reports/${id}`))

export const assignReportDepartment = async (id, departmentId) =>
  unwrapData(await apiClient.patch(`/api/admin/reports/${id}/department`, { departmentId }))
