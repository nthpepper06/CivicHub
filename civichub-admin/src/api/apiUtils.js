export const unwrapData = (response) => response?.data?.data ?? response?.data ?? null

export const unwrapPage = (response) => {
  const data = unwrapData(response)

  return {
    content: Array.isArray(data?.content) ? data.content : [],
    page: Number.isFinite(data?.page) ? data.page : 0,
    size: Number.isFinite(data?.size) ? data.size : 10,
    totalElements: Number.isFinite(data?.totalElements) ? data.totalElements : 0,
    totalPages: Number.isFinite(data?.totalPages) ? data.totalPages : 0,
    first: Boolean(data?.first),
    last: Boolean(data?.last),
  }
}

export const cleanParams = (params = {}) =>
  Object.fromEntries(
    Object.entries(params).filter(
      ([, value]) => value !== '' && value !== null && value !== undefined,
    ),
  )

export const getApiErrorMessage = (error) => {
  if (!error?.response) {
    return 'Backend is unavailable. Check that the API server is running.'
  }

  if (error.response.status === 400) {
    const data = error.response.data
    const fieldError = Array.isArray(data?.errors) ? data.errors[0]?.message : ''

    return fieldError || data?.message || 'Validation failed. Check the submitted values.'
  }

  if (error.response.status === 401) {
    return 'Your session has expired. Please sign in again.'
  }

  if (error?.response?.status === 403) {
    return 'You do not have permission to perform this action.'
  }

  if (error.response.status === 404) {
    return 'The requested data was not found.'
  }

  if (error.response.status === 409) {
    return error.response.data?.message || 'The request conflicts with existing data.'
  }

  if (error?.response?.status >= 500) {
    return 'Server error. Please try again later.'
  }

  const data = error?.response?.data
  const fieldError = Array.isArray(data?.errors) ? data.errors[0]?.message : ''

  return fieldError || data?.message || error?.message || 'Request failed.'
}
