class GoobiUtil
    
  # from https://github.com/programmfabrik/coffeescript-ui/blob/fde25089327791d9aca540567bfa511e64958611/src/base/util.coffee#L506
  # has to be reused here, because cui not be used in updater
  @isEqual: (x, y, debug) ->
    #// if both are function
    if x instanceof Function
      if y instanceof Function
        return x.toString() == y.toString()
      return false

    if x == null or x == undefined or y == null or y == undefined
      return x == y

    if x == y or x.valueOf() == y.valueOf()
      return true

    # if one of them is date, they must had equal valueOf
    if x instanceof Date
      return false

    if y instanceof Date
      return false

    # if they are not function or strictly equal, they both need to be Objects
    if not (x instanceof Object)
      return false

    if not (y instanceof Object)
      return false

    p = Object.keys(x)
    if Object.keys(y).every( (i) -> return p.indexOf(i) != -1 )
      return p.every((i) =>
        eq = @isEqual(x[i], y[i], debug)
        if not eq
          if debug
            console.debug("X: ",x)
            console.debug("Differs to Y:", y)
            console.debug("Key differs: ", i)
            console.debug("Value X:", x[i])
            console.debug("Value Y:", y[i])
          return false
        else
          return true
      )
    else
      return false
    
  @getStandardFromGoobiJSON: (context, object, cdata, databaseLanguages = false) ->
    if databaseLanguages == false
      databaseLanguages = ez5.loca.getDatabaseLanguages()

    _standard = 
      text:  object.conceptName
      l10ntext: {}
    
    l10nObject = {}

    # init l10nObject for fulltext
    for language in databaseLanguages
      l10nObject[language] = ''

    # 1. L10N
    #  give l10n-languages the easydb-language-syntax
    for l10nObjectKey, l10nObjectValue of l10nObject
      # add to l10n
      l10nObject[l10nObjectKey] = object.conceptName

    _standard.l10ntext = l10nObject

    return _standard


  @getFullTextFromGoobiJSON: (object, databaseLanguages = false) ->
    if databaseLanguages == false
      databaseLanguages = ez5.loca.getDatabaseLanguages()

    if Array.isArray(object)
      object = object[0]

    _fulltext = 
      text: ''
      l10ntext: {}
    
    fullTextString = ''
    l10nObject = {}
    l10nObjectWithShortenedLanguages = {}

    # init l10nObject for fulltext
    for language in databaseLanguages
      l10nObject[language] = ''
    # preflabel to all languages
    fullTextString += object.conceptName

    for l10nObjectKey, l10nObjectValue of l10nObject
      l10nObject[l10nObjectKey] = fullTextString

    _fulltext.text = fullTextString
    _fulltext.l10ntext = l10nObject

    return _fulltext

