import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class Autos {
  private readonly baseUrl = 'http://localhost:3000/autos';

  constructor(private http: HttpClient) {}

  getAll(): Observable<any[]> {
    return this.http.get<any[]>(this.baseUrl);
  }

  getById(id: number | string): Observable<any> {
    return this.http.get<any>(`${this.baseUrl}/${id}`);
  }

  create(auto: any): Observable<any> {
    return this.http.post<any>(this.baseUrl, auto);
  }

  update(id: number | string, auto: any): Observable<any> {
    return this.http.put<any>(`${this.baseUrl}/${id}`, auto);
  }

  delete(id: number | string): Observable<any> {
    return this.http.delete<any>(`${this.baseUrl}/${id}`);
  }
}
