export const formatDateTime = (value) => {
  if (!value) {
    return '-'
  }

  const date = new Date(value)

  if (Number.isNaN(date.getTime())) {
    return value
  }

  return new Intl.DateTimeFormat('en', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date)
}

export const formatLabel = (value) => {
  if (!value) {
    return '-'
  }

  return String(value)
    .toLowerCase()
    .split('_')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ')
}

export const reportStatusColor = (status) => {
  const colors = {
    PENDING: 'warning',
    RECEIVED: 'info',
    IN_PROGRESS: 'primary',
    RESOLVED: 'success',
    REJECTED: 'danger',
    CANCELLED: 'secondary',
  }

  return colors[status] || 'secondary'
}

export const booleanStatusColor = (isActive) => (isActive ? 'success' : 'secondary')
