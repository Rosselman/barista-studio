import '../models/wheel_loadout.dart';

class DefaultLoadouts {
  static final WheelLoadout summerIcedWheel = WheelLoadout(
    id: 'default-loadout-summer-iced-wheel',
    name: 'Summer Iced Wheel',
    description: '13 refreshing iced coffees, cold foams, and nitrogen cascades tailored for hot days.',
    createdAt: DateTime(2026, 1, 1),
    slots: const [
      LoadoutSlotEntry(slotIndex: 0, recipeId: '2d5eaea7-349e-499d-86a7-4d606e2ff735', recipeName: 'Iced Frappe'),
      LoadoutSlotEntry(slotIndex: 1, recipeId: 'fcf0a803-933d-4b24-926c-8efa1405be06', recipeName: 'Nitro Cold Foam'),
      LoadoutSlotEntry(slotIndex: 2, recipeId: 'b8192a34-0123-4567-89ab-cdef01234567', recipeName: 'Espresso Freddo'),
      LoadoutSlotEntry(slotIndex: 3, recipeId: '67a89b01-2345-6789-abcd-ef0123456789', recipeName: 'Cold Shakerato'),
      LoadoutSlotEntry(slotIndex: 4, recipeId: '78901234-5678-9abc-def0-123456789012', recipeName: 'Iced Caramel Mac'),
      LoadoutSlotEntry(slotIndex: 5, recipeId: '89012345-6789-abcd-ef01-234567890123', recipeName: 'Brown Sugar Oat'),
      LoadoutSlotEntry(slotIndex: 6, recipeId: '90123456-789a-bcde-f012-345678901234', recipeName: 'Vanilla Sweet Foam'),
      LoadoutSlotEntry(slotIndex: 7, recipeId: '01234567-89ab-cdef-0123-456789abcdef', recipeName: 'Salted Caramel Foam'),
      LoadoutSlotEntry(slotIndex: 8, recipeId: '12345678-9abc-def0-1234-56789abcdef0', recipeName: 'Iced Mocha Cloud'),
      LoadoutSlotEntry(slotIndex: 9, recipeId: 'e528b741-0f72-46b1-91a5-8321de620401', recipeName: 'Espresso Tonic'),
      LoadoutSlotEntry(slotIndex: 10, recipeId: '8a3c4d12-bf91-4e78-90b5-12a84976cf33', recipeName: 'Coconut Cold Whip'),
      LoadoutSlotEntry(slotIndex: 11, recipeId: 'a1b2c3d4-8888-4444-8888-000000000008', recipeName: 'Whipped Espresso'),
      LoadoutSlotEntry(slotIndex: 12, recipeId: 'e3161968-5809-4e91-aa41-786248beb1e3', recipeName: 'Affogato Foam'),
    ],
  );

  static final WheelLoadout winterWarmers = WheelLoadout(
    id: 'default-loadout-winter-warmers',
    name: 'Winter Warmers',
    description: '13 velvety hot coffees, melted real chocolates, and soothing spiced winter comforts.',
    createdAt: DateTime(2026, 1, 1),
    slots: const [
      LoadoutSlotEntry(slotIndex: 0, recipeId: '6450bd62-b706-44e7-8b67-7063ec64a492', recipeName: 'Cappuccino'),
      LoadoutSlotEntry(slotIndex: 1, recipeId: 'af52e842-da9a-4fb8-a50c-449744b17123', recipeName: 'Flat White'),
      LoadoutSlotEntry(slotIndex: 2, recipeId: '3de2e7cb-318a-4133-95b6-6b5e211c605d', recipeName: 'Hot Chocolate'),
      LoadoutSlotEntry(slotIndex: 3, recipeId: '23456789-abcd-ef01-2345-6789abcdef01', recipeName: 'Mexican Cocoa'),
      LoadoutSlotEntry(slotIndex: 4, recipeId: 'c8816c93-6893-4be9-a561-148fe7f04037', recipeName: 'Mocha Viennois'),
      LoadoutSlotEntry(slotIndex: 5, recipeId: '1a938c4d-22f1-46bb-90ea-37dc882b4512', recipeName: 'White Choc Mocha'),
      LoadoutSlotEntry(slotIndex: 6, recipeId: '456789ab-cdef-0123-4567-89abcdef0123', recipeName: 'Spiced Chai'),
      LoadoutSlotEntry(slotIndex: 7, recipeId: '56789abc-def0-1234-5678-9abcdef01234', recipeName: 'London Fog'),
      LoadoutSlotEntry(slotIndex: 8, recipeId: 'd851ea74-3ca5-49e4-c4d8-16540b953734', recipeName: 'Irish Velvet'),
      LoadoutSlotEntry(slotIndex: 9, recipeId: 'fa730c96-5ec7-4ba6-e6fa-38762db75956', recipeName: 'Biscoff Swirl'),
      LoadoutSlotEntry(slotIndex: 10, recipeId: '88390b1c-7201-49b8-a764-15967280aa11', recipeName: 'Vienna Melange'),
      LoadoutSlotEntry(slotIndex: 11, recipeId: '9abcdef0-1234-5678-9abc-def012345678', recipeName: 'Spiced Cider'),
      LoadoutSlotEntry(slotIndex: 12, recipeId: '1c952eb8-70e9-4dc8-081c-5a984fd97b78', recipeName: 'Chai Ganache'),
    ],
  );

