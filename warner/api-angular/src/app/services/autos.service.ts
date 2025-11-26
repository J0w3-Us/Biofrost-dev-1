import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, retry } from 'rxjs/operators';

export interface Auto {
  id?: number;
  make?: string;
  model?: string;
  year?: number;
  price?: number;
  image?: string;
  description?: string;
  [key: string]: any;
}

const httpOptions = {
  headers: new HttpHeaders({ 'Content-Type': 'application/json' }),
};

@Injectable({ providedIn: 'root' })
export class AutosService {
  private readonly baseUrl = 'http://localhost:3000/autos';

  constructor(private http: HttpClient) {}

  // List with optional query params (filters, pagination)
  list(params?: Record<string, any>): Observable<Auto[]> {
    let httpParams = new HttpParams();
    if (params) {
      Object.keys(params).forEach((k) => {
        const v = params[k];
        if (v !== undefined && v !== null) httpParams = httpParams.set(k, String(v));
      });
    }
    return this.http
      .get<Auto[]>(this.baseUrl, { params: httpParams })
      .pipe(retry(1), catchError(this.handleError));
  }

  get(id: number | string): Observable<Auto> {
    return this.http
      .get<Auto>(`${this.baseUrl}/${id}`)
      .pipe(retry(1), catchError(this.handleError));
  }

  create(auto: Auto): Observable<Auto> {
    return this.http
      .post<Auto>(this.baseUrl, auto, httpOptions)
      .pipe(catchError(this.handleError));
  }

  update(id: number | string, auto: Partial<Auto>): Observable<Auto> {
    return this.http
      .put<Auto>(`${this.baseUrl}/${id}`, auto, httpOptions)
      .pipe(catchError(this.handleError));
  }

  delete(id: number | string): Observable<void> {
    return this.http
      .delete<void>(`${this.baseUrl}/${id}`, httpOptions)
      .pipe(catchError(this.handleError));
  }

  private handleError(error: HttpErrorResponse) {
    // Avoid using browser-specific types like ErrorEvent (not available on SSR).
    let message = '';

    if (error.error) {
      if (typeof error.error === 'string') {
        message = error.error;
      } else if (typeof error.error === 'object') {
        // prefer an explicit message property if present
        const maybeMsg = (error.error as any).message;
        if (maybeMsg && typeof maybeMsg === 'string') {
          message = maybeMsg;
        } else {
          message = `Server returned code ${error.status}, body was: ${JSON.stringify(error.error)}`;
        }
      } else {
        message = String(error.error);
      }
    } else {
      // fallback to HttpErrorResponse.message which works on SSR and browser
      message = error.message || `HTTP error (status: ${error.status})`;
    }

    return throwError(() => new Error(message));
  }
}
