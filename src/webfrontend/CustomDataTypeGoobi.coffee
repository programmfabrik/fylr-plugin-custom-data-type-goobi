class CustomDataTypeGoobi extends CustomDataTypeWithCommonsAsPlugin

  #######################################################################  
  # return the prefix for localization for this data type.  
  # Note: This function is supposed to be deprecated, but is still used   
  # internally and has to be used here as a workaround because the   
  # default generates incorrect prefixes for camelCase class names 
  getL10NPrefix: ->
    'custom.data.type.goobi' 

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-goobi.goobi"


  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.goobi.name")

  #######################################################################
  # support geostandard in frontend?
  supportsGeoStandard: ->
    return false

  #######################################################################
  # configure used facet
  getFacet: (opts) ->
    opts.field = @
    new CustomDataTypeGoobiFacet(opts)

  #######################################################################
  # get frontend-language
  getFrontendLanguage: () ->
    # language
    desiredLanguage = ez5?.loca?.getLanguage()
    if desiredLanguage
      desiredLanguage = desiredLanguage.split('-')
      desiredLanguage = desiredLanguage[0]
    else
      desiredLanguage = false

    desiredLanguage
  
  #######################################################################
  # checks the form and returns status (Custom because it is no uri in conceptURI)
  getDataStatus: (cdata) ->
      if (cdata)
        if cdata.conceptURI and cdata.conceptName
          # check url for valididy
          uriCheck = false
          if cdata.conceptURI.trim() != ''
            uriCheck = true

          nameCheck = if cdata.conceptName then cdata.conceptName.trim() else undefined

          if uriCheck and nameCheck
            return "ok"

          if cdata.conceptURI.trim() == '' and cdata.conceptName.trim() == ''
            return "empty"

          return "invalid"
      return "empty"

   
 #######################################################################
  # read info from goobi-terminology
  __getAdditionalTooltipInfo: (uri, tooltip, extendedInfo_xhr) ->

    that = @

    #encodedURI = encodeURIComponent uri

    # abort eventually running request
    if extendedInfo_xhr.xhr != undefined
      extendedInfo_xhr.xhr.abort()

    # start new request and download goobi-process-record via identifier / uri
    goobi_endpoint_token = if that.getCustomMaskSettings().goobi_endpoint_token?.value then that.getCustomMaskSettings().goobi_endpoint_token?.value else ''
    goobi_endpoint_token = encodeURIComponent(goobi_endpoint_token)

    goobi_projects = if that.getCustomMaskSettings().projects?.value then that.getCustomMaskSettings().projects?.value else ''
    goobi_projects = encodeURIComponent(goobi_projects)

    goobi_api_url = if that.getCustomMaskSettings().goobi_api_url?.value then that.getCustomMaskSettings().goobi_api_url?.value else ''

    url = goobi_api_url + '/processes/search?token=' + goobi_endpoint_token + '&field='+that.getCustomSchemaSettings().safeAsConceptURI?.value+'&offset=0&orderby=' + that.getCustomSchemaSettings().safeAsConceptURI?.value + '&descending=true&value=' + uri + '&limit=1&filterProjects=' + goobi_projects
    extendedInfo_xhr.xhr = new (CUI.XHR)(url: url)
    extendedInfo_xhr.xhr.start()
    .done((data, status, statusText) ->
      htmlContent = '<span style="font-weight: bold; padding: 3px 6px;">' + $$('custom.data.type.goobi.config.parameter.mask.infopopup.popup.info') + '</span>'
      htmlContent += '<table style="border-spacing: 10px; border-collapse: separate;">'

      if data?[0]?.metadata
        metadatas = data?[0]?.metadata
        valuePairs = {}
        for key, metadata of metadatas
          for entry, key2 in metadata
            if entry.labels
              # get label in frontend-language if possible
              if entry.labels?[that.getFrontendLanguage()]
                label =  entry.labels?[that.getFrontendLanguage()]
              else
                label = entry.labels[Object.keys(entry.labels)[0]]
              if ! valuePairs[label]
                valuePairs[label] = []
              valuePairs[label].push entry['value']
        for key, metadata of valuePairs
          htmlContent += '<tr><td style="min-width:150px;"><b>' + key + ':</b></td><td>'
          for entry, key2 in metadata
            htmlContent += entry
          htmlContent += '</td></tr>'
        htmlContent += '</table>'
      tooltip.DOM.innerHTML = htmlContent
      tooltip.autoSize()
    )

    return


  #######################################################################
  # handle suggestions-menu
  __updateSuggestionsMenu: (cdata, cdata_form, searchstring, input, suggest_Menu, searchsuggest_xhr, layout, opts) ->
    that = @

    delayMillisseconds = 200

    setTimeout ( ->

        safeAsConceptName = that.getCustomSchemaSettings().safeAsConceptName?.value
        safeAsConceptURI = that.getCustomSchemaSettings().safeAsConceptURI?.value

        # as arthur says: https://gist.github.com/alisterlf/3490957#gistcomment-1405758
        #   and https://stackoverflow.com/questions/990904/remove-accents-diacritics-in-a-string-in-javascript#answer-37511463

        goobi_searchterm = searchstring.normalize('NFD').replace(/[\u0300-\u036f]/g, "")
        goobi_countSuggestions = 20
        goobi_searchfield = that.getCustomMaskSettings().searchfields?.value.split(',')
        goobi_projects_to_search = that.getCustomMaskSettings().projects?.value.split(',')

        if cdata_form
          goobi_searchterm = cdata_form.getFieldsByName("searchbarInput")[0].getValue()
          goobi_countSuggestions = cdata_form.getFieldsByName("countOfSuggestions")[0].getValue()
          goobi_searchfield = cdata_form.getFieldsByName("searchfieldSelect")[0].getValue()

        if goobi_searchterm.length == 0
            return
        
        goobi_searchterms = goobi_searchterm.split(' ')

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()

        # build new request
        searchBody = {};
        searchBody['filterProjects'] = goobi_projects_to_search

        searchBody['metadataFilters'] = []

        if ! Array.isArray(goobi_searchfield)
          goobi_searchfield = [goobi_searchfield]
        for goobi_searchterm, key in goobi_searchterms
            filters = []
            for goobi_searchfield_entry, key in goobi_searchfield
              filter = { "field": goobi_searchfield_entry, "relation" : "LIKE", "value" : goobi_searchterm }
              filters.push filter
            metadataFilter = { "conjunctive": false, "filters": filters }
            searchBody['metadataFilters'].push metadataFilter

        searchBody['metadataConjunctive'] = true
        searchBody['sortField'] = goobi_searchfield.shift()
        searchBody['sortDescending'] = false
        searchBody['limit'] = goobi_countSuggestions

        searchBody['offset'] = '0'
        searchBody['wantedFields'] = [safeAsConceptName, safeAsConceptURI]

        for goobi_searchfield_entry, key in goobi_searchfield
          searchBody['wantedFields'].push goobi_searchfield_entry

        searchBody['wantedFields'] = searchBody['wantedFields'].filter((x, i, a) => a.indexOf(x) == i)

        searchBody = JSON.stringify(searchBody)

        goobi_endpoint_token = if that.getCustomMaskSettings().goobi_endpoint_token?.value then that.getCustomMaskSettings().goobi_endpoint_token?.value else ''
        goobi_endpoint_token = encodeURIComponent(goobi_endpoint_token)

        goobi_projects = if that.getCustomMaskSettings().projects?.value then that.getCustomMaskSettings().projects?.value else ''
        goobi_projects = encodeURIComponent(goobi_projects)

        goobi_api_url = if that.getCustomMaskSettings().goobi_api_url?.value then that.getCustomMaskSettings().goobi_api_url?.value else ''

        url = goobi_api_url + '/processes/search?token=' + goobi_endpoint_token
        searchsuggest_xhr.xhr = new (CUI.XHR)(
          method: 'POST'
          url: url
          body: searchBody
          headers:  {'content-type' : 'application/json'}
        )

        searchsuggest_xhr.xhr.start().done((data, status, statusText) ->
            if status == 200 && data
              # init xhr for tooltipcontent
              extendedInfo_xhr = { "xhr" : undefined }

              # create new menu with suggestions
              menu_items = []
              # the actual Featureclass
              for suggestion, key in data
                id = suggestion.id
                suggestion = suggestion.metadata
                if suggestion?[safeAsConceptURI]
                  conceptNameCandidate = if suggestion?[safeAsConceptName] then suggestion?[safeAsConceptName][0].value else ''
                  conceptURICandidate = if suggestion?[safeAsConceptURI] then suggestion?[safeAsConceptURI][0].value else ''
                  if conceptNameCandidate == ''
                    conceptNameCandidate = $$('custom.data.type.goobi.config.parameter.mask.notdefined.label') + ' (ID: ' + id + ')'
                  if conceptNameCandidate != '' && conceptURICandidate != ''
                    do(key) ->
                      getUri = conceptURICandidate
                      item =
                        text: conceptNameCandidate
                        value: conceptURICandidate
                        tooltip:
                          markdown: true
                          placement: "nw"
                          content: (tooltip) ->
                              that.__getAdditionalTooltipInfo(getUri, tooltip, extendedInfo_xhr)
                              new CUI.Label(icon: "spinner", text: $$('custom.data.type.goobi.config.parameter.mask.show_infopopup.loading.label'))
                      menu_items.push item

              # set new items to menu
              itemList =
                onClick: (ev2, btn) ->
                  # lock in save data
                  cdata.conceptURI = btn.getOpt("value")
                  cdata.conceptName = btn.getText()
                  console.error cdata
                  console.error opts
                  # update the layout in form
                  that.__updateResult(cdata, layout, opts)
                  # hide suggest-menu
                  suggest_Menu.hide()
                  # close popover
                  if that.popover
                    that.popover.hide()
                items: menu_items

              # if no hits set "empty" message to menu
              if itemList.items.length == 0
                itemList =
                  items: [
                    text: "kein Treffer"
                    value: undefined
                  ]

              suggest_Menu.setItemList(itemList)

              suggest_Menu.show()
        )
    ), delayMillisseconds


  #######################################################################
  # create form
  __getEditorFields: (cdata) ->
    # read searchfields from datamodel
    searchOptions = []
    searchfields = this.getCustomMaskSettings().searchfields?.value.split ','
    for searchfield, key in searchfields
      option=
        value: searchfield
        text: $$('custom.data.type.goobi.modal.form.text.searchfield.' + searchfield)
      searchOptions.push option

    # form fields
    fields = [
      {
        type: CUI.Select
        undo_and_changed_support: false
        class: "commonPlugin_Select"
        form:
            label: $$('custom.data.type.goobi.modal.form.text.count')
        options: [
          (
              value: 10
              text: '10 ' + $$('custom.data.type.goobi.modal.form.text.count_short')
          )
          (
              value: 20
              text: '20 ' + $$('custom.data.type.goobi.modal.form.text.count_short')
          )
          (
              value: 50
              text: '50 ' + $$('custom.data.type.goobi.modal.form.text.count_short')
          )
          (
              value: 100
              text: '100 ' + $$('custom.data.type.goobi.modal.form.text.count_short')
          )
          (
              value: 500
              text: '500 ' + $$('custom.data.type.goobi.modal.form.text.count_short')
          )
        ]
        name: 'countOfSuggestions'
      }
      {
        type: CUI.Select
        class: "commonPlugin_Select"
        undo_and_changed_support: false
        form:
            label: $$('custom.data.type.goobi.modal.form.text.searchfield')
        options: searchOptions
        name: 'searchfieldSelect'
      }
      {
        type: CUI.Input
        class: "commonPlugin_Input"
        undo_and_changed_support: false
        form:
            label: $$("custom.data.type.goobi.modal.form.text.searchbar")
        placeholder: $$("custom.data.type.goobi.modal.form.text.searchbar.placeholder")
        name: "searchbarInput"
      }]

    fields


  #######################################################################
  # renders the "result" in original form (outside popover)
  __renderButtonByData: (cdata) ->

    that = @

    # when status is empty or invalid --> message

    switch @getDataStatus(cdata)
      when "empty"
        return new CUI.EmptyLabel(text: $$("custom.data.type.goobi.edit.no_goobi")).DOM
      when "invalid"
        return new CUI.EmptyLabel(text: $$("custom.data.type.goobi.edit.no_valid_goobi")).DOM

    extendedInfo_xhr = { "xhr" : undefined }

    # if status is ok
    cdata.conceptURI = cdata.conceptURI

    # output Button with Name of picked Entry and URI
    new CUI.HorizontalLayout
      maximize: true
      left:
        content:
          new CUI.Label
            centered: false
            text: cdata.conceptName
      center:
        content:
          # Url to the Source
          new CUI.Button
            appearance: "link"
            #href: cdata.conceptURI
            #target: "_blank"
            icon_left: new CUI.Icon(class: "fa-info-circle")
            tooltip:
              markdown: true
              placement: 'n'
              content: (tooltip) ->
                uri = cdata.conceptURI
                # get jskos-details-data
                that.__getAdditionalTooltipInfo(uri, tooltip, extendedInfo_xhr)
                # loader, until details are xhred
                new CUI.Label(icon: "spinner", text: $$('custom.data.type.dante.modal.form.popup.loadingstring'))
            text: ""
      right: null
    .DOM


  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []
    
    if custom_settings.safeAsConceptName?.value
      tags.push "✓ Name: " + custom_settings.safeAsConceptName.value
    else
      tags.push "✘ " + $$('custom.data.type.goobi.missing.config')

    if custom_settings.safeAsConceptURI.value
      tags.push "✓ URI: " + custom_settings.safeAsConceptURI.value
    else
      tags.push "✘ " + $$('custom.data.type.goobi.missing.config')
    tags


CustomDataType.register(CustomDataTypeGoobi)
