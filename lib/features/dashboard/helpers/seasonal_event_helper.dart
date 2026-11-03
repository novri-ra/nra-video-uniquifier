/// Model containing seasonal microstock commercial campaign details.
class SeasonalCampaignInfo {
  final String quarterLabel;
  final String title;
  final String campaignDescription;
  final List<String> primaryTags;
  final List<TrendTopic> upcomingTrends;

  const SeasonalCampaignInfo({
    required this.quarterLabel,
    required this.title,
    required this.campaignDescription,
    required this.primaryTags,
    required this.upcomingTrends,
  });
}

/// Trend topic model with category, title, description, and interactive chips.
class TrendTopic {
  final String category;
  final String title;
  final String description;
  final List<String> chips;

  const TrendTopic({
    required this.category,
    required this.title,
    required this.description,
    required this.chips,
  });
}

/// Helper calculating 60-90 days commercial lead-time seasonal windows and tags.
class SeasonalEventHelper {
  /// Target calculation: today + 75 days lead time.
  static SeasonalCampaignInfo getSeasonalWindowInfo([DateTime? referenceDate]) {
    final now = referenceDate ?? DateTime.now();
    final targetDate = now.add(const Duration(days: 75));
    final month = targetDate.month;

    if (month >= 1 && month <= 3) {
      return _buildQ1Campaign(targetDate);
    } else if (month >= 4 && month <= 6) {
      return _buildQ2Campaign(targetDate);
    } else if (month >= 7 && month <= 9) {
      return _buildQ3Campaign(targetDate);
    } else {
      return _buildQ4Campaign(targetDate);
    }
  }

  static SeasonalCampaignInfo _buildQ1Campaign(DateTime target) {
    return const SeasonalCampaignInfo(
      quarterLabel: 'Q1',
      title: 'Q1 Global Commercials & Celebrations',
      campaignDescription:
          "Valentine's Day • Ramadan & Eid al-Fitr • Lunar New Year",
      primaryTags: [
        '#Valentines',
        '#Ramadan2026',
        '#EidMubarak',
        '#LunarNewYear',
        '#LoveStory',
      ],
      upcomingTrends: [
        TrendTopic(
          category: 'HOLIDAYS',
          title: 'Ramadan & Eid Celebrations',
          description: 'Lanterns, calligraphy, family gatherings in 4K 60FPS',
          chips: ['#Lantern', '#Mandala', '#EidMubarak', '#Calligraphy'],
        ),
        TrendTopic(
          category: 'ROMANCE',
          title: "Valentine's & Modern Romance",
          description:
              'Couple portraits, aesthetic date spots, gifts in clean lighting',
          chips: ['#Romance', '#ValentinesDay', '#GiftBox', '#AestheticLove'],
        ),
        TrendTopic(
          category: 'CULTURAL',
          title: 'Lunar New Year & Traditions',
          description:
              'Red lanterns, dragon dances, festive dinners, fireworks',
          chips: [
            '#LunarNewYear',
            '#RedEnvelope',
            '#DragonDance',
            '#Tradition',
          ],
        ),
        TrendTopic(
          category: 'TECH',
          title: 'AI & Autonomous Robotics',
          description:
              'Humanoid robots, neural data streams, clean lab lighting',
          chips: ['#Cybernetic', '#NeuralNetwork', '#Robotics', '#AIWorkflow'],
        ),
      ],
    );
  }

  static SeasonalCampaignInfo _buildQ2Campaign(DateTime target) {
    return const SeasonalCampaignInfo(
      quarterLabel: 'Q2',
      title: 'Q2 Spring Renewal & Mid-Year Commercials',
      campaignDescription:
          'Earth Day • Mother\'s & Father\'s Day • Summer Kickoff',
      primaryTags: [
        '#EarthDay',
        '#MothersDay',
        '#SummerKickoff',
        '#OutdoorVibes',
        '#EcoTech',
      ],
      upcomingTrends: [
        TrendTopic(
          category: 'SUSTAINABILITY',
          title: 'Clean Energy & Green Tech',
          description:
              'Solar farms, wind turbines, eco agriculture time-lapses',
          chips: ['#SolarPower', '#GreenLiving', '#EcoTech', '#ZeroCarbon'],
        ),
        TrendTopic(
          category: 'FAMILY',
          title: "Mother's & Father's Celebrations",
          description:
              'Multigenerational lifestyle clips and emotional candid smiles',
          chips: ['#FamilyLove', '#MothersDay', '#FathersDay', '#Parenting'],
        ),
        TrendTopic(
          category: 'OUTDOOR',
          title: 'Summer Getaways & Exploration',
          description:
              'Beach landscapes, turquoise waters, van-life camping scenes',
          chips: ['#SummerTravel', '#BeachLife', '#Drone4K', '#RoadTrip'],
        ),
        TrendTopic(
          category: 'HEALTH',
          title: 'Wellness & Mindfulness',
          description:
              'Morning meditation, running trails, clean organic food prep',
          chips: ['#Mindfulness', '#HealthyEating', '#YogaFlow', '#CleanVibes'],
        ),
      ],
    );
  }

