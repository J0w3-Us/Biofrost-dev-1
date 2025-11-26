
import { Component, OnInit, Inject, PLATFORM_ID, OnDestroy } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { AutosService, Auto } from '../../services/autos.service';
import { ReactiveFormsModule, FormControl } from '@angular/forms';
import { AutoForm } from '../auto-form/auto-form';
import { Subject, of } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap, takeUntil, tap, catchError, map } from 'rxjs/operators';

@Component({
  selector: 'app-auto-list',
  imports: [CommonModule, ReactiveFormsModule, AutoForm],
  templateUrl: './auto-list.html',
  styleUrls: ['./auto-list.css'],
})
export class AutoList implements OnInit, OnDestroy {
  autos: Auto[] = [];
  loading = false;
  errorMsg: string | null = null;
  editingAuto: Auto | null = null;
  showForm = false;
  editingId: number | null = null;
  searchControl = new FormControl('');
  private destroy$ = new Subject<void>();

  constructor(
    private autosService: AutosService,
    @Inject(PLATFORM_ID) private platformId: Object
  ) {}

  ngOnInit(): void {
    // Initial load - force immediate data fetch (call even in browser environments)
    this.loadAutos();

    // Wire up search with debounce and cancellation of inflight requests — only on browser
    if (isPlatformBrowser(this.platformId)) {
      this.searchControl.valueChanges.pipe(
        debounceTime(300),
        map((v: any) => (v || '').toString()),
        distinctUntilChanged(),
        tap(() => { 
          if (this.searchControl.value && this.searchControl.value.trim()) {
            this.loading = true; 
            this.errorMsg = null; 
          }
        }),
        switchMap((q: string) => {
          // Only search if there's actual text, otherwise reload all data
          if (!q || !q.trim()) {
            // return current cached list instead of triggering another load
            return of(this.autos);
          }
          const param = { q: q.trim() };
          return this.autosService.list(param).pipe(catchError((err: any) => { this.errorMsg = err?.message || String(err); return of([] as Auto[]); }));
        }),
        takeUntil(this.destroy$)
      ).subscribe((results: Auto[]) => {
        // Update only when user typed a query
        if (this.searchControl.value && this.searchControl.value.trim()) {
          this.autos = results || [];
          this.loading = false;
        }
      });
    }
  }

  loadAutos(): void {
    this.loading = true;
    this.errorMsg = null;
    console.log('Fetching autos from API...');
    this.autosService.list().pipe(
      takeUntil(this.destroy$),
      catchError((err: any) => {
        console.error('Error loading autos', err);
        this.errorMsg = err?.message || String(err) || 'Error cargando autos';
        this.loading = false;
        return of([] as Auto[]);
      })
    ).subscribe((data: Auto[]) => {
      this.autos = data || [];
      this.loading = false;
    });
  }

  deleteAuto(id?: number | string) {
    if (id === undefined || id === null) return;
    if (!confirm('¿Eliminar este auto?')) return;
    this.loading = true;
    this.autosService.delete(id).subscribe({
      next: () => {
        // refresh from server after delete
        this.loadAutos();
      },
      error: (err: any) => {
        console.error('Error deleting auto', err);
        this.loading = false;
      },
    });
  }

  imageFor(auto: Auto) {
    // Return a stable image URL for each auto. Use loremflickr for car images.
    const id = auto.id ?? Math.floor(Math.random() * 1000);
    return auto.image || `https://loremflickr.com/640/360/car?lock=${id}`;
  }

  openCreate() {
    this.editingId = null;
    this.editingAuto = null;
    this.showForm = true;
  }

  openEdit(a: Auto) {
    this.editingId = a.id ?? null;
    this.editingAuto = a;
    this.showForm = true;
  }

  cancelForm() {
    this.showForm = false;
    this.editingAuto = null;
    this.editingId = null;
  }
  onFormSave(payload: Auto) {
    this.loading = true;
    if (this.editingId) {
      this.autosService.update(this.editingId, payload).subscribe({
        next: () => {
          this.loadAutos();
          this.cancelForm();
        },
        error: (err: any) => {
          console.error('Error updating auto', err);
          this.loading = false;
        }
      });
    } else {
      this.autosService.create(payload).subscribe({
        next: () => {
          this.loadAutos();
          this.cancelForm();
        },
        error: (err: any) => {
          console.error('Error creating auto', err);
          this.loading = false;
        }
      });
    }
  }

  selectFilter(filter: string): void {
    // In a real app, you might filter by category on the server
    // For now, just reload all autos
    this.searchControl.setValue('');
    this.loadAutos();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
