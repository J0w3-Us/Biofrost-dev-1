import { forwardRef } from 'react';

export const Input = forwardRef(({
  label,
  error,
  helperText,
  className = '',
  icon,
  size = 'md',
  state = 'default',
  ...props
}, ref) => {
  const sizeClasses = {
    sm: 'px-3 py-2 text-sm',
    md: 'px-4 py-2.5 text-base',
    lg: 'px-4 py-3 text-lg',
  };

  const stateClasses = {
    default: 'border-gray-200 focus:border-gray-400 focus:ring-gray-200',
    success: 'border-green-500 focus:border-green-600 focus:ring-green-100',
    error: 'border-red-500 focus:border-red-600 focus:ring-red-100',
    disabled: 'bg-gray-50 border-gray-200 cursor-not-allowed opacity-60',
  };

  return (
    <div className="w-full">
      {label && (
        <label className="block text-sm font-semibold text-gray-900 mb-2">
          {label}
        </label>
      )}
      <div className="relative">
        {icon && (
          <div className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
            {icon}
          </div>
        )}
        <input
          ref={ref}
          className={`
            w-full
            bg-white border-2
            rounded-lg
            text-gray-900 placeholder:text-gray-400
            transition-all duration-200
            focus:outline-none
            disabled:opacity-50 disabled:cursor-not-allowed
            ${icon ? 'pl-10' : ''}
            ${sizeClasses[size]}
            ${stateClasses[state]}
            ${error ? stateClasses.error : ''}
            ${className}
          `}
          {...props}
        />
      </div>
      {error && (
        <p className="mt-2 text-sm font-medium text-red-600">{error}</p>
      )}
      {helperText && !error && (
        <p className="mt-2 text-sm text-gray-500">{helperText}</p>
      )}
    </div>
  );
});

Input.displayName = 'Input';

export const Textarea = forwardRef(({
  label,
  error,
  helperText,
  className = '',
  size = 'md',
  rows = 4,
  ...props
}, ref) => {
  const sizeClasses = {
    sm: 'px-3 py-2 text-sm',
    md: 'px-4 py-2.5 text-base',
    lg: 'px-4 py-3 text-lg',
  };

  return (
    <div className="w-full">
      {label && (
        <label className="block text-sm font-semibold text-gray-900 mb-2">
          {label}
        </label>
      )}
      <textarea
        ref={ref}
        rows={rows}
        className={`
          w-full
          bg-white border-2 border-gray-200
          rounded-lg
          text-gray-900 placeholder:text-gray-400
          transition-all duration-200
          resize-none
          focus:outline-none focus:border-gray-400 focus:ring-2 focus:ring-gray-200
          disabled:opacity-50 disabled:cursor-not-allowed
          ${sizeClasses[size]}
          ${error ? 'border-red-500 focus:border-red-600 focus:ring-red-100' : ''}
          ${className}
        `}
        {...props}
      />
      {error && (
        <p className="mt-2 text-sm font-medium text-red-600">{error}</p>
      )}
      {helperText && !error && (
        <p className="mt-2 text-sm text-gray-500">{helperText}</p>
      )}
    </div>
  );
});

Textarea.displayName = 'Textarea';

export const Select = forwardRef(({
  label,
  error,
  helperText,
  children,
  className = '',
  size = 'md',
  ...props
}, ref) => {
  const sizeClasses = {
    sm: 'px-3 py-2 text-sm',
    md: 'px-4 py-2.5 text-base',
    lg: 'px-4 py-3 text-lg',
  };

  return (
    <div className="w-full">
      {label && (
        <label className="block text-sm font-semibold text-gray-900 mb-2">
          {label}
        </label>
      )}
      <select
        ref={ref}
        className={`
          w-full
          bg-white border-2 border-gray-200
          rounded-lg
          text-gray-900
          transition-all duration-200
          focus:outline-none focus:border-gray-400 focus:ring-2 focus:ring-gray-200
          disabled:opacity-50 disabled:cursor-not-allowed
          appearance-none cursor-pointer
          ${sizeClasses[size]}
          ${error ? 'border-red-500 focus:border-red-600 focus:ring-red-100' : ''}
          ${className}
        `}
        {...props}
      >
        {children}
      </select>
      {error && (
        <p className="mt-2 text-sm font-medium text-red-600">{error}</p>
      )}
      {helperText && !error && (
        <p className="mt-2 text-sm text-gray-500">{helperText}</p>
      )}
    </div>
  );
});

Select.displayName = 'Select';
