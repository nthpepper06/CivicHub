import apiClient from './apiClient'
import { cleanParams, unwrapData, unwrapPage } from './apiUtils'

export const getNotifications = async (params) =>
  unwrapPage(await apiClient.get('/api/notifications', { params: cleanParams(params) }))

export const getUnreadNotificationCount = async () =>
  unwrapData(await apiClient.get('/api/notifications/unread-count'))

export const markNotificationAsRead = async (id) =>
  unwrapData(await apiClient.patch(`/api/notifications/${id}/read`))

export const markAllNotificationsAsRead = async () =>
  unwrapData(await apiClient.patch('/api/notifications/read-all'))

export const markSelectedNotificationsAsRead = async (notificationIds) =>
  unwrapData(await apiClient.patch('/api/notifications/read', { notificationIds }))
