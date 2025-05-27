import { Controller, Get, Post, Put, Delete, Body, Param } from "@nestjs/common";
import { IngreService } from "./ingre.service";
import { ingre } from "@prisma/client";

@Controller()
export class IngreController{

    constructor(private readonly ingreService: IngreService) {}

    @Get()
    async getAllIngre() {
        return await this.ingreService.getAllIngre();
    }

    @Get(':id')
    async getIngreById(@Param(':id') id:number) {
        return await this.ingreService.getIngreById(id);
    }

    @Post()
    async createIngre(@Body() data: ingre) {
        return await this.ingreService.createIngre(data);
    }

    @Put(':id')
    async updateIngre(@Param(':id') id: string, @Body() data: ingre) {
        return await this.ingreService.updateIngre(Number(id), data);
    }

    @Delete(':id')
    async deleteIngre(@Param('id') id: string) {
        return await this.ingreService.deleteIngre(Number(id));
    }
}