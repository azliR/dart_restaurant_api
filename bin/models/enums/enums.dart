enum DiscountType {
  fixed,
  percentage;

  factory DiscountType.fromString(String? value) {
    switch (value) {
      case 'fixed':
        return DiscountType.fixed;
      case 'percentage':
        return DiscountType.percentage;
      default:
        throw FormatException('Invalid discount type: $value');
    }
  }
}

enum OrderStatus {
  pending,
  preparing,
  ready,
  complete,
  cancelled;

  factory OrderStatus.fromString(String? value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'complete':
        return OrderStatus.complete;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        throw FormatException('Invalid order status: $value');
    }
  }
}

enum OrderType {
  now,
  scheduled;

  factory OrderType.fromString(String? name) {
    switch (name) {
      case 'scheduled':
        return OrderType.scheduled;
      case 'now':
        return OrderType.now;
      default:
        throw FormatException('Invalid order type: $name');
    }
  }
}

enum PickupType {
  pickup,
  dineIn;

  factory PickupType.fromString(String? name) {
    switch (name) {
      case 'pickup':
        return PickupType.pickup;
      case 'dine-in':
        return PickupType.dineIn;
      default:
        throw FormatException('Invalid pickup type: $name');
    }
  }

  String get name {
    switch (this) {
      case PickupType.pickup:
        return 'pickup';
      case PickupType.dineIn:
        return 'dine-in';
    }
  }
}

enum StoreRole {
  admin,
  staff;

  factory StoreRole.fromString(String? value) {
    switch (value) {
      case 'admin':
        return StoreRole.admin;
      case 'staff':
        return StoreRole.staff;
      default:
        throw FormatException('Invalid store role: $value');
    }
  }
}
