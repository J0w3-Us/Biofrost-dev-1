import swaggerJSDoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'SuperHero API',
      version: '1.0.0',
      description: 'API para batallas de superhéroes',
    },
    servers: [
      {
        url: 'https://superhero-1-3gmw.onrender.com',
        description: 'Servidor de producción',
      },
      {
        url: 'http://localhost:3000',
        description: 'Servidor de desarrollo',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      },
      schemas: {
        User: {
          type: 'object',
          required: ['username', 'email'],
          properties: {
            id: {
              type: 'integer',
              description: 'ID único del usuario',
              example: 1
            },
            username: {
              type: 'string',
              description: 'Nombre de usuario único',
              example: 'spiderman_user'
            },
            email: {
              type: 'string',
              description: 'Email del usuario',
              example: 'peter@dailybugle.com'
            },
            token: {
              type: 'string',
              description: 'Token JWT del usuario',
              example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Fecha de creación',
              example: '2025-07-16T10:30:00Z'
            }
          }
        },
        LoginRequest: {
          type: 'object',
          required: ['username', 'password'],
          properties: {
            username: {
              type: 'string',
              description: 'Nombre de usuario',
              example: 'spiderman_user'
            },
            password: {
              type: 'string',
              description: 'Contraseña del usuario',
              example: 'password123'
            }
          }
        },
        RegisterRequest: {
          type: 'object',
          required: ['username', 'password'],
          properties: {
            username: {
              type: 'string',
              description: 'Nombre de usuario único',
              example: 'spiderman_user'
            },
            password: {
              type: 'string',
              description: 'Contraseña del usuario',
              example: 'password123'
            }
          }
        },
        Hero: {
          type: 'object',
          required: ['name', 'alias'],
          properties: {
            id: {
              type: 'integer',
              description: 'ID único del superhéroe',
              example: 1
            },
            name: {
              type: 'string',
              description: 'Nombre real del superhéroe',
              example: 'Peter Parker'
            },
            alias: {
              type: 'string',
              description: 'Alias o nombre de superhéroe',
              example: 'Spider-Man'
            },
            city: {
              type: 'string',
              description: 'Ciudad donde opera el superhéroe',
              example: 'New York'
            },
            team: {
              type: 'string',
              description: 'Equipo al que pertenece',
              example: 'Avengers'
            }
          }
        },
        Battle: {
          type: 'object',
          required: ['name', 'heroTeam', 'villainTeam', 'status'],
          properties: {
            id: {
              type: 'integer',
              description: 'ID único de la batalla',
              example: 1
            },
            name: {
              type: 'string',
              description: 'Nombre de la batalla',
              example: 'Battle for New York'
            },
            heroTeam: {
              type: 'array',
              items: {
                $ref: '#/components/schemas/Hero'
              },
              description: 'Equipo de héroes (máximo 3)'
            },
            villainTeam: {
              type: 'array',
              items: {
                $ref: '#/components/schemas/Villain'
              },
              description: 'Equipo de villanos (máximo 3)'
            },
            status: {
              type: 'string',
              enum: ['pending', 'in_progress', 'completed'],
              description: 'Estado de la batalla',
              example: 'pending'
            },
            winner: {
              type: 'string',
              enum: ['heroes', 'villains'],
              description: 'Ganador de la batalla',
              example: 'heroes'
            },
            userId: {
              type: 'integer',
              description: 'ID del usuario que creó la batalla',
              example: 1
            }
          }
        },
        Villain: {
          type: 'object',
          required: ['name', 'alias', 'city', 'organization'],
          properties: {
            id: {
              type: 'integer',
              description: 'ID único del villano',
              example: 1
            },
            name: {
              type: 'string',
              description: 'Nombre real del villano',
              example: 'Norman Osborn'
            },
            alias: {
              type: 'string',
              description: 'Alias o nombre del villano',
              example: 'Green Goblin'
            },
            city: {
              type: 'string',
              description: 'Ciudad donde opera el villano',
              example: 'New York'
            },
            organization: {
              type: 'string',
              description: 'Organización a la que pertenece',
              example: 'Oscorp'
            }
          }
        },
        Error: {
          type: 'object',
          properties: {
            error: {
              type: 'string',
              description: 'Mensaje de error'
            }
          }
        }
      }
    }
  },
  apis: ['./controllers/*.js'], // Rutas a los archivos que contienen las anotaciones
};

const specs = swaggerJSDoc(options);

export { swaggerUi, specs };
