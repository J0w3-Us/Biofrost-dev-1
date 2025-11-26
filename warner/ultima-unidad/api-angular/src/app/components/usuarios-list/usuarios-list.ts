import { Component, OnInit } from '@angular/core';

import { Usuarios } from '../../services/usuarios';
import { UsuarioForm } from '../usuario-form/usuario-form';

@Component({
  selector: 'app-usuarios-list',
  templateUrl: './usuarios-list.html',
  styleUrl: './usuarios-list.css',
})
export class UsuariosList implements OnInit {
  displayedColumns: string[] = ['id', 'name', 'email', 'phone', 'actions'];
  dataSource: any[] = [];
  allUsers: any[] = [];

  constructor(private usuariosService: Usuarios) {}

  ngOnInit(): void {
    this.loadUsuarios();
  }

  loadUsuarios(): void {
    this.usuariosService.getUsuarios().subscribe((users) => {
      this.allUsers = users || [];
      this.dataSource = [...this.allUsers];
    });
  }

  applyFilter(event: Event): void {
    const filterValue = (event.target as HTMLInputElement).value.trim().toLowerCase();
    if (!filterValue) {
      this.dataSource = [...this.allUsers];
      return;
    }
    this.dataSource = this.allUsers.filter((u) => {
      return (
        (u.name || '').toString().toLowerCase().includes(filterValue) ||
        (u.email || '').toString().toLowerCase().includes(filterValue)
      );
    });
  }

  openAdd() {
    const dialog = (this as any).dialog;
    const ref = dialog?.open?.(UsuarioForm, { width: '480px' });
    ref?.afterClosed?.()?.subscribe?.((res: boolean | undefined) => {
      if (res) this.loadUsuarios();
    });
  }

  openEdit(user: any) {
    const dialog = (this as any).dialog;
    const ref = dialog?.open?.(UsuarioForm, { width: '480px', data: user });
    ref?.afterClosed?.()?.subscribe?.((res: boolean | undefined) => {
      if (res) this.loadUsuarios();
    });
  }

  delete(user: any) {
    if (!confirm(`Eliminar usuario ${user.name}?`)) return;
    this.usuariosService.deleteUsuario(user.id).subscribe(() => this.loadUsuarios());
  }
}
