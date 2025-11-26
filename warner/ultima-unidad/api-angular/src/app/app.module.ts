import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { HttpClientModule } from '@angular/common/http';
import { ReactiveFormsModule } from '@angular/forms';


import { UsuariosList } from './components/usuarios-list/usuarios-list';
import { UsuarioForm } from './components/usuario-form/usuario-form';

@NgModule({
  declarations: [UsuariosList, UsuarioForm],
  imports: [
    BrowserModule,
    BrowserAnimationsModule,
    HttpClientModule,
    ReactiveFormsModule,
  ],
  exports: [UsuariosList, UsuarioForm],
})
export class AppModule {}
