import apiClient from './apiClient'
import { unwrapData, unwrapPage } from './apiUtils'

export const getDashboardSummary = async () =>
  unwrapData(await apiClient.get('/api/admin/dashboard/summary'))

export const getCategoryStatistics = async () =>
  unwrapData(await apiClient.get('/api/admin/dashboard/category'))

export const getDepartmentStatistics = async () =>
  unwrapData(await apiClient.get('/api/admin/dashboard/department'))

export const getMonthlyStatistics = async (year) =>
  unwrapData(await apiClient.get('/api/admin/dashboard/monthly', { params: { year } }))

export const getRecentReports = async (size = 10) =>
  unwrapPage(await apiClient.get('/api/admin/dashboard/recent', { params: { size } }))