  static SeasonalCampaignInfo _buildQ3Campaign(DateTime target) {
    return const SeasonalCampaignInfo(
      quarterLabel: 'Q3',
      title: 'Q3 Back to School & Autumn Horizons',
      campaignDescription: 'Back to School • Autumn Harvest • Tech Keynotes',
      primaryTags: [
        '#BackToSchool',
        '#AutumnLeaves',
        '#HarvestVibes',
        '#CozyFashion',
        '#CampusLife',
      ],
      upcomingTrends: [
        TrendTopic(
          category: 'EDUCATION',
          title: 'Back to Campus & E-Learning',
          description:
              'Classrooms, digital stylus note-taking, student study hubs',
          chips: ['#CampusLife', '#StudyWithMe', '#BackToSchool', '#EdTech'],
        ),
        TrendTopic(
          category: 'AUTUMN',
          title: 'Golden Hour & Fall Textures',
          description:
              'Warm foliage, pumpkin spice, cozy knitwear, forest paths',
          chips: ['#AutumnVibes', '#GoldenHour', '#CozyAesthetic', '#Foliage'],
        ),
        TrendTopic(
          category: 'COMMERCIAL',
          title: 'Enterprise Innovation & Cloud',
          description:
              'Modern office suites, high-speed fiber data visualization',
          chips: ['#Fintech', '#CloudSecurity', '#BigData', '#GlobalBusiness'],
        ),
        TrendTopic(
          category: 'FITNESS',
          title: 'Marathon & Indoor Training',
          description:
              'Athletic wear, track sprints, high-intensity functional gym',
          chips: ['#CardioFit', '#MarathonPrep', '#GymWorkout', '#Athletic'],
        ),
      ],
    );
  }

  static SeasonalCampaignInfo _buildQ4Campaign(DateTime target) {
    return const SeasonalCampaignInfo(
      quarterLabel: 'Q4',
      title: 'Q4 Mega Shopping & Holiday Seasons',
      campaignDescription:
          'Black Friday • Cyber Monday • Christmas & Year-End Countdown',
      primaryTags: [
        '#BlackFriday',
        '#Christmas2026',
        '#NewYearsEve',
        '#HolidaySale',
        '#WinterMagic',
      ],
      upcomingTrends: [
        TrendTopic(
          category: 'ECOMMERCE',
          title: 'Black Friday & Cyber Shopping',
          description:
              'Smartphone shopping carts, unboxing packages, neon sales',
          chips: [
            '#SalePromo',
            '#BlackFriday',
            '#CyberMonday',
            '#CartCheckout',
          ],
        ),
        TrendTopic(
          category: 'HOLIDAYS',
          title: 'Christmas & Winter Wonderland',
          description:
              'Decorated pines, snow falling, fireplace glow, gift wrapping',
          chips: [
            '#ChristmasMagic',
            '#WinterSnow',
            '#GiftWrapping',
            '#HolidayJoy',
          ],
        ),
        TrendTopic(
          category: 'CELEBRATION',
          title: "New Year's Eve Celebrations",
          description:
              'Champagne toast, confetti drops, rooftop skyline countdowns',
          chips: [
            '#Countdown2027',
            '#ChampagneToast',
            '#Fireworks',
            '#Celebration',
          ],
        ),
        TrendTopic(
          category: 'COMMERCIAL',
          title: 'Annual Review & Goal Setting',
          description:
              'Year-end financial analysis, team retrospectives, targets',
          chips: [
            '#AnnualReview',
            '#BusinessGoals',
            '#Strategy2027',
            '#Success',
          ],
        ),
      ],
    );
  }
}
