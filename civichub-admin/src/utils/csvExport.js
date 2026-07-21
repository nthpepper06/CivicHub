const escapeCsvValue = (value) => {
  if (value === null || value === undefined) {
    return ''
  }

  const text = String(value)

  if (/[",\r\n]/.test(text)) {
    return `"${text.replaceAll('"', '""')}"`
  }

  return text
}

export const downloadCsv = ({ filename, columns, rows }) => {
  const header = columns.map((column) => escapeCsvValue(column.header)).join(',')
  const body = rows
    .map((row) => columns.map((column) => escapeCsvValue(column.value(row))).join(','))
    .join('\n')
  const csv = [header, body].filter(Boolean).join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')

  link.href = url
  link.download = filename
  link.click()
  URL.revokeObjectURL(url)
}
