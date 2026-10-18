import '../models/phase.dart';
import '../models/recipe.dart';
import '../models/recipe_step.dart';

class PresetCatalog {
  static const List<String> categories = [
    'All',
    'Multi-Step',
    'Hot Coffee',
    'Iced & Cold Coffee',
    'Non-Coffee',
    'Dairy',
    'Non-Dairy',
    'Cold Foam & Textures',
  ];

  static final List<Recipe> presets = [
    // ==========================================
    // --- HOT COFFEE CLASSICS & SPECIALTIES ---
    // ==========================================
    Recipe(
      id: '6450bd62-b706-44e7-8b67-7063ec64a492',
      name: 'Cappuccino',
      description: 'Classic Italian cappuccino with a dense, glossy microfoam crown.',
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Dairy'],
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
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Dairy'],
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
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Dairy'],
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
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Dairy'],
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
    Recipe(
      id: '88390b1c-7201-49b8-a764-15967280aa11',
      name: 'Vienna Melange',
      description: 'Traditional Viennese café staple with light fluffy foam topped with whipped cream.',
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Dairy'],
      phases: [
        Phase.clamped(speed: 3100, accel: 800, temp: 45, duration: 22),
        Phase.clamped(speed: 1300, accel: 500, temp: 64, duration: 16),
      ],
      ingredients: [
        '110 ml Whole milk',
        '1 Nespresso Lungo or double espresso shot',
        'Whipped cream & cocoa powder for finishing',
      ],
      instructions: [
        'Pour 110 ml whole milk into the jug.',
        'Run Vienna Melange cycle.',
        'Extract coffee into a wide ceramic cup.',
        'Pour the velvety milk foam over the coffee and crown with fresh whipped cream.',
      ],
    ),
    Recipe(
      id: 'e394017a-8b4e-4f01-9a72-11cdeef88990',
      name: 'Spanish Latte',
      description: 'Sweet condensed milk emulsified into rich textured whole milk paired with bold espresso.',
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Dairy'],
      phases: [
        Phase.clamped(speed: 2500, accel: 600, temp: 50, duration: 25),
        Phase.clamped(speed: 1400, accel: 500, temp: 66, duration: 20),
      ],
      ingredients: [
        '110 ml Whole milk',
        '20 ml Sweetened condensed milk',
        '1 Nespresso Espresso shot (40 ml)',
      ],
      instructions: [
        'Add condensed milk and whole milk directly to the Barista jug.',
        'Start Spanish Latte cycle to emulsify the thick condensed milk.',
        'Brew espresso into a glass tumbler.',
        'Pour the sweet, rich warm milk foam over the espresso.',
      ],
    ),
    Recipe(
      id: '5f92c103-6a84-48d9-bf12-984e72ba6501',
      name: 'Caffe Breve',
      description: 'Decadent American espresso drink made with steamed half-and-half for an ultra-thick body.',
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Dairy'],
      phases: [
        Phase.clamped(speed: 2600, accel: 700, temp: 48, duration: 25),
        Phase.clamped(speed: 1200, accel: 450, temp: 65, duration: 18),
      ],
      ingredients: [
        '100 ml Half-and-half (equal parts milk and single cream)',
        '1 Nespresso Espresso capsule',
      ],
      instructions: [
        'Pour 100 ml cold half-and-half into the Barista jug.',
        'Run Caffe Breve program.',
        'Brew espresso into a ceramic cappuccino cup.',
        'Pour the ultra-thick, velvety hot cream froth over coffee.',
      ],
    ),
    Recipe(
      id: 'c8816c93-6893-4be9-a561-148fe7f04037',
      name: 'Mocha Viennois',
      description: 'Harmonious fusion of cocoa powder, bold espresso, and creamy textured milk.',
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Non-Coffee', 'Dairy'],
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
      id: '1a938c4d-22f1-46bb-90ea-37dc882b4512',
      name: 'White Choc Mocha',
      description: 'Sweet real white chocolate melted into silky hot milk and paired with dark roasted espresso.',
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Non-Coffee', 'Dairy'],
      phases: [
        Phase.clamped(speed: 2000, accel: 600, temp: 55, duration: 35),
        Phase.clamped(speed: 1500, accel: 500, temp: 68, duration: 20),
      ],
      ingredients: [
        '120 ml Whole milk',
        '25g Belgian white chocolate drops or small pieces',
        '1 Nespresso Espresso shot',
      ],
      instructions: [
        'Place milk and white chocolate pieces into the jug.',
        'Start White Choc Mocha program to melt cocoa butter fully at 68°C.',
        'Brew espresso into a mug.',
        'Pour the luxurious white chocolate foam over espresso and enjoy.',
      ],
    ),
    Recipe(
      id: '9f8e7d6c-5b4a-4321-fedc-ba9876543210',
      name: 'Affogato Cream',
      description: 'Ultra-rich dense cream froth designed to pour piping hot over vanilla bean gelato.',
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Dairy'],
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
      id: '55667788-9900-1122-3344-556677889900',
      name: 'Pistachio Crema',
      description: 'Silky warm cream froth infused with pure Sicilian pistachio paste.',
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Dairy'],
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
    Recipe(
      id: '44556677-8899-0011-2233-445566778899',
      name: 'Cardamom Rose',
      description: 'Middle Eastern inspired floral warm foam with cracked green cardamom and rose water.',
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Dairy'],
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
      id: '7d341902-99ca-4c28-98e3-bb2300456101',
      name: 'Caramel Cortado',
      description: 'Smooth dulce de leche melted into warm microfoam for a sweet Spanish cortado.',
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Dairy'],
      phases: [
        Phase.clamped(speed: 2800, accel: 700, temp: 48, duration: 20),
        Phase.clamped(speed: 1300, accel: 500, temp: 64, duration: 15),
      ],
      ingredients: [
        '80 ml Whole milk',
        '1 tbsp Dulce de leche or thick caramel sauce',
        '1 Nespresso Espresso capsule (40 ml)',
      ],
      instructions: [
        'Add milk and caramel sauce directly to the jug.',
        'Run Caramel Cortado program.',
        'Brew espresso into a cortado glass.',
        'Pour the golden, silky caramel foam over coffee.',
      ],
    ),
    Recipe(
      id: 'a0b1c2d3-e4f5-4678-90ab-cdef12345678',
      name: 'Dirty Chai',
      description: 'Spiced Indian masala chai froth married to an espresso shot.',
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Non-Coffee', 'Dairy'],
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

    // ==========================================
    // --- ICED & COLD COFFEE INNOVATIONS ---
    // ==========================================
    Recipe(
      id: '2d5eaea7-349e-499d-86a7-4d606e2ff735',
      name: 'Iced Frappe',
      description: 'Ultra-chilled dense cold foam with zero induction heating for iced refreshments.',
      category: 'Iced & Cold Coffee',
      tags: const ['Iced & Cold Coffee', 'Dairy', 'Cold Foam & Textures'],
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
      category: 'Iced & Cold Coffee',
      tags: const ['Iced & Cold Coffee', 'Dairy', 'Cold Foam & Textures'],
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
      id: 'b8192a34-0123-4567-89ab-cdef01234567',
      name: 'Espresso Freddo',
      description: 'Greek café favorite: chilled espresso and ice sheared into dense hazelnut crema foam.',
      category: 'Iced & Cold Coffee',
      tags: const ['Iced & Cold Coffee', 'Cold Foam & Textures'],
      phases: [
        Phase.clamped(speed: 3500, accel: 1100, temp: 0, duration: 30),
      ],
      ingredients: [
        '2 Nespresso Espresso shots (80 ml total, fresh hot)',
        '2 Ice cubes in jug',
        '1 tsp Sugar (optional)',
        'Ice cubes in serving glass',
      ],
      instructions: [
        'Brew espresso shots into a cup and dissolve sugar if desired.',
        'Pour espresso into the Barista jug with 2 ice cubes.',
        'Run Espresso Freddo (cold cycle). Whisk rapidly chills and creates a thick hazelnut coffee foam.',
        'Pour over fresh ice in a glass tumbler.',
      ],
    ),
    Recipe(
      id: '67a89b01-2345-6789-abcd-ef0123456789',
      name: 'Cold Shakerato',
      description: 'Italian classic shaken espresso emulsified with cane syrup into an ice-cold velvet foam.',
      category: 'Iced & Cold Coffee',
      tags: const ['Iced & Cold Coffee', 'Cold Foam & Textures'],
      phases: [
        Phase.clamped(speed: 3900, accel: 1400, temp: 0, duration: 28),
      ],
      ingredients: [
        '1 Nespresso Ristretto or intense espresso shot (40 ml)',
        '1 tbsp Cane sugar syrup',
        '2 Ice cubes in the jug',
      ],
      instructions: [
        'Brew hot espresso.',
        'Place espresso, cane syrup, and 2 ice cubes into the Barista jug.',
        'Run Cold Shakerato at 3900 RPM cold.',
        'Strain into a chilled martini or coupe glass for a luxurious foam top.',
      ],
    ),
    Recipe(
      id: '78901234-5678-9abc-def0-123456789012',
      name: 'Iced Caramel Mac',
      description: 'Cold textured milk layer crowned with fresh espresso and vanilla froth.',
      category: 'Iced & Cold Coffee',
      tags: const ['Iced & Cold Coffee', 'Dairy', 'Cold Foam & Textures'],
      phases: [
        Phase.clamped(speed: 3400, accel: 1000, temp: 0, duration: 35),
      ],
      ingredients: [
        '120 ml Cold whole milk',
        '1 tbsp Vanilla syrup',
        '1 Nespresso Espresso shot',
        'Caramel drizzle for topping',
        'Ice cubes',
      ],
      instructions: [
        'Add cold milk and vanilla syrup to the jug and run cycle.',
        'Fill a tall glass with ice.',
        'Pour the cold frothy vanilla milk over the ice.',
        'Gently extract or pour espresso on top, then drizzle with caramel.',
      ],
    ),
    Recipe(
      id: '89012345-6789-abcd-ef01-234567890123',
      name: 'Brown Sugar Oat',
      description: 'Cold whipped oat milk foam with brown sugar syrup and cinnamon over iced blonde espresso.',
      category: 'Iced & Cold Coffee',
      tags: const ['Iced & Cold Coffee', 'Non-Dairy', 'Cold Foam & Textures'],
      phases: [
        Phase.clamped(speed: 3600, accel: 1100, temp: 0, duration: 32),
      ],
      ingredients: [
        '100 ml Barista Oat Milk (chilled)',
        '1 tbsp Brown sugar syrup or dark muscovado syrup',
        'Pinch of ground cinnamon',
        '2 Nespresso Volluto or light roast espresso capsules',
        'Ice cubes',
      ],
      instructions: [
        'Place cold oat milk, brown sugar syrup, and cinnamon into the jug.',
        'Run Brown Sugar Oat cycle with heater off.',
        'Brew espresso shots over ice in a tall glass.',
        'Pour the fragrant spiced oat cold foam on top.',
      ],
    ),
    Recipe(
      id: '90123456-789a-bcde-f012-345678901234',
      name: 'Vanilla Sweet Foam',
      description: 'Barista-style vanilla sweet cream foam float for iced cold brew.',
      category: 'Iced & Cold Coffee',
      tags: const ['Iced & Cold Coffee', 'Dairy', 'Cold Foam & Textures'],
      phases: [
        Phase.clamped(speed: 3700, accel: 1200, temp: 0, duration: 30),
      ],
      ingredients: [
        '50 ml Heavy whipping cream',
        '30 ml Whole milk',
        '1 tbsp Vanilla bean syrup',
        '160 ml Cold brew coffee over ice',
      ],
      instructions: [
        'Pour cream, milk, and vanilla syrup into the Barista jug.',
        'Run Vanilla Sweet Foam program.',
        'Prepare glass with ice and cold brew coffee.',
        'Pour the silky, dense sweet cream foam to float cleanly on top.',
      ],
    ),
    Recipe(
      id: '01234567-89ab-cdef-0123-456789abcdef',
      name: 'Salted Caramel Foam',
      description: 'Savory and sweet cold cream crown with pink Himalayan salt and caramel syrup.',
      category: 'Iced & Cold Coffee',
      tags: const ['Iced & Cold Coffee', 'Dairy', 'Cold Foam & Textures'],
      phases: [
        Phase.clamped(speed: 3800, accel: 1300, temp: 0, duration: 32),
      ],
      ingredients: [
        '50 ml Double cream or heavy whipping cream',
        '30 ml Whole milk',
        '1 tbsp Salted caramel syrup',
        'Pinch of flaky sea salt',
        '150 ml Cold brew or iced americano',
      ],
      instructions: [
        'Combine cream, milk, caramel syrup, and salt in the Barista jug.',
        'Start Salted Caramel Foam cycle.',
        'Prepare cold brew over ice in a tumbler.',
        'Pour the thick, decadent salted foam gently over the coffee.',
      ],
    ),
    Recipe(
      id: '12345678-9abc-def0-1234-56789abcdef0',
      name: 'Iced Mocha Cloud',
      description: 'Decadent chilled chocolate-cream cold foam float over iced espresso and milk.',
      category: 'Iced & Cold Coffee',
      tags: const ['Iced & Cold Coffee', 'Non-Coffee', 'Dairy', 'Cold Foam & Textures'],
      phases: [
        Phase.clamped(speed: 3700, accel: 1200, temp: 0, duration: 34),
      ],
      ingredients: [
        '60 ml Heavy whipping cream',
        '30 ml Whole milk',
        '1 tbsp Chocolate syrup or Dutch cocoa powder',
        '1 Nespresso Espresso shot over iced milk',
      ],
      instructions: [
        'Pour cream, milk, and chocolate syrup into the jug.',
        'Run cold cycle at 3700 RPM to whip chocolate into dense cloud.',
        'Pour espresso and cold milk over ice.',
        'Top with the thick iced mocha cloud float.',
      ],
    ),

    // ==========================================
    // --- NON-COFFEE WARMERS & INFUSIONS ---
    // ==========================================
    Recipe(
      id: '3de2e7cb-318a-4133-95b6-6b5e211c605d',
      name: 'Hot Chocolate',
      description: 'Continuous slow stir melting real dark chocolate squares seamlessly into piping hot milk.',
      category: 'Non-Coffee',
      tags: const ['Non-Coffee', 'Dairy'],
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
      id: '23456789-abcd-ef01-2345-6789abcdef01',
      name: 'Mexican Cocoa',
      description: 'Rich dark chocolate infused with cinnamon, pure vanilla, and a gentle pinch of cayenne pepper.',
      category: 'Non-Coffee',
      tags: const ['Non-Coffee', 'Dairy'],
      phases: [
        Phase.clamped(speed: 1600, accel: 550, temp: 55, duration: 40),
        Phase.clamped(speed: 1900, accel: 600, temp: 70, duration: 40),
      ],
      ingredients: [
        '140 ml Whole milk',
        '30g Dark chocolate (70% cocoa minimum)',
        '1/2 tsp Ground cinnamon',
        'Tiny pinch of cayenne pepper',
        '1 tsp Brown sugar',
      ],
      instructions: [
        'Add milk, chocolate pieces, cinnamon, cayenne, and sugar to the jug.',
        'Run Mexican Cocoa program to dissolve chocolate and bloom the spices.',
        'Pour into a warming ceramic mug.',
        'Garnish with a whole cinnamon stick.',
      ],
    ),
    Recipe(
      id: '3456789a-bcde-f012-3456-789abcdef012',
      name: 'White Hot Cocoa',
      description: 'Creamy melted Belgian white chocolate with Madagascar vanilla bean in hot velvety whole milk.',
      category: 'Non-Coffee',
      tags: const ['Non-Coffee', 'Dairy'],
      phases: [
        Phase.clamped(speed: 1800, accel: 500, temp: 52, duration: 35),
        Phase.clamped(speed: 2100, accel: 600, temp: 68, duration: 30),
      ],
      ingredients: [
        '150 ml Whole milk',
        '35g Belgian white chocolate buttons',
        '1/4 tsp Pure vanilla bean paste',
      ],
      instructions: [
        'Place milk, white chocolate, and vanilla paste into the Barista jug.',
        'Start White Hot Cocoa cycle.',
        'Induction heats gently to 68°C to prevent scorching delicate white chocolate.',
        'Pour creamy, rich white cocoa into your favorite mug.',
      ],
    ),
    Recipe(
      id: 'bad60b4f-68e8-4f65-95db-276600bd0ba7',
      name: 'Matcha Silk',
      description: 'High shear rotation that dissolves Japanese ceremonial matcha lumps into emerald microfoam.',
      category: 'Non-Coffee',
      tags: const ['Non-Coffee', 'Dairy', 'Non-Dairy'],
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
      id: 'c1a4a231-43b4-47ed-b7ff-4f9198e4a35e',
      name: 'Turmeric Elixir',
      description: 'Aromatic golden milk infusion with ground turmeric, cinnamon, and black pepper.',
      category: 'Non-Coffee',
      tags: const ['Non-Coffee', 'Non-Dairy'],
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
      id: '456789ab-cdef-0123-4567-89abcdef0123',
      name: 'Spiced Chai',
      description: 'Aromatic Indian masala chai froth with cinnamon, cardamom, cloves, and ginger.',
      category: 'Non-Coffee',
      tags: const ['Non-Coffee', 'Dairy', 'Non-Dairy'],
      phases: [
        Phase.clamped(speed: 2700, accel: 700, temp: 48, duration: 25),
        Phase.clamped(speed: 1400, accel: 500, temp: 66, duration: 20),
      ],
      ingredients: [
        '130 ml Whole milk or oat milk',
        '2 tbsp Spiced chai concentrate or steeped black tea with chai spices',
        '1 tsp Honey',
      ],
      instructions: [
        'Add milk, chai concentrate, and honey to the jug.',
        'Start Spiced Chai cycle to froth and infuse the warming spices.',
        'Pour into a tall cup and garnish with freshly ground nutmeg.',
      ],
    ),
    Recipe(
      id: '56789abc-def0-1234-5678-9abcdef01234',
      name: 'London Fog',
      description: 'Earl Grey tea infusion with bergamot citrus, vanilla syrup, and silky hot microfoam.',
      category: 'Non-Coffee',
      tags: const ['Non-Coffee', 'Dairy'],
      phases: [
        Phase.clamped(speed: 2800, accel: 750, temp: 46, duration: 25),
        Phase.clamped(speed: 1300, accel: 500, temp: 65, duration: 20),
      ],
      ingredients: [
        '100 ml Whole milk',
        '100 ml Hot brewed concentrated Earl Grey tea',
        '1 tbsp Pure vanilla syrup',
      ],
      instructions: [
        'Brew concentrated Earl Grey tea in your serving mug and stir in vanilla syrup.',
        'Pour milk into the Barista jug and run London Fog cycle.',
        'Pour the silky, sweet microfoam over the fragrant Earl Grey tea.',
      ],
    ),
    Recipe(
      id: '6789abcd-ef01-2345-6789-abcdef012345',
      name: 'Babyccino',
      description: 'Kid-safe gentle 55°C warm sweet milk froth topped with cocoa and mini marshmallows.',
      category: 'Non-Coffee',
      tags: const ['Non-Coffee', 'Dairy'],
      phases: [
        Phase.clamped(speed: 3400, accel: 900, temp: 40, duration: 20),
        Phase.clamped(speed: 1200, accel: 400, temp: 55, duration: 15),
      ],
      ingredients: [
        '100 ml Whole milk',
        '1/2 tsp Honey or vanilla syrup',
        'Cocoa powder for dusting',
        'Mini marshmallows',
      ],
      instructions: [
        'Add milk and sweetener to the Barista jug.',
        'Run Babyccino program. Capped at a kid-safe 55°C to avoid burns while maximizing froth.',
        'Pour into a small cup, dust generously with cocoa powder, and float marshmallows.',
      ],
    ),
    Recipe(
      id: '789abcde-f012-3456-789a-bcdef0123456',
      name: 'Vanilla Steamer',
      description: 'Gentle warm sweetened milk infused with pure vanilla extract; a soothing caffeine-free nightcap.',
      category: 'Non-Coffee',
      tags: const ['Non-Coffee', 'Dairy', 'Non-Dairy'],
      phases: [
        Phase.clamped(speed: 2400, accel: 600, temp: 45, duration: 25),
        Phase.clamped(speed: 1100, accel: 400, temp: 62, duration: 20),
      ],
      ingredients: [
        '150 ml Whole milk or oat milk',
        '1 tbsp Pure vanilla extract or syrup',
        'Pinch of ground cinnamon',
      ],
      instructions: [
        'Pour milk and vanilla into the Barista jug.',
        'Run Vanilla Steamer program.',
        'Pour the soothing, fragrant warm milk into a mug and sprinkle with cinnamon.',
      ],
    ),
    Recipe(
      id: '89abcdef-0123-4567-89ab-cdef01234567',
      name: 'Rooibos Honey',
      description: 'South African red bush tea foam infused with wildflower honey and warm oat or whole milk.',
      category: 'Non-Coffee',
      tags: const ['Non-Coffee', 'Non-Dairy', 'Dairy'],
      phases: [
        Phase.clamped(speed: 2500, accel: 650, temp: 48, duration: 25),
        Phase.clamped(speed: 1300, accel: 450, temp: 66, duration: 20),
      ],
      ingredients: [
        '120 ml Oat milk or whole milk',
        '1 tsp Finely ground red rooibos tea or rooibos concentrate',
        '1 tbsp Wildflower honey',
      ],
      instructions: [
        'Add milk, rooibos, and honey to the Barista jug.',
        'Run Rooibos Honey cycle.',
        'Pour the copper-hued, naturally caffeine-free warm tea latte into a mug.',
      ],
    ),
    Recipe(
      id: '9abcdef0-1234-5678-9abc-def012345678',
      name: 'Spiced Cider',
      description: 'Warm mulled apple cider microfoam with cinnamon stick infusion and brown sugar.',
      category: 'Non-Coffee',
      tags: const ['Non-Coffee'],
      phases: [
        Phase.clamped(speed: 2000, accel: 500, temp: 55, duration: 30),
        Phase.clamped(speed: 2400, accel: 600, temp: 68, duration: 25),
      ],
      ingredients: [
        '140 ml Fresh cloudy apple cider or unfiltered apple juice',
        '1/4 tsp Ground cinnamon',
        '1/4 tsp Ground ginger',
        '1 tsp Brown sugar',
      ],
      instructions: [
        'Pour apple cider and spices into the Barista jug.',
        'Run Spiced Cider cycle. The induction heater warms the juice to aromatic perfection.',
        'Pour the spiced steaming cider into a mug and garnish with a cinnamon stick.',
      ],
    ),

    // ==========================================
    // --- NON-DAIRY & PLANT-BASED SPECIALISTS --
    // ==========================================
    Recipe(
      id: '7b81c4e9-1234-4b99-90aa-33ff55881122',
      name: 'Oat Microfoam 58',
      description: 'Gentle temperature curve strictly capped at 58°C to prevent oat milk protein breakdown.',
      category: 'Non-Dairy',
      tags: const ['Non-Dairy', 'Hot Coffee'],
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
      category: 'Non-Dairy',
      tags: const ['Non-Dairy', 'Hot Coffee'],
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
      category: 'Non-Dairy',
      tags: const ['Non-Dairy', 'Hot Coffee'],
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
    Recipe(
      id: '8a3c4d12-bf91-4e78-90b5-12a84976cf33',
      name: 'Coconut Cold Whip',
      description: 'Tropical chilled foam using rich coconut milk and light vanilla froth.',
      category: 'Non-Dairy',
      tags: const ['Non-Dairy', 'Cold Foam & Textures', 'Iced & Cold Coffee'],
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
    Recipe(
      id: 'abcdef01-2345-6789-abcd-ef0123456789',
      name: 'Cashew Silk Foam',
      description: 'Creamy warm cashew milk microfoam with subtle nutty sweetness and luscious texture.',
      category: 'Non-Dairy',
      tags: const ['Non-Dairy', 'Hot Coffee'],
      phases: [
        Phase.clamped(speed: 2800, accel: 700, temp: 46, duration: 24),
        Phase.clamped(speed: 1200, accel: 450, temp: 60, duration: 18),
      ],
      ingredients: [
        '130 ml Unsweetened creamy cashew milk',
        '1 Nespresso Espresso shot',
        '1 tsp Agave or maple syrup (optional)',
      ],
      instructions: [
        'Pour cashew milk into the Barista jug.',
        'Run Cashew Silk Foam cycle.',
        'Brew espresso into a cup.',
        'Pour the silky, naturally buttery foam over espresso.',
      ],
    ),
    Recipe(
      id: 'bcdef012-3456-789a-bcde-f0123456789a',
      name: 'Pea Milk Cloud',
      description: 'High-protein barista pea milk whipped into an ultra-stable velvety microfoam crown.',
      category: 'Non-Dairy',
      tags: const ['Non-Dairy', 'Hot Coffee'],
      phases: [
        Phase.clamped(speed: 3100, accel: 800, temp: 48, duration: 25),
        Phase.clamped(speed: 1200, accel: 450, temp: 63, duration: 18),
      ],
      ingredients: [
        '130 ml Barista Pea Protein Milk (e.g. Sproud)',
        '1 Nespresso Espresso capsule',
      ],
      instructions: [
        'Pour cold pea protein milk into the jug.',
        'Run Pea Milk Cloud cycle.',
        'Brew espresso into cup.',
        'Pour the exceptionally glossy, stable microfoam over coffee.',
      ],
    ),

    // ==========================================
    // --- COLD FOAM & TEXTURES SPECIALISTS ---
    // ==========================================
    Recipe(
      id: '11223344-5566-7788-9900-aabbccddeeff',
      name: 'Matcha Cloud',
      description: 'Cold emerald sweet matcha froth floating atop iced milk or cold brew.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Non-Coffee', 'Non-Dairy'],
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
    Recipe(
      id: 'cdef0123-4567-89ab-cdef-0123456789ab',
      name: 'Butterfly Foam',
      description: 'Striking natural blue botanical herbal cold froth for color-changing iced drinks.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Non-Coffee', 'Non-Dairy'],
      phases: [
        Phase.clamped(speed: 3800, accel: 1300, temp: 0, duration: 35),
      ],
      ingredients: [
        '80 ml Chilled oat or coconut milk',
        '1/2 tsp Butterfly pea flower powder',
        '1 tsp Vanilla syrup',
        'Iced lemonade or tonic water in serving glass',
      ],
      instructions: [
        'Place milk, blue butterfly pea flower powder, and vanilla syrup in the jug.',
        'Run Butterfly Foam cycle with heater off.',
        'Fill glass with ice and lemonade or tonic water.',
        'Pour the royal-blue foam float on top. Watch it swirl and shift toward purple!',
      ],
    ),
    Recipe(
      id: 'def01234-5678-9abc-def0-123456789abc',
      name: 'Strawberry Foam',
      description: 'Chilled strawberry-infused sweet cream cold foam for iced coffees and teas.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Non-Coffee', 'Dairy'],
      phases: [
        Phase.clamped(speed: 3600, accel: 1200, temp: 0, duration: 32),
      ],
      ingredients: [
        '50 ml Heavy cream',
        '30 ml Whole milk',
        '1 tbsp Strawberry purée or syrup',
        'Iced matcha latte or cold brew in glass',
      ],
      instructions: [
        'Pour heavy cream, milk, and strawberry purée into the Barista jug.',
        'Run Strawberry Foam cycle.',
        'Prepare your iced beverage over ice.',
        'Crown with the pastel-pink, velvety strawberry cream foam.',
      ],
    ),
    Recipe(
      id: 'ef012345-6789-abcd-ef01-23456789abcd',
      name: 'Cold Whip Cream',
      description: 'Rapid unheated shearing turning fresh heavy cream into soft, pillowy dollops.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Dairy'],
      phases: [
        Phase.clamped(speed: 3900, accel: 1400, temp: 0, duration: 26),
      ],
      ingredients: [
        '80 ml Very cold double cream (minimum 36% fat)',
        '1 tsp Powdered icing sugar',
        'Few drops of vanilla extract',
      ],
      instructions: [
        'Pour chilled cream, sugar, and vanilla into the cold Barista jug.',
        'Run Cold Whip Cream cycle. Watch as high RPM shear creates thick whipped dollops in seconds.',
        'Spoon lavishly over hot chocolate, cold brews, or desserts.',
      ],
    ),
    Recipe(
      id: 'f0123456-789a-bcde-f012-3456789abcde',
      name: 'Dense Cold Crown',
      description: 'Ultra-compact microfoam made from chilled skimmed milk for floating over cold drinks.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Dairy'],
      phases: [
        Phase.clamped(speed: 4000, accel: 1500, temp: 0, duration: 42),
      ],
      ingredients: [
        '100 ml Ultra-cold skimmed milk (under 4°C)',
      ],
      instructions: [
        'Ensure the jug, whisk, and skimmed milk are all ice-cold.',
        'Pour milk into the jug and start Dense Cold Crown at max 4000 RPM.',
        'Spoon the ultra-stiff, pure white peaks over iced espresso or iced tea.',
      ],
    ),
    Recipe(
      id: 'a1b2c3d4-1111-4444-8888-000000000001',
      name: 'Nitro Milk Cascade',
      description: 'Guinness-style cascading microfoam created via high-RPM hydrodynamic shear without nitrogen cartridges.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Dairy'],
      phases: [
        Phase.clamped(speed: 4000, accel: 1800, temp: 0, duration: 28),
        Phase.clamped(speed: 1200, accel: 300, temp: 0, duration: 15),
      ],
      ingredients: [
        '100 ml Ice-cold whole milk',
        '1 Freshly extracted espresso shot',
        '3 Large ice cubes in a tall glass',
      ],
      instructions: [
        'Ensure the Barista jug and whisk are thoroughly chilled.',
        'Pour 100 ml cold whole milk into the jug.',
        'Run Nitro Milk Cascade. Shearing aeration creates tiny micro-bubbles.',
        'Pour over iced glass and watch the cascading surge and creamy head develop.',
      ],
    ),
    Recipe(
      id: 'a1b2c3d4-2222-4444-8888-000000000002',
      name: 'Nitro Oat Cloud',
      description: 'Dairy-free cascading microfoam specifically tuned for oat milk proteins and starches.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Non-Dairy'],
      phases: [
        Phase.clamped(speed: 3800, accel: 1600, temp: 0, duration: 30),
        Phase.clamped(speed: 1400, accel: 400, temp: 0, duration: 12),
      ],
      ingredients: [
        '100 ml Cold Barista edition oat milk',
        '1 tsp Pure maple syrup or agave',
        'Cold brew coffee or iced Americano',
      ],
      instructions: [
        'Add cold oat milk and maple syrup to the jug.',
        'Run Nitro Oat Cloud cycle.',
        'Pour gently over a glass of cold brew. The oat cloud will cascade and float smoothly.',
      ],
    ),
    Recipe(
      id: 'a1b2c3d4-3333-4444-8888-000000000003',
      name: 'Nitro Sweet Cream',
      description: 'Starbucks-inspired vanilla sweet cream cold foam with velvety cascading density.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Dairy'],
      phases: [
        Phase.clamped(speed: 3400, accel: 1200, temp: 0, duration: 22),
        Phase.clamped(speed: 900, accel: 300, temp: 0, duration: 10),
      ],
      ingredients: [
        '60 ml Heavy whipping cream (36% fat)',
        '40 ml Cold whole milk',
        '15 ml Vanilla syrup',
        'Glass of iced cold brew',
      ],
      instructions: [
        'Pour heavy cream, cold milk, and vanilla syrup into the jug.',
        'Run Nitro Sweet Cream. Low-to-high velocity blend creates thick, slow-cascading cream.',
        'Layer gently over cold brew with ice.',
      ],
    ),
    Recipe(
      id: 'a1b2c3d4-4444-4444-8888-000000000004',
      name: 'Nitro Coconut Silk',
      description: 'Tropical, luxurious vegan cold foam with glossy micro-bubbles and natural coconut sweetness.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Non-Dairy', 'Non-Coffee'],
      phases: [
        Phase.clamped(speed: 3600, accel: 1400, temp: 0, duration: 25),
        Phase.clamped(speed: 1100, accel: 350, temp: 0, duration: 12),
      ],
      ingredients: [
        '80 ml Chilled culinary coconut milk',
        '20 ml Chilled filtered water or coconut water',
        '1 tsp Simple syrup',
      ],
      instructions: [
        'Pour coconut milk, water, and syrup into the cold jug.',
        'Run Nitro Coconut Silk cycle.',
        'Pour over iced matcha or cold brew for an exotic layered beverage.',
      ],
    ),
    Recipe(
      id: 'a1b2c3d4-5555-4444-8888-000000000005',
      name: 'Nitro Almond Mist',
      description: 'Delicate, nutty, zero-heat cold foam formulated for light almond milk.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Non-Dairy'],
      phases: [
        Phase.clamped(speed: 3700, accel: 1500, temp: 0, duration: 26),
        Phase.clamped(speed: 1300, accel: 400, temp: 0, duration: 10),
      ],
      ingredients: [
        '100 ml Unsweetened barista almond milk',
        '1 tsp Agave nectar',
        'Dash of ground cinnamon',
      ],
      instructions: [
        'Add cold almond milk and agave to the jug.',
        'Run Nitro Almond Mist.',
        'Spoon the delicate, nutty foam over iced espresso or cold brew.',
      ],
    ),
    Recipe(
      id: 'a1b2c3d4-6666-4444-8888-000000000006',
      name: 'Viennese Chantilly',
      description: 'Bourbon vanilla whipped double cream for traditional Austrian Café Viennois.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Dairy'],
      phases: [
        Phase.clamped(speed: 2600, accel: 700, temp: 0, duration: 20),
        Phase.clamped(speed: 1100, accel: 300, temp: 0, duration: 12),
      ],
      ingredients: [
        '80 ml Chilled double cream',
        '10g Powdered confectioners sugar',
        '3 drops Pure Madagascar vanilla extract',
      ],
      instructions: [
        'Pour chilled cream, sugar, and vanilla into the jug.',
        'Run cycle. Precise rotation creates glossy, soft peaks without turning to butter.',
        'Spoon lavishly over hot espresso lungo and dust with cocoa.',
      ],
    ),
    Recipe(
      id: 'a1b2c3d4-7777-4444-8888-000000000007',
      name: 'Irish Velvet Cream',
      description: 'Warm whiskey-infused velvety textured cream crown for Irish Coffee lovers.',
      category: 'Hot Coffee',
      tags: const ['Hot Coffee', 'Dairy'],
      phases: [
        Phase.clamped(speed: 2200, accel: 500, temp: 45, duration: 20),
        Phase.clamped(speed: 800, accel: 200, temp: 58, duration: 15),
      ],
      ingredients: [
        '60 ml Single cream',
        '40 ml Whole milk',
        '15 ml Irish whiskey or Irish cream syrup',
        '1 Nespresso double espresso or lungo',
      ],
      instructions: [
        'Combine cream, milk, and whiskey/syrup in the jug.',
        'Run Irish Velvet Cream cycle for gentle warming and thick emulsion.',
        'Pour freshly extracted hot espresso into an Irish coffee glass with brown sugar.',
        'Float the warm velvet cream over the back of a warm spoon.',
      ],
    ),
    Recipe(
      id: 'a1b2c3d4-8888-4444-8888-000000000008',
      name: 'Whipped Espresso',
      description: 'Authentic Italian Crema di Caffè — thick, frosty, whipped coffee soft-serve foam.',
      category: 'Iced & Cold Coffee',
      tags: const ['Iced & Cold Coffee', 'Cold Foam & Textures'],
      phases: [
        Phase.clamped(speed: 3900, accel: 1600, temp: 0, duration: 35),
        Phase.clamped(speed: 1500, accel: 400, temp: 0, duration: 15),
      ],
      ingredients: [
        '40 ml Cold espresso (1 espresso shot cooled in fridge)',
        '15g Fine caster sugar',
        '2 Small ice cubes',
      ],
      instructions: [
        'Drop ice cubes, chilled espresso, and sugar into the Barista jug.',
        'Run Whipped Espresso cycle.',
        'The high-velocity shear turns the liquid coffee into a thick, mousse-like frozen cream.',
        'Spoon directly into glass cups and serve immediately.',
      ],
    ),
    Recipe(
      id: 'a1b2c3d4-9999-4444-8888-000000000009',
      name: 'Pistachio Velvet',
      description: 'Decadent sweet pistachio cream cold foam for dessert drinks and iced lattes.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Dairy', 'Non-Coffee'],
      phases: [
        Phase.clamped(speed: 3200, accel: 1000, temp: 0, duration: 24),
        Phase.clamped(speed: 1100, accel: 300, temp: 0, duration: 12),
      ],
      ingredients: [
        '70 ml Cold whole milk',
        '30 ml Heavy cream',
        '1 tbsp Sweet pistachio cream paste',
        'Crushed roasted pistachios for garnish',
      ],
      instructions: [
        'Add milk, cream, and pistachio paste into the jug.',
        'Run Pistachio Velvet cycle.',
        'Pour over iced espresso or cold milk and garnish with crushed pistachios.',
      ],
    ),
    Recipe(
      id: 'a1b2c3d4-aaaa-4444-8888-00000000000a',
      name: 'Golden Chai Foam',
      description: 'Anti-inflammatory turmeric, ginger, and cardamom spiced cold cloud atop iced tea or oat latte.',
      category: 'Cold Foam & Textures',
      tags: const ['Cold Foam & Textures', 'Non-Dairy', 'Non-Coffee'],
      phases: [
        Phase.clamped(speed: 3600, accel: 1200, temp: 0, duration: 26),
        Phase.clamped(speed: 1000, accel: 300, temp: 0, duration: 12),
      ],
      ingredients: [
        '100 ml Cold barista oat or almond milk',
        '1/4 tsp Ground turmeric',
        'Pinch of ground cinnamon, cardamom, and black pepper',
        '1 tsp Honey or maple syrup',
      ],
      instructions: [
        'Add plant milk, spices, and honey into the jug.',
        'Run Golden Chai Foam cycle.',
        'Spoon the vibrant golden foam over iced black tea, cold brew, or iced chai.',
      ],
    ),

    // =========================================================================
    // --- NATIVE MULTI-STEP RECIPES (FIRMWARE PAUSE & DUAL-STAGE EXECUTION) ---
    // =========================================================================
    Recipe(
      id: 'adae1c28-e9f0-4a0c-a52d-e842de813862',
      name: 'Latte Double',
      description: 'Signature dual-stage latte. Step 1 cold-whisks espresso for crema, pauses, then Step 2 froths hot microfoam.',
      category: 'Hot Coffee',
      tags: const ['Multi-Step', 'Hot Coffee', 'Dairy'],
      steps: [
        RecipeStep(
          name: 'STEP 1',
          instruction: 'Extract 1 espresso (40 ml) & 1 ice cube into jug. Press start to whip crema.',
          phases: [
            Phase.clamped(speed: 3000, accel: 800, temp: 0, duration: 15),
          ],
        ),
        RecipeStep(
          name: 'STEP 2',
          instruction: 'Machine pauses. Add 120 ml cold whole milk, then press machine center dial to resume.',
          phases: [
            Phase.clamped(speed: 2400, accel: 800, temp: 65, duration: 35),
          ],
        ),
      ],
      ingredients: [
        '1 Nespresso Espresso capsule (40 ml)',
        '1 Standard ice cube',
        '120 ml Fresh cold whole milk',
      ],
      instructions: [
        'Insert whisk. Brew 1 espresso shot directly into the Barista jug and add 1 ice cube.',
        'Close lid, select "Latte Double", and press the physical start button (Step 1 executes).',
        'When Step 1 completes, the machine automatically cuts motor/heat and enters PAUSE mode.',
        'Remove lid, add 120 ml cold milk into the jug, close lid, and press the center dial button.',
        'Step 2 finishes with velvety hot microfoam. Pour into a tall latte glass.',
      ],
    ),
    Recipe(
      id: 'aca70b89-a6f5-49fd-8aca-a683315e4d08',
      name: 'Nitro Swt Cream',
      description: 'Two-stage cold craft. Step 1 aerates coffee into a micro-bubbled nitro emulsion; Step 2 whips sweet cream.',
      category: 'Iced & Cold Coffee',
      tags: const ['Multi-Step', 'Iced & Cold Coffee', 'Cold Foam & Textures', 'Dairy'],
      steps: [
        RecipeStep(
          name: 'STEP 1',
          instruction: 'Add 60 ml cold brew concentrate & 10 ml vanilla syrup. Press start to nitro-whip.',
          phases: [
            Phase.clamped(speed: 3600, accel: 900, temp: 0, duration: 20),
            Phase.clamped(speed: 1800, accel: 600, temp: 0, duration: 10),
          ],
        ),
        RecipeStep(
          name: 'STEP 2',
          instruction: 'Machine pauses. Pour in 80 ml heavy cream & 20 ml milk. Press dial to froth float.',
          phases: [
            Phase.clamped(speed: 2800, accel: 750, temp: 0, duration: 22),
          ],
        ),
      ],
      ingredients: [
        '60 ml Cold brew concentrate',
        '10 ml Madagascar vanilla syrup',
        '80 ml Heavy whipping cream (chilled)',
        '20 ml Whole milk',
      ],
      instructions: [
        'Add cold brew and vanilla syrup into the jug. Run Step 1 for ultra-high speed nitro aeration.',
        'At the pause prompt, open lid and add 80 ml cold heavy cream and 20 ml milk.',
        'Press center dial button to trigger Step 2.',
        'Pour the nitro coffee into a glass filled with ice and spoon the thick sweet cream crown on top.',
      ],
    ),
    Recipe(
      id: '3cb172c5-3ed6-43bd-b6bc-b54c76a87390',
      name: 'Viennese Choco',
      description: 'Artisan hot chocolate. Step 1 gently melts pure chocolate flakes into milk; Step 2 whips Chantilly foam.',
      category: 'Non-Coffee',
      tags: const ['Multi-Step', 'Non-Coffee', 'Dairy'],
      steps: [
        RecipeStep(
          name: 'STEP 1',
          instruction: 'Add 25g dark chocolate flakes & 100 ml milk. Press start to melt & temper.',
          phases: [
            Phase.clamped(speed: 1200, accel: 500, temp: 65, duration: 35),
            Phase.clamped(speed: 2200, accel: 700, temp: 68, duration: 15),
          ],
        ),
        RecipeStep(
          name: 'STEP 2',
          instruction: 'Machine pauses. Add 50 ml heavy cream & pinch of cinnamon. Press dial to finish.',
          phases: [
            Phase.clamped(speed: 3200, accel: 850, temp: 60, duration: 25),
          ],
        ),
      ],
      ingredients: [
        '25g Valrhona 70% dark chocolate flakes or chips',
        '100 ml Fresh whole milk',
        '50 ml Heavy cream',
        'Pinch of ground Ceylon cinnamon',
      ],
      instructions: [
        'Insert whisk. Add chocolate flakes and 100 ml milk to the jug.',
        'Start recipe: Step 1 heats to 68°C while gently whisking to fully melt chocolate.',
        'At the pause icon, open jug and add 50 ml heavy cream and cinnamon.',
        'Press the machine center button to resume Step 2 for high-speed aeration.',
        'Serve in a porcelain mug with shaved chocolate curls.',
      ],
    ),
    Recipe(
      id: 'e3161968-5809-4e91-aa41-786248beb1e3',
      name: 'Affogato Foam',
      description: 'Deconstructed liquid affogato. Step 1 flash-chills espresso; Step 2 whips an ultra-dense gelato-like foam.',
      category: 'Iced & Cold Coffee',
      tags: const ['Multi-Step', 'Iced & Cold Coffee', 'Cold Foam & Textures', 'Dairy'],
      steps: [
        RecipeStep(
          name: 'STEP 1',
          instruction: 'Add 1 espresso shot & 2 ice cubes. Press start to flash-chill & emulsify.',
          phases: [
            Phase.clamped(speed: 2600, accel: 700, temp: 0, duration: 18),
          ],
        ),
        RecipeStep(
          name: 'STEP 2',
          instruction: 'Machine pauses. Add 70 ml chilled vanilla cream. Press dial to whip gelato foam.',
          phases: [
            Phase.clamped(speed: 3800, accel: 1000, temp: 0, duration: 28),
          ],
        ),
      ],
      ingredients: [
        '1 Nespresso Ristretto or Espresso shot (40 ml)',
        '2 Standard ice cubes',
        '50 ml Heavy whipping cream',
        '20 ml Whole milk with 1/2 tsp vanilla bean paste',
      ],
      instructions: [
        'Extract espresso into the jug with 2 ice cubes. Start Step 1 to rapidly chill and aerate.',
        'When the machine beeps and enters PAUSE, remove lid and add the vanilla cream mixture.',
        'Press the center dial to launch Step 2 (3800 RPM maximum cold foam whip).',
        'Pour dense foam over an espresso glass or dessert bowl.',
      ],
    ),
    Recipe(
      id: 'c4976aa7-f961-4774-9d97-dadc351b3cff',
      name: 'Matcha Cloud',
      description: 'Japanese ceremonial preparation. Step 1 whisks matcha clump-free at 55°C; Step 2 textures silky oat milk.',
      category: 'Non-Coffee',
      tags: const ['Multi-Step', 'Non-Coffee', 'Non-Dairy'],
      steps: [
        RecipeStep(
          name: 'STEP 1',
          instruction: 'Add 2g ceremonial matcha & 40 ml warm water. Press start to dissolve clump-free.',
          phases: [
            Phase.clamped(speed: 2800, accel: 800, temp: 55, duration: 22),
          ],
        ),
        RecipeStep(
          name: 'STEP 2',
          instruction: 'Machine pauses. Pour in 120 ml barista oat milk & 5 ml agave. Press dial to froth.',
          phases: [
            Phase.clamped(speed: 2200, accel: 700, temp: 58, duration: 32),
          ],
        ),
      ],
      ingredients: [
        '2g Ceremonial-grade Uji matcha powder (sifted)',
        '40 ml Filtered water',
        '120 ml Barista oat milk',
        '5 ml Agave nectar or maple syrup',
      ],
      instructions: [
        'Add sifted matcha powder and water to the jug. Run Step 1 (55°C whisking dissolves completely).',
        'When the machine pauses with prompt, pour in 120 ml cold barista oat milk and agave.',
        'Press the center dial to execute Step 2 at 58°C (optimal plant-milk microfoam temperature).',
        'Pour into a clear glass to reveal the luminous jade green foam texture.',
      ],
    ),
    Recipe(
      id: '5b01ac33-7554-4844-9627-8e271fa6d664',
      name: 'Caramel Macch',
      description: 'Layered café macchiato. Step 1 textures dense vanilla milk foam; Step 2 folds caramel drizzle gently.',
      category: 'Hot Coffee',
      tags: const ['Multi-Step', 'Hot Coffee', 'Dairy'],
      steps: [
        RecipeStep(
          name: 'STEP 1',
          instruction: 'Add 120 ml whole milk & 10 ml vanilla syrup. Press start for foam base.',
          phases: [
            Phase.clamped(speed: 3000, accel: 800, temp: 50, duration: 25),
            Phase.clamped(speed: 1200, accel: 500, temp: 65, duration: 15),
          ],
        ),
        RecipeStep(
          name: 'STEP 2',
          instruction: 'Machine pauses. Drizzle 15 ml caramel sauce around jug. Press dial to fold.',
          phases: [
            Phase.clamped(speed: 900, accel: 400, temp: 65, duration: 15),
          ],
        ),
      ],
      ingredients: [
        '120 ml Cold whole milk',
        '10 ml Vanilla syrup',
        '15 ml Salted caramel sauce',
        '1 Nespresso Espresso shot (40 ml)',
      ],
      instructions: [
        'Add milk and vanilla syrup to the Barista jug and run Step 1 for textured microfoam.',
        'At the pause prompt, open lid and drizzle thick caramel sauce directly into the milk.',
        'Press the dial button to trigger Step 2 (gentle low-RPM fold that distributes caramel without deflating foam).',
        'Pour into a glass, brew espresso shot through the center, and top with crosshatch caramel.',
      ],
    ),
    Recipe(
      id: '7f4df999-f519-4062-bee0-921551e31ed8',
      name: 'Cortado Extr',
      description: 'Thermal contrast Spanish cortado. Step 1 creates hot emulsified milk; Step 2 tempers with ice cream/cold cream.',
      category: 'Hot Coffee',
      tags: const ['Multi-Step', 'Hot Coffee', 'Dairy'],
      steps: [
        RecipeStep(
          name: 'STEP 1',
          instruction: 'Add 60 ml milk & 1 brown sugar cube. Press start for hot caramelization.',
          phases: [
            Phase.clamped(speed: 3400, accel: 900, temp: 68, duration: 20),
          ],
        ),
        RecipeStep(
          name: 'STEP 2',
          instruction: 'Machine pauses. Add 20 ml ice-cold single cream. Press dial to temper.',
          phases: [
            Phase.clamped(speed: 1000, accel: 400, temp: 0, duration: 15),
          ],
        ),
      ],
      ingredients: [
        '60 ml Cold whole milk',
        '1 Brown demerara sugar cube',
        '20 ml Ice-cold single cream',
        '1 Nespresso Ristretto capsule (25 ml)',
      ],
      instructions: [
        'Place milk and brown sugar in the jug. Step 1 dissolves sugar and produces piping hot foam at 68°C.',
        'Upon pause, immediately pour 20 ml ice-cold cream into the jug.',
        'Press center dial: Step 2 tempers the emulsion at 1000 RPM with heater off.',
        'Pour equal parts espresso and silky tempered foam into a 130 ml Gibraltar glass.',
      ],
    ),
    Recipe(
      id: 'cacebbeb-6c6b-4cd7-ac12-e92110ce56b7',
      name: 'Golden Turmeric',
      description: 'Ayurvedic wellness ritual. Step 1 blooms active spices in water; Step 2 froths rich almond milk foam.',
      category: 'Non-Coffee',
      tags: const ['Multi-Step', 'Non-Coffee', 'Non-Dairy'],
      steps: [
        RecipeStep(
          name: 'STEP 1',
          instruction: 'Add 1 tsp turmeric spice blend & 50 ml water. Press start to bloom aromatics.',
          phases: [
            Phase.clamped(speed: 1600, accel: 600, temp: 65, duration: 30),
          ],
        ),
        RecipeStep(
          name: 'STEP 2',
          instruction: 'Machine pauses. Add 120 ml almond milk & honey. Press dial to whip golden foam.',
          phases: [
            Phase.clamped(speed: 3100, accel: 800, temp: 56, duration: 25),
          ],
        ),
      ],
      ingredients: [
        '1 tsp Organic ground turmeric & ginger blend',
        'Pinch of cracked black pepper (boosts curcumin absorption)',
        '50 ml Water',
        '120 ml Unsweetened almond milk',
        '1 tsp Wildflower honey',
      ],
      instructions: [
        'Add spice blend, black pepper, and water into the jug. Step 1 heats to 65°C to bloom active oils.',
        'At the pause prompt, add 120 ml cold almond milk and honey.',
        'Press machine dial: Step 2 whisks at 3100 RPM to craft an aromatic golden microfoam crown.',
        'Pour into a mug and dust with fresh nutmeg.',
      ],
    ),
    Recipe(
      id: '5ef2eaef-0118-4673-9c45-ef22fce8660d',
      name: 'Tiramisu Coffee',
      description: 'Decadent dessert coffee. Step 1 blends cold espresso and cocoa; Step 2 whips cold mascarpone foam.',
      category: 'Iced & Cold Coffee',
      tags: const ['Multi-Step', 'Iced & Cold Coffee', 'Cold Foam & Textures', 'Dairy'],
      steps: [
        RecipeStep(
          name: 'STEP 1',
          instruction: 'Add 40 ml espresso, 1 tsp cocoa & 1 ice cube. Press start to blend base.',
          phases: [
            Phase.clamped(speed: 2400, accel: 700, temp: 0, duration: 18),
          ],
        ),
        RecipeStep(
          name: 'STEP 2',
          instruction: 'Machine pauses. Add 60 ml cream & 1 tbsp mascarpone. Press dial for thick foam.',
          phases: [
            Phase.clamped(speed: 3600, accel: 950, temp: 0, duration: 25),
          ],
        ),
      ],
      ingredients: [
        '1 Nespresso Espresso shot (40 ml)',
        '1 tsp Dutch-processed cocoa powder',
        '1 Ice cube',
        '60 ml Heavy whipping cream (chilled)',
        '1 heaping tbsp Italian Mascarpone cheese',
        '1 tsp Powdered sugar & drops of vanilla',
      ],
      instructions: [
        'Add espresso, cocoa powder, and ice cube to the jug. Run Step 1 for cold coffee liquefaction.',
        'When the machine enters pause mode, add heavy cream, mascarpone, powdered sugar, and vanilla.',
        'Press center dial: Step 2 whips the mascarpone cream into a velvety spoonable cloud.',
        'Layer over savoiardi ladyfinger biscuit or cold milk.',
      ],
    ),
    Recipe(
      id: '70581e69-261a-42a1-bfe7-468a7e4dd729',
      name: 'London Fog',
      description: 'Fragrant tea latte. Step 1 extracts bergamot & lavender; Step 2 aerates hot vanilla microfoam.',
      category: 'Non-Coffee',
      tags: const ['Multi-Step', 'Non-Coffee', 'Dairy'],
      steps: [
        RecipeStep(
          name: 'STEP 1',
          instruction: 'Add 40 ml strong brewed Earl Grey & 1 tsp lavender syrup. Press start to heat.',
          phases: [
            Phase.clamped(speed: 1400, accel: 500, temp: 70, duration: 30),
          ],
        ),
        RecipeStep(
          name: 'STEP 2',
          instruction: 'Machine pauses. Add 100 ml cold whole milk & vanilla extract. Press dial to finish.',
          phases: [
            Phase.clamped(speed: 3200, accel: 800, temp: 64, duration: 22),
          ],
        ),
      ],
      ingredients: [
        '40 ml Concentrated hot brewed Earl Grey tea',
        '5 ml Culinary lavender syrup',
        '100 ml Fresh whole milk',
        '2 drops Pure vanilla extract',
      ],
      instructions: [
        'Pour hot concentrated Earl Grey and lavender syrup into jug. Run Step 1 to infuse at 70°C.',
        'At the pause prompt, open lid and add 100 ml cold whole milk and vanilla extract.',
        'Press the dial button: Step 2 whips a tight, fragrant microfoam crown at 64°C.',
        'Garnish with dried edible lavender buds.',
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