  static final WheelLoadout houseGuests = WheelLoadout(
    id: 'default-loadout-house-guests',
    name: 'House Guests',
    description: '13 versatile crowd-pleasers: barista classics, sweet steamers, babyccinos, and dairy-free options.',
    createdAt: DateTime(2026, 1, 1),
    slots: const [
      LoadoutSlotEntry(slotIndex: 0, recipeId: '6450bd62-b706-44e7-8b67-7063ec64a492', recipeName: 'Cappuccino'),
      LoadoutSlotEntry(slotIndex: 1, recipeId: 'd4648f3a-7a66-4e51-bb3d-848ed1176709', recipeName: 'Latte Macchiato'),
      LoadoutSlotEntry(slotIndex: 2, recipeId: 'af52e842-da9a-4fb8-a50c-449744b17123', recipeName: 'Flat White'),
      LoadoutSlotEntry(slotIndex: 3, recipeId: '5e7f21a4-98c3-4d62-a279-88fb713a2901', recipeName: 'Velvet Cortado'),
      LoadoutSlotEntry(slotIndex: 4, recipeId: 'e394017a-8b4e-4f01-9a72-11cdeef88990', recipeName: 'Spanish Latte'),
      LoadoutSlotEntry(slotIndex: 5, recipeId: '3de2e7cb-318a-4133-95b6-6b5e211c605d', recipeName: 'Hot Chocolate'),
      LoadoutSlotEntry(slotIndex: 6, recipeId: '789abcde-f012-3456-789a-bcdef0123456', recipeName: 'Vanilla Steamer'),
      LoadoutSlotEntry(slotIndex: 7, recipeId: '6789abcd-ef01-2345-6789-abcdef012345', recipeName: 'Babyccino'),
      LoadoutSlotEntry(slotIndex: 8, recipeId: 'bad60b4f-68e8-4f65-95db-276600bd0ba7', recipeName: 'Matcha Silk'),
      LoadoutSlotEntry(slotIndex: 9, recipeId: '2d5eaea7-349e-499d-86a7-4d606e2ff735', recipeName: 'Iced Frappe'),
      LoadoutSlotEntry(slotIndex: 10, recipeId: '89012345-6789-abcd-ef01-234567890123', recipeName: 'Brown Sugar Oat'),
      LoadoutSlotEntry(slotIndex: 11, recipeId: '7b81c4e9-1234-4b99-90aa-33ff55881122', recipeName: 'Oat Microfoam 58'),
      LoadoutSlotEntry(slotIndex: 12, recipeId: 'fcf0a803-933d-4b24-926c-8efa1405be06', recipeName: 'Nitro Cold Foam'),
    ],
  );

  static final List<WheelLoadout> defaults = [
    summerIcedWheel,
    winterWarmers,
    houseGuests,
  ];
}
