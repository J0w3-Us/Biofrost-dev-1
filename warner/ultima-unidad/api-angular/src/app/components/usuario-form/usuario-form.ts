
import { Component, Inject } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';

import { Usuarios } from '../../services/usuarios';

@Component({
  selector: 'app-usuario-form',
  templateUrl: './usuario-form.html',
  styleUrl: './usuario-form.css',
})
export class UsuarioForm {
  form: FormGroup;

  constructor(private fb: FormBuilder, private usuariosService: Usuarios) {
    const d = (this as any).data;
    this.form = this.fb.group({
      name: [d?.name || '', Validators.required],
      email: [d?.email || '', [Validators.required, Validators.email]],
      phone: [d?.phone || ''],
    });
  }

  save() {
    if (this.form.invalid) return;
    const payload = this.form.value;
    const d = (this as any).data;
    const dialogRef = (this as any).dialogRef;
    if (d?.id) {
      this.usuariosService.updateUsuario(d.id, payload).subscribe(() => dialogRef?.close?.(true));
    } else {
      this.usuariosService.addUsuario(payload).subscribe(() => dialogRef?.close?.(true));
    }
  }

  cancel() {
    const dialogRef = (this as any).dialogRef;
    dialogRef?.close?.(false);
  }
}
