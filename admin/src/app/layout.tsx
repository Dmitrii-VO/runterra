import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Runterra Admin',
  description: 'Runterra Admin Panel',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
