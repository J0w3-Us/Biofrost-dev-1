export function Card({ children, className = '', hover = false, elevated = false, interactive = false, ...props }) {
  return (
    <div
      className={`
        bg-white rounded-lg border border-gray-200
        transition-all duration-200
        ${hover || interactive ? 'hover:border-gray-300 hover:shadow-md hover:-translate-y-0.5 cursor-pointer' : ''}
        ${elevated ? 'shadow-lg border-gray-150' : 'shadow-sm'}
        ${interactive ? 'active:scale-[0.98] active:shadow-sm' : ''}
        ${className}
      `}
      {...props}
    >
      {children}
    </div>
  );
}

export function CardHeader({ children, className = '', bordered = true }) {
  return (
    <div className={`px-6 py-5 ${bordered ? 'border-b border-gray-100' : ''} ${className}`}>
      {children}
    </div>
  );
}

export function CardContent({ children, className = '' }) {
  return (
    <div className={`p-6 ${className}`}>
      {children}
    </div>
  );
}

export function CardFooter({ children, className = '', bordered = true }) {
  return (
    <div className={`px-6 py-4 ${bordered ? 'border-t border-gray-100' : ''} ${className}`}>
      {children}
    </div>
  );
}
