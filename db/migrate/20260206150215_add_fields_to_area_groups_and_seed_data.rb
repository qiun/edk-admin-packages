class AddFieldsToAreaGroupsAndSeedData < ActiveRecord::Migration[8.1]
  AREA_GROUPS_DATA = [
    { name: "dolnośląskie 1", description: "dolnośląskie - Michał Kliszczak", leader_email: "michalkli@icloud.com", voivodeship: "dolnośląskie" },
    { name: "dolnośląskie 2", description: "dolnośląskie - Jerzy Guziak", leader_email: "j.guziak@int.pl", voivodeship: "dolnośląskie" },
    { name: "dolnośląskie 3", description: "dolnośląskie -", leader_email: nil, voivodeship: "dolnośląskie" },
    { name: "dolnośląskie 4", description: "dolnośląskie - Marcelina Chilińska", leader_email: "marcelinach@gazeta.pl", voivodeship: "dolnośląskie" },
    { name: "dolnośląskie 5", description: "dolnośląskie - Piotr Białokryty", leader_email: "pbialokryty@wp.pl", voivodeship: "dolnośląskie" },
    { name: "dolnośląskie 6", description: "dolnośląskie - Anna Jarosławska", leader_email: "jaroslawska77@gmail.com", voivodeship: "dolnośląskie" },
    { name: "kujawsko-pomorskie 1", description: "kujawsko-pomorskie - Artur Lorczak", leader_email: "alorczak@wp.pl", voivodeship: "kujawsko-pomorskie" },
    { name: "kujawsko-pomorskie 2", description: "kujawsko-pomorskie - Arkadiusz Kamiński", leader_email: "ar.kaminski@onet.pl", voivodeship: "kujawsko-pomorskie" },
    { name: "kujawsko-pomorskie 3", description: "kujawsko-pomorskie - Artur Racinowski", leader_email: "artur@racinowski.pl", voivodeship: "kujawsko-pomorskie" },
    { name: "lubelskie 1", description: "lubelskie - Rafał Lipert", leader_email: "rlipert@wp.pl", voivodeship: "lubelskie" },
    { name: "lubelskie 2", description: "lubelskie - Sławomir Denisiuk", leader_email: "denisiukslawek@gmail.com", voivodeship: "lubelskie" },
    { name: "lubelskie 3", description: "lubelskie - Beata Zydlewska", leader_email: "beata.ubi@wp.pl", voivodeship: "lubelskie" },
    { name: "lubelskie 4", description: "lubelskie - Paweł Gawda", leader_email: "palo.gawda@gmail.com", voivodeship: "lubelskie" },
    { name: "lubelskie 5", description: "lubelskie - Joanna Wójtowicz Mróz", leader_email: "joankamroz@gmail.com", voivodeship: "lubelskie" },
    { name: "lubuskie 1", description: "lubuskie - Ryszard Staniszewski", leader_email: "rstaniszewski@wp.pl", voivodeship: "lubuskie" },
    { name: "lubuskie 2", description: "lubuskie - Tomasz Sucholas", leader_email: "tsucholas@wp.pl", voivodeship: "lubuskie" },
    { name: "łódzkie 1", description: "łódzkie - Michał Bak", leader_email: "geodeta_mb@interia.pl", voivodeship: "łódzkie" },
    { name: "łódzkie 2", description: "łódzkie - Piotr Bibik", leader_email: "pbibik@gmail.com", voivodeship: "łódzkie" },
    { name: "łódzkie 3", description: "łódzkie - Marek Kijewski", leader_email: "mkijewski1805@gmail.com", voivodeship: "łódzkie" },
    { name: "małopolskie 1", description: "małopolskie - Robert Sztaba", leader_email: "robert.sztaba@me.com", voivodeship: "małopolskie" },
    { name: "małopolskie 2", description: "małopolskie - Grzegorz Leleń", leader_email: "lelen@op.pl", voivodeship: "małopolskie" },
    { name: "małopolskie 3", description: "małopolskie - Sylwia Tokarczyk", leader_email: "sylwiaturek1711@gmail.com", voivodeship: "małopolskie" },
    { name: "małopolskie 4", description: "małopolskie - Urszula Franczak", leader_email: "ursula.franczak@gmail.com", voivodeship: "małopolskie" },
    { name: "małopolskie 5", description: "małopolskie - Bogdan Stawowy", leader_email: "bogdanstawowy@onet.eu", voivodeship: "małopolskie" },
    { name: "małopolskie 6", description: "małopolskie - Mateusz Kołodziej", leader_email: "mateuszkolodziejlight@gmail.com", voivodeship: "małopolskie" },
    { name: "małopolskie 7", description: "małopolskie -", leader_email: nil, voivodeship: "małopolskie" },
    { name: "małopolskie 8", description: "małopolskie -", leader_email: nil, voivodeship: "małopolskie" },
    { name: "małopolskie 9", description: "małopolskie - Gabriel Stachura", leader_email: "garson@o2.pl", voivodeship: "małopolskie" },
    { name: "mazowieckie 1", description: "mazowieckie - Hubert Osiński", leader_email: "hubert@osinski.at", voivodeship: "mazowieckie" },
    { name: "mazowieckie 2", description: "mazowieckie - Agnieszka Kazanecka", leader_email: "agkazanecka@o2.pl", voivodeship: "mazowieckie" },
    { name: "mazowieckie 3", description: "mazowieckie - Przemysław Chądzyński", leader_email: "przemek.chadzynski@gmail.com", voivodeship: "mazowieckie" },
    { name: "mazowieckie 4", description: "mazowieckie - Ewa Micyk", leader_email: "ewa.micyk@gmail.com", voivodeship: "mazowieckie" },
    { name: "mazowieckie 5", description: "mazowieckie - Dominik Manowski", leader_email: "manowski.dominik@gmail.com", voivodeship: "mazowieckie" },
    { name: "mazowieckie 6", description: "mazowieckie -", leader_email: nil, voivodeship: "mazowieckie" },
    { name: "mazowieckie 7", description: "mazowieckie -", leader_email: nil, voivodeship: "mazowieckie" },
    { name: "mazowieckie 8", description: "mazowieckie - Sławek Gomoliszek", leader_email: "sgomos.edk@gmail.com", voivodeship: "mazowieckie" },
    { name: "mazowieckie 9", description: "mazowieckie -", leader_email: nil, voivodeship: "mazowieckie" },
    { name: "mazowieckie 10", description: "mazowieckie - Marcin Pasik", leader_email: "m_pasik@interia.pl", voivodeship: "mazowieckie" },
    { name: "mazowieckie 11", description: "mazowieckie - Paweł Kaczmarczyk", leader_email: "pizzerialatino1@gmail.com", voivodeship: "mazowieckie" },
    { name: "opolskie 1", description: "opolskie - Jacek Dzierżanowski", leader_email: "dzierzanowski.jacek@wp.pl", voivodeship: "opolskie" },
    { name: "opolskie 2", description: "opolskie - Magdalena Skrobisz", leader_email: "skrobisz32@gmail.com", voivodeship: "opolskie" },
    { name: "podkarpackie 1", description: "podkarpackie - Marek Młynarczyk", leader_email: "nalczyk@interia.pl", voivodeship: "podkarpackie" },
    { name: "podkarpackie 2", description: "podkarpackie -", leader_email: nil, voivodeship: "podkarpackie" },
    { name: "podkarpackie 3", description: "podkarpackie - Jacek Furman", leader_email: "jacko941@wp.pl", voivodeship: "podkarpackie" },
    { name: "podkarpackie 4", description: "podkarpackie - Krzysztof Preisner", leader_email: "preisnerkrzysztof@wp.pl", voivodeship: "podkarpackie" },
    { name: "podkarpackie 5", description: "podkarpackie - Łukasz Mróz", leader_email: "lukasz.mroz@zhr.pl", voivodeship: "podkarpackie" },
    { name: "podkarpackie 6", description: "podkarpackie - Magdalena Ziomek", leader_email: "magzioster@gmail.com", voivodeship: "podkarpackie" },
    { name: "podkarpackie 7", description: "podkarpackie - Kazimierz Grządziel", leader_email: "grzadziel@autograf.pl", voivodeship: "podkarpackie" },
    { name: "podlaskie 1", description: "podlaskie - Katarzyna Gleba", leader_email: "katgle500298@onet.pl", voivodeship: "podlaskie" },
    { name: "podlaskie 2", description: "podlaskie - Wojciech Kozłowski", leader_email: "wkozlowski75@gmail.com", voivodeship: "podlaskie" },
    { name: "podlaskie 3", description: "podlaskie - Krzysztof Łukaszewicz", leader_email: "krzysztoflukaszewicz@wp.pl", voivodeship: "podlaskie" },
    { name: "podlaskie 4", description: "podlaskie - Jarosław Przesław", leader_email: "jprzeslaw@vp.pl", voivodeship: "podlaskie" },
    { name: "pomorskie 1", description: "pomorskie -", leader_email: "asiastopa7@wp.pl", voivodeship: "pomorskie" },
    { name: "pomorskie 2", description: "pomorskie - Rafał Wasielewski", leader_email: "rafalnastatku@gmail.com", voivodeship: "pomorskie" },
    { name: "pomorskie 3", description: "pomorskie - Jarek Krefta", leader_email: "kreftajarek@gmail.com", voivodeship: "pomorskie" },
    { name: "śląskie 1", description: "śląskie - Kamil Baczyński - Grodziec", leader_email: "baczynskikam@gmail.com", voivodeship: "śląskie" },
    { name: "śląskie 2", description: "śląskie - Bartosz Smołka - Żory", leader_email: "bart.smolka@gmail.com", voivodeship: "śląskie" },
    { name: "śląskie 3", description: "śląskie - Jarosław Życiński - Gliwice", leader_email: "kwarek@gmail.com", voivodeship: "śląskie" },
    { name: "śląskie 4", description: "śląskie - Grzegorz Dukata - Chudów", leader_email: "grzegorz.dukata@indywidualnosci.pl", voivodeship: "śląskie" },
    { name: "śląskie 5", description: "śląskie -", leader_email: nil, voivodeship: "śląskie" },
    { name: "śląskie 6", description: "śląskie - Michał Ślusarek - Tarnowskie Góry", leader_email: "slusarekm@gmail.com", voivodeship: "śląskie" },
    { name: "śląskie 7", description: "śląskie - Roma Petrymusz - Bytom", leader_email: "romapetrymusz@gmail.com", voivodeship: "śląskie" },
    { name: "śląskie 8", description: "śląskie - Adam Badura - Czerwionka", leader_email: "adambadur@gmail.com", voivodeship: "śląskie" },
    { name: "śląskie 9", description: "śląskie - Grzegorz Leśniewski - Gidle", leader_email: "grzesiek.gelu.lesniewski@gmail.com", voivodeship: "śląskie" },
    { name: "śląskie 10", description: "śląskie - Katarzyna Grabowska-Jonderko", leader_email: "katarzynagj73@gmail.com", voivodeship: "śląskie" },
    { name: "śląskie 11", description: "śląskie - Dariusz Filipek", leader_email: "darek_bercik@interia.pl", voivodeship: "śląskie" },
    { name: "świętokrzyskie 1", description: "świętokrzyskie - Łukasz Skórski", leader_email: "skora@poczta.fm", voivodeship: "świętokrzyskie" },
    { name: "świętokrzyskie 2", description: "świętokrzyskie - Łukasz Hamera", leader_email: "hamerki@o2.pl", voivodeship: "świętokrzyskie" },
    { name: "świętokrzyskie 3", description: "świętokrzyskie -", leader_email: nil, voivodeship: "świętokrzyskie" },
    { name: "warmińsko-mazurskie 1", description: "warmińsko-mazurskie - Krzysztof Sieczkowski", leader_email: "krzysztofff29@gmail.com", voivodeship: "warmińsko-mazurskie" },
    { name: "warmińsko-mazurskie 2", description: "warmińsko-mazurskie -", leader_email: nil, voivodeship: "warmińsko-mazurskie" },
    { name: "wielkopolskie 1", description: "wielkopolskie - Zbigniew Żołądek", leader_email: nil, voivodeship: "wielkopolskie" },
    { name: "wielkopolskie 2", description: "wielkopolskie - Tomasz Tomczak", leader_email: "tmjt23@gmail.com", voivodeship: "wielkopolskie" },
    { name: "wielkopolskie 3", description: "wielkopolskie - Joanna Kujawa", leader_email: "asia.ak6@gmail.com", voivodeship: "wielkopolskie" },
    { name: "wielkopolskie 4", description: "wielkopolskie - Adam Bartczak", leader_email: "adam_bartczak@poczta.onet.pl", voivodeship: "wielkopolskie" },
    { name: "wielkopolskie 5", description: "wielkopolskie - Mirosław Zakręt", leader_email: "mirzak5@op.pl", voivodeship: "wielkopolskie" },
    { name: "wielkopolskie 6", description: "wielkopolskie - Andrzej Gabryś", leader_email: "andrzej@meblomark.eu", voivodeship: "wielkopolskie" },
    { name: "zachodniopomorskie 1", description: "zachodniopomorskie - Marcin Sadowski", leader_email: nil, voivodeship: "zachodniopomorskie" },
    { name: "zachodniopomorskie 2", description: "zachodniopomorskie - Andrzej Milart", leader_email: "milart@post.pl", voivodeship: "zachodniopomorskie" },
    { name: "zachodniopomorskie 3", description: "zachodniopomorskie - Arkadiusz Nowak", leader_email: nil, voivodeship: "zachodniopomorskie" },
  ].freeze

  def up
    add_column :area_groups, :description, :string
    add_reference :area_groups, :voivodeship, foreign_key: true, null: true

    edition = Edition.find_by(is_active: true) || Edition.order(created_at: :desc).first
    return unless edition

    voivodeships = Voivodeship.all.index_by(&:name)

    AREA_GROUPS_DATA.each do |ag_data|
      next if AreaGroup.exists?(name: ag_data[:name], edition_id: edition.id)

      leader = ag_data[:leader_email] ? User.find_by(email: ag_data[:leader_email]) : nil
      voivodeship = ag_data[:voivodeship] ? voivodeships[ag_data[:voivodeship]] : nil

      AreaGroup.create!(
        name: ag_data[:name],
        description: ag_data[:description],
        edition: edition,
        leader: leader,
        voivodeship: voivodeship
      )
    end
  end

  def down
    edition = Edition.find_by(is_active: true) || Edition.order(created_at: :desc).first
    if edition
      names = AREA_GROUPS_DATA.map { |ag| ag[:name] }
      AreaGroup.where(name: names, edition_id: edition.id)
               .left_joins(:regions).where(regions: { id: nil })
               .destroy_all
    end

    remove_reference :area_groups, :voivodeship
    remove_column :area_groups, :description
  end
end
