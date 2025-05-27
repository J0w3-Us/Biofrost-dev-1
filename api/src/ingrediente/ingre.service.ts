import { Injectable } from "@nestjs/common";
import { ingre } from "@prisma/client";
import { PrismaService } from "src/prisma/prisma.service";

@Injectable()
export class IngreService{

    constructor(private prisma: PrismaService) {}

    async getAllIngre(): Promise<ingre[]> {
        return this.prisma.ingre.findMany()
    }

    async getIngreById(id: number): Promise<ingre | null> {
        return this.prisma.ingre.findUnique({
            where: {id}
        })
    }

    async createIngre(data: ingre): Promise<ingre> {
        return this.prisma.ingre.create({
            data
        })
    }

    async deleteIngre(id: number): Promise<ingre>{
        return this.prisma.ingre.delete({
            where: {id}
        })
    }

    async updateIngre(id: number, data: ingre): Promise<ingre> {
        return this.prisma.ingre.update({
            where: {id},
            data
        })
    }
}