import { Routes } from '@angular/router';
import { AutoList } from './components/auto-list/auto-list';

export const routes: Routes = [
	{ path: '', component: AutoList },
	{ path: 'autos', component: AutoList },
];
