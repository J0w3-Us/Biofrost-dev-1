import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { CommonModule, NgIf } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Auto } from '../../services/autos.service';

@Component({
  selector: 'app-auto-form',
  standalone: true,
  imports: [CommonModule, NgIf, ReactiveFormsModule],
  templateUrl: './auto-form.html',
  styleUrls: ['./auto-form.css']
})
export class AutoForm implements OnInit {
  @Input() auto: Auto | null = null;
  @Output() save = new EventEmitter<Auto>();
  @Output() cancel = new EventEmitter<void>();

  form!: FormGroup;

  constructor(private fb: FormBuilder) {}

  ngOnInit(): void {
    this.form = this.fb.group({
      make: [this.auto?.make || this.auto?.['marca'] || '', Validators.required],
      model: [this.auto?.model || this.auto?.['modelo'] || '', Validators.required],
      year: [this.auto?.year || this.auto?.['anio'] || new Date().getFullYear(), [Validators.required, Validators.min(1900)]],
      price: [this.auto?.price || this.auto?.['precio'] || 0, [Validators.required, Validators.min(0)]],
      image: [this.auto?.image || ''],
      description: [this.auto?.description || this.auto?.['descripcion'] || ''],
    });
  }

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.save.emit(this.form.value as Auto);
  }

  doCancel(): void {
    this.cancel.emit();
  }
}
