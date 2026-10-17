import '../models/phase.dart';
import '../models/recipe.dart';

class PresetCatalog {
  static const List<String> categories = [
    'All',
    'Hot',
    'Iced / Cold Foam',
    'Plant-Based / Non-Dairy',
    'Chocolate & Matcha',
    'Specialty',
  ];

  static final List<Recipe> presets = [
    // --- HOT CLASSICS ---
    Recipe(
      id: '6450bd62-b706-44e7-8b67-7063ec64a492',
      name: 'Cappuccino',
      description: 'Classic Italian cappuccino with a dense, glossy microfoam crown.',
      category: 'Hot',
      phases: [
        Phase.clamped(speed: 3200, accel: 800, temp: 40, duration: 25),
        Phase.clamped(speed: 1100, accel: 700, temp: 64, duration: 15),
      ],
      ingredients: [
        '100 ml Fresh cold whole or semi-skimmed milk',
        '1 Nespresso Espresso or Ristretto capsule (40 ml)',
        'Optional: dusting of fine cocoa powder',
      ],
      instructions: [
        'Insert the Barista whisk into the bottom of the jug.',
        'Pour 100 ml of cold milk into the jug (up to the lower level mark).',
        'Close the lid, flash or select Cappuccino, and press the start button.',
        'Meanwhile, brew your espresso into a cappuccino cup.',
        'Once finished, gently swirl the jug and pour the silky microfoam over the espresso.',
      ],
    ),
    Recipe(
      id: 'd4648f3a-7a66-4e51-bb3d-848ed1176709',
      name: 'Latte Macchiato',
      description: 'Layered warm textured milk with light, airy foam and dramatic espresso suspension.',
      category: 'Hot',
      phases: [
        Phase.clamped(speed: 2800, accel: 650, temp: 48, duration: 30),
        Phase.clamped(speed: 1400, accel: 500, temp: 65, duration: 15),
      ],
      ingredients: [
        '150 ml Fresh cold whole milk',
        '1 Nespresso Espresso capsule (40 ml)',
      ],
      instructions: [
        'Insert the whisk into the Barista jug.',
        'Add 150 ml of cold milk into the jug.',
        'Close lid and trigger the Latte Macchiato recipe on the machine.',
        'Pour the hot textured milk and froth into a tall glass; allow 30 seconds to settle into layers.',
        'Brew the espresso shot directly through the center of the foam.',
      ],
    ),
    Recipe(
      id: 'af52e842-da9a-4fb8-a50c-449744b17123',
      name: 'Flat White',
      description: 'Silky, glossy microfoam with tight aeration expertly blended for a double ristretto.',
      category: 'Hot',
      phases: [
        Phase.clamped(speed: 3600, accel: 900, temp: 50, duration: 20),
        Phase.clamped(speed: 900, accel: 400, temp: 62, duration: 20),
      ],
      ingredients: [
        '120 ml Fresh cold whole milk',
        '2 Nespresso Ristretto capsules (50 ml total)',
      ],
      instructions: [
        'Place whisk into the jug.',
        'Pour 120 ml milk into the jug.',
        'Start the Flat White recipe.',
        'Extract a double ristretto into a ceramic tulip cup.',
        'Tap the jug lightly on the counter to remove bubbles and fold foam smoothly into the espresso.',
      ],
    ),
    Recipe(
      id: '5e7f21a4-98c3-4d62-a279-88fb713a2901',
      name: 'Velvet Cortado',
      description: 'Equal parts dense Spanish textured milk and intense espresso with a velvety mouthfeel.',
      category: 'Hot',
      phases: [
        Phase.clamped(speed: 2900, accel: 750, temp: 45, duration: 18),
        Phase.clamped(speed: 1200, accel: 500, temp: 60, duration: 12),
      ],
      ingredients: [
        '60 ml Cold whole milk',
        '1 Nespresso Ristretto or intense espresso capsule (40 ml)',
      ],
      instructions: [
        'Insert whisk and pour 60 ml milk into the jug.',
        'Execute Velvet Cortado on the Barista.',
        'Brew espresso into a 130 ml Gibraltar or Cortado glass.',
        'Pour equal volume of warm textured milk over the coffee.',
      ],
    ),

    // --- ICED / COLD FOAM ---
    Recipe(
      id: '2d5eaea7-349e-499d-86a7-4d606e2ff735',
      name: 'Iced Frappé',
      description: 'Ultra-chilled dense cold foam with zero induction heating for iced refreshments.',
      category: 'Iced / Cold Foam',
      phases: [
        Phase.clamped(speed: 3800, accel: 1200, temp: 0, duration: 40),
      ],
      ingredients: [
        '100 ml Skimmed or semi-skimmed milk (refrigerated at 4°C)',
        '3 Ice cubes (in serving glass)',
        '1 Nespresso Espresso capsule brewed over ice',
        '1 tsp Simple sugar syrup (optional)',
      ],
      instructions: [
        'Ensure the jug and whisk are clean and cold.',
        'Pour 100 ml cold milk into the jug. Ensure induction heater remains at 0°C.',
        'Run Iced Frappé cycle. The high-speed vortex creates stiff cold microfoam.',
        'Place ice cubes and brewed espresso in a glass; spoon cold foam over top.',
      ],
    ),
    Recipe(
      id: 'fcf0a803-933d-4b24-926c-8efa1405be06',
      name: 'Nitro Cold Foam',
      description: 'Cascading nitro-style velvet foam float for cold brews and iced americanos.',
      category: 'Iced / Cold Foam',
      phases: [
        Phase.clamped(speed: 4000, accel: 1500, temp: 0, duration: 32),
      ],
      ingredients: [
        '80 ml Skimmed milk or heavy cream + milk (50/50 mix)',
        '150 ml Cold brew coffee',
        'Ice cubes',
        '1/2 tsp Vanilla syrup',
      ],
      instructions: [
        'Add chilled milk mixture and vanilla syrup to the Barista jug.',
        'Start Nitro Cold Foam program (4000 RPM maximum shear aeration, 0°C).',
        'Fill a glass with ice and cold brew coffee.',
        'Slowly pour the dense cascading white foam float on top.',
      ],
    ),
    Recipe(
      id: '8a3c4d12-bf91-4e78-90b5-12a84976cf33',
      name: 'Coconut Cold Whip',
      description: 'Tropical chilled foam using rich coconut milk and light vanilla froth.',
      category: 'Iced / Cold Foam',
      phases: [
        Phase.clamped(speed: 3600, accel: 1100, temp: 0, duration: 35),
      ],
      ingredients: [
        '90 ml Barista Coconut Milk beverage (chilled)',
        '1 pump Coconut or vanilla syrup',
        '1 Nespresso Iced Leggero or Freddo Delicato shot',
        'Ice cubes',
      ],
      instructions: [
        'Pour cold coconut milk into the Barista jug.',
        'Run Coconut Cold Whip with heater OFF.',
        'Extract iced coffee capsule over 3 ice cubes in a glass.',
        'Crown with airy, fragrant coconut cold froth.',
      ],
    ),

    // --- PLANT-BASED / NON-DAIRY ---
    Recipe(
      id: '7b81c4e9-1234-4b99-90aa-33ff55881122',
      name: 'Oat Microfoam 58',
      description: 'Gentle temperature curve strictly capped at 58°C to prevent oat milk protein breakdown.',
      category: 'Plant-Based / Non-Dairy',
      phases: [
        Phase.clamped(speed: 2900, accel: 700, temp: 45, duration: 25),
        Phase.clamped(speed: 1300, accel: 450, temp: 58, duration: 20),
      ],
      ingredients: [
        '130 ml Barista Edition Oat Milk (e.g. Oatly Barista)',
        '1 Nespresso Master Origins Colombia or Ethiopia capsule',
      ],
      instructions: [
        'Shake oat milk carton vigorously before measuring.',
        'Pour 130 ml oat milk into the jug.',
        'Run Oat Microfoam 58. The temperature is strictly maintained under 60°C to preserve natural oat sweetness.',
        'Brew light roast espresso into a cup and fold the glossy oat foam gently.',
      ],
    ),
    Recipe(
      id: '9922bb44-88aa-47cc-91ee-447733221100',
      name: 'Almond Velvet 55',
      description: 'Low-temperature whip engineered specifically for delicate almond milk proteins.',
      category: 'Plant-Based / Non-Dairy',
      phases: [
        Phase.clamped(speed: 2700, accel: 600, temp: 40, duration: 22),
        Phase.clamped(speed: 1100, accel: 400, temp: 55, duration: 18),
      ],
      ingredients: [
        '120 ml Barista Almond Milk',
        '1 Nespresso Volluto or Cosi espresso shot',
        'Optional: drop of almond extract or agave syrup',
      ],
      instructions: [
        'Add almond milk to the Barista jug.',
        'Run Almond Velvet 55 cycle.',
        'Brew sweet floral espresso.',
        'Pour textured almond foam into the cup, finishing with subtle latte art.',
      ],
    ),
    Recipe(
      id: '33445566-7788-99aa-bbcc-ddeeff001122',
      name: 'Soy Latte Silk',
      description: 'Multi-stage gentle stir optimizing soy milk foam density without curdling.',
      category: 'Plant-Based / Non-Dairy',
      phases: [
        Phase.clamped(speed: 2500, accel: 550, temp: 45, duration: 25),
        Phase.clamped(speed: 1200, accel: 400, temp: 62, duration: 20),
      ],
      ingredients: [
        '140 ml Fresh organic soy milk',
        '1 Nespresso Fortissio Lungo or Espresso capsule',
      ],
      instructions: [
        'Pour soy milk into the Barista jug.',
        'Start Soy Latte Silk program.',
        'Brew espresso or lungo into mug.',
        'Pour silky microfoam smoothly over coffee.',
      ],
    ),

    // --- CHOCOLATE & MATCHA ---
    Recipe(
      id: '3de2e7cb-318a-4133-95b6-6b5e211c605d',
      name: 'Hot Chocolate',
      description: 'Continuous slow stir melting real dark chocolate squares seamlessly into piping hot milk.',
      category: 'Chocolate & Matcha',
      phases: [
        Phase.clamped(speed: 1500, accel: 500, temp: 55, duration: 45),
        Phase.clamped(speed: 1800, accel: 600, temp: 70, duration: 45),
      ],
      ingredients: [
        '150 ml Whole milk',
        '25-30g High quality dark chocolate (cut into small squares)',
        'Pinch of sea salt or cinnamon',
      ],
      instructions: [
        'Insert whisk and pour milk into the jug.',
        'Drop chocolate squares directly around the whisk.',
        'Start Hot Chocolate program. Induction heating reaches 70°C to melt cocoa butter completely.',
        'Pour rich, molten hot chocolate into a mug and top with whipped cream.',
      ],
    ),
    Recipe(
      id: 'c8816c93-6893-4be9-a561-148fe7f04037',
      name: 'Mocha Viennois',
      description: 'Harmonious fusion of cocoa powder, bold espresso, and creamy textured milk.',
      category: 'Chocolate & Matcha',
      phases: [
        Phase.clamped(speed: 2200, accel: 700, temp: 50, duration: 30),
        Phase.clamped(speed: 1200, accel: 500, temp: 67, duration: 20),
      ],
      ingredients: [
        '130 ml Whole milk',
        '1 tbsp Pure cocoa powder',
        '1 Nespresso Arpeggio or Ristretto capsule',
        'Whipped cream & chocolate shavings for garnish',
      ],
      instructions: [
        'Place milk and cocoa powder in the jug.',
        'Run Mocha Viennois cycle.',
        'Brew intense espresso shot into a large glass.',
        'Pour hot chocolate milk over espresso, garnish with whipped cream and cocoa.',
      ],
    ),
    Recipe(
      id: 'bad60b4f-68e8-4f65-95db-276600bd0ba7',
      name: 'Matcha Silk',
      description: 'High shear rotation that dissolves Japanese ceremonial matcha lumps into emerald microfoam.',
      category: 'Chocolate & Matcha',
      phases: [
        Phase.clamped(speed: 2600, accel: 800, temp: 45, duration: 25),
        Phase.clamped(speed: 1600, accel: 600, temp: 66, duration: 25),
      ],
      ingredients: [
        '140 ml Oat milk or whole milk',
        '1.5 tsp Ceremonial grade matcha powder (sifted)',
        '1 tsp Honey or vanilla syrup',
      ],
      instructions: [
        'Pour milk into the Barista jug.',
        'Add sifted matcha powder and honey directly onto the milk.',
        'Start Matcha Silk program. Rapid whisking dissolves lumps completely.',
        'Pour vibrant green matcha foam into a ceramic bowl or cup.',
      ],
    ),
    Recipe(
      id: '11223344-5566-7788-9900-aabbccddeeff',
      name: 'Matcha Cloud',
      description: 'Cold emerald sweet matcha froth floating atop iced milk or cold brew.',
      category: 'Chocolate & Matcha',
      phases: [
        Phase.clamped(speed: 3700, accel: 1300, temp: 0, duration: 38),
      ],
      ingredients: [
        '80 ml Chilled skimmed milk or almond milk',
        '1 tsp Matcha powder',
        '1 tsp Agave or vanilla syrup',
        '120 ml Iced water or iced milk in glass',
      ],
      instructions: [
        'Add cold milk, matcha, and sweetener to the Barista jug.',
        'Run Matcha Cloud with 0°C cold froth setting.',
        'Prepare glass with ice cubes and 120 ml iced oat or almond milk.',
        'Gently float the dense emerald matcha cloud on top.',
      ],
    ),

    // --- SPECIALTY ---
    Recipe(
      id: 'c1a4a231-43b4-47ed-b7ff-4f9198e4a35e',
      name: 'Turmeric Elixir',
      description: 'Aromatic golden milk infusion with ground turmeric, cinnamon, and black pepper.',
      category: 'Specialty',
      phases: [
        Phase.clamped(speed: 1900, accel: 500, temp: 52, duration: 30),
        Phase.clamped(speed: 2400, accel: 700, temp: 68, duration: 20),
      ],
      ingredients: [
        '140 ml Almond or coconut milk',
        '1/2 tsp Ground turmeric',
        '1/4 tsp Ground cinnamon',
        'Pinch of black pepper (enhances curcumin absorption)',
        '1 tsp Maple syrup',
      ],
      instructions: [
        'Add milk, spices, and maple syrup to the jug.',
        'Run Turmeric Elixir on your Barista.',
        'Pour the glowing golden warm tonic into a mug and dust with cinnamon.',
      ],
    ),
    Recipe(
      id: 'a0b1c2d3-e4f5-4678-90ab-cdef12345678',
      name: 'Dirty Chai',
      description: 'Spiced Indian masala chai froth married to an espresso shot.',
      category: 'Specialty',
      phases: [
        Phase.clamped(speed: 2800, accel: 700, temp: 48, duration: 25),
        Phase.clamped(speed: 1400, accel: 500, temp: 66, duration: 20),
      ],
      ingredients: [
        '120 ml Whole or oat milk',
        '2 tbsp Spiced chai concentrate or chai tea syrup',
        '1 Nespresso Espresso shot',
        'Ground star anise or cinnamon for garnish',
      ],
      instructions: [
        'Pour milk and chai syrup into the Barista jug.',
        'Start Dirty Chai cycle.',
        'Brew fresh espresso into a ceramic mug.',
        'Pour aromatic spiced froth over the espresso and sprinkle with cinnamon.',
      ],
    ),
    Recipe(
      id: '9f8e7d6c-5b4a-4321-fedc-ba9876543210',
      name: 'Affogato Cream',
      description: 'Ultra-rich dense cream froth designed to pour piping hot over gelato.',
      category: 'Specialty',
      phases: [
        Phase.clamped(speed: 2100, accel: 600, temp: 68, duration: 25),
      ],
      ingredients: [
        '70 ml Heavy cream & whole milk (equal parts)',
        '1 Scoop Vanilla bean gelato',
        '1 Nespresso Ristretto capsule',
      ],
      instructions: [
        'Add cream and milk mixture to the Barista jug.',
        'Start Affogato Cream cycle (heats to 68°C).',
        'Place 1 generous scoop of vanilla bean gelato in a bowl or dessert glass.',
        'Extract hot ristretto over gelato, then pour the warm velvety cream foam over everything.',
      ],
    ),
    Recipe(
      id: '44556677-8899-0011-2233-445566778899',
      name: 'Cardamom Rose',
      description: 'Middle Eastern inspired floral warm foam with cracked green cardamom and rose water.',
      category: 'Specialty',
      phases: [
        Phase.clamped(speed: 2400, accel: 650, temp: 50, duration: 25),
        Phase.clamped(speed: 1300, accel: 450, temp: 65, duration: 20),
      ],
      ingredients: [
        '130 ml Whole milk',
        '2 Crushed green cardamom pods (seeds only)',
        '1/2 tsp Culinary rose water',
        '1 tsp Honey',
        '1 Nespresso Espresso shot',
      ],
      instructions: [
        'Add milk, crushed cardamom seeds, rose water, and honey to the jug.',
        'Run Cardamom Rose program.',
        'Brew espresso into a cup.',
        'Strain or pour the fragrant spiced foam over the coffee.',
      ],
    ),
    Recipe(
      id: '55667788-9900-1122-3344-556677889900',
      name: 'Pistachio Crema',
      description: 'Silky warm cream froth infused with pure Sicilian pistachio paste.',
      category: 'Specialty',
      phases: [
        Phase.clamped(speed: 2300, accel: 600, temp: 52, duration: 28),
        Phase.clamped(speed: 1500, accel: 500, temp: 66, duration: 18),
      ],
      ingredients: [
        '130 ml Whole milk',
        '1 heaped tsp 100% Pure unsweetened pistachio paste',
        '1 tsp Sugar or agave',
        '1 Nespresso Espresso capsule',
        'Crushed roasted pistachios for topping',
      ],
      instructions: [
        'Whisk milk, pistachio paste, and sugar in the Barista jug.',
        'Run Pistachio Crema cycle.',
        'Extract espresso shot into a glass cup.',
        'Pour green-tinted velvety foam over coffee and top with crushed pistachios.',
      ],
    ),
  ];

  /// Lookup preset by 16-byte UUID
  static Recipe? findByUuid(String uuid) {
    final clean = uuid.toLowerCase();
    try {
      return presets.firstWhere((p) => p.id.toLowerCase() == clean);
    } catch (_) {
      return null;
    }
  }
}
