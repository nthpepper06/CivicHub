import apiClient from './apiClient'
import { cleanParams, unwrapData, unwrapPage } from './apiUtils'

export const getDashboardSummary = async (params) =>
  unwrapData(await apiClient.get('/api/admin/dashboard/summary', { params: cleanParams(params) }))

export const getCategoryStatistics = async (params) =>
  unwrapData(await apiClient.get('/api/admin/dashboard/category', { params: cleanParams(params) }))

export const getDepartmentStatistics = async (params) =>
  unwrapData(
    await apiClient.get('/api/admin/dashboard/department', { params: cleanParams(params) }),
  )

export const getMonthlyStatistics = async (year, params) =>
  unwrapData(
    await apiClient.get('/api/admin/dashboard/monthly', {
      params: cleanParams({ year, ...params }),
    }),
  )

export const getRecentReports = async (size = 10) =>
  unwrapPage(await apiClient.get('/api/admin/dashboard/recent', { params: { size } }))
