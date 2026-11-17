import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Request, Response } from 'express';

/**
 * Global exception filter normalizing NestJS HttpExceptions, Prisma ORM errors,
 * and unexpected runtime exceptions into a backward-compatible, structured JSON
 * envelope without leaking internal SQL queries or stack traces.
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();
    const path = request?.originalUrl || request?.url || '';
    const timestamp = new Date().toISOString();

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const resBody = exception.getResponse();

      if (typeof resBody === 'object' && resBody !== null) {
        const bodyObj = resBody as Record<string, unknown>;
        response.status(status).json({
          statusCode: status,
          errorCode:
            (bodyObj.code as string) ||
            (bodyObj.errorCode as string) ||
            `HTTP_${status}`,
          error: (bodyObj.error as string) || HttpStatus[status] || 'Error',
          message: bodyObj.message ?? exception.message,
          timestamp,
          path,
          ...bodyObj,
        });
        return;
      }

      response.status(status).json({
        statusCode: status,
        errorCode: `HTTP_${status}`,
        error: HttpStatus[status] || 'Error',
        message: String(resBody),
        timestamp,
        path,
      });
      return;
    }

    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      const { status, errorCode, message, error } = this.mapPrismaError(
        exception.code,
      );
      response.status(status).json({
        statusCode: status,
        errorCode,
        error,
        message,
        timestamp,
        path,
      });
      return;
    }

    this.logger.error(
      `Unhandled exception on ${request?.method} ${path}`,
      exception instanceof Error ? exception.stack : String(exception),
    );

    response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
      errorCode: 'INTERNAL_SERVER_ERROR',
      error: 'Internal Server Error',
      message: 'An unexpected internal server error occurred.',
      timestamp,
      path,
    });
  }

  private mapPrismaError(code: string): {
    status: number;
    errorCode: string;
    error: string;
    message: string;
  } {
    switch (code) {
      case 'P2002':
        return {
          status: HttpStatus.CONFLICT,
          errorCode: 'UNIQUE_CONSTRAINT_VIOLATION',
          error: 'Conflict',
          message: 'A record with the provided unique field already exists.',
        };
      case 'P2025':
        return {
          status: HttpStatus.NOT_FOUND,
          errorCode: 'RECORD_NOT_FOUND',
          error: 'Not Found',
          message: 'The requested resource record was not found.',
        };
      case 'P2003':
        return {
          status: HttpStatus.BAD_REQUEST,
          errorCode: 'FOREIGN_KEY_VIOLATION',
          error: 'Bad Request',
          message: 'Referenced relation record does not exist.',
        };
      default:
        return {
          status: HttpStatus.BAD_REQUEST,
          errorCode: `PRISMA_${code}`,
          error: 'Bad Request',
          message: 'Database request could not be completed.',
        };
    }
  }
}

