import { Module } from "@nestjs/common";
import { IngreController } from "./ingre.controller";
import { IngreService } from "./ingre.service";
import { PrismaModule } from "src/prisma/prsima.module";


@Module({
    controllers:[IngreController],
    providers:[IngreService],
    imports: [PrismaModule]
})
export class IngreModule{}