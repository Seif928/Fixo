import { ApiProperty } from '@nestjs/swagger';
import { PaymentMethodType } from '@prisma/client';
import { IsEnum, IsNotEmpty } from 'class-validator';

export class CheckoutBookingDto {
  @ApiProperty({
    enum: PaymentMethodType,
    example: PaymentMethodType.CASH_ON_SERVICE,
    description:
      'Payment method for checkout. Currently only CASH_ON_SERVICE is accepted.',
  })
  @IsNotEmpty({ message: 'paymentMethod is required' })
  @IsEnum(PaymentMethodType, {
    message: `paymentMethod must be one of: ${Object.values(PaymentMethodType).join(', ')}`,
  })
  paymentMethod: PaymentMethodType;
}

