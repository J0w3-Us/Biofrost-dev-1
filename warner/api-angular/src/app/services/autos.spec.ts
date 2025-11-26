import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';

import { AutosService } from './autos.service';

describe('AutosService', () => {
  let service: AutosService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
    });
    service = TestBed.inject(AutosService);
  });
  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
