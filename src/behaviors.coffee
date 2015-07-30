moment = require 'moment'

module.exports = (robot) =>

  robot.hear /costco/g, (msg) ->
    msg.send "http://imgur.com/nMMLv8n"

  priceThreshold = 7
  robot.respond /feed me( (sf|eastbay)?)?$/i, (msg) ->
    location = if msg.match[1] then msg.match[1].trim() else 'eastbay'
    now = moment().format('HH:MM')

    # https://api.spoonrocket.com/userapi/zones
    zones = {
        sf: {
          id: 2,
          name: "San Francisco"
        },
        eastbay: {
          id: 8,
          name: "East Bay"
        }
    }

    zone = zones[location]

    msg.http('https://api.spoonrocket.com/userapi/menu?zone_id=' + zone.id)
      .get() (err, res, body) ->
        return msg.send "Sorry, SpoonRocket doesn't like you. ERROR:#{err}" if err
        return msg.send "Unable to get today's menu: #{res.statusCode + ':\n' + body}" if res.statusCode != 200

        resp = JSON.parse(body)

        return msg.send "Sorry, SpoonRocket in " + zone.name + " is currently inactive." if !resp.active

        if now >= resp.closing_time && resp.closing_time != '00:00'
          return msg.send "Sorry, SpoonRocket is currently closed in " + zone.name + "."

        emit = 'Today\'s SpoonRocket menu is:' + "\n\n";

        entries = {}

        for entry in resp.menu when entry.type != 'dessert' && entry.type != 'beverage'
          entries[entry.id] =
            name: entry.name
            properties: entry.properties
            description: entry.description
            image: entry.image.original

        messages = []
        for id, entry of entries
          messages.push "#{entry.name} - #{entry.properties}\n#{entry.description}\n#{entry.image.original}\n"
        for message in messages
         msg.send message

