import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';

import { Usuarios } from './usuarios';

describe('Usuarios', () => {
  let service: Usuarios;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
    });
    service = TestBed.inject(Usuarios);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
