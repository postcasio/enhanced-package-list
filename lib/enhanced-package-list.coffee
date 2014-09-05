module.exports =
	settingsView: null
	itemChangedSubscription: null
	itemRemovedSubscription: null
	disabledPackagesSubscription: null
	confSubscription: null

	highlightAuthor: null
	packagesChanged: true
	sourceFilter: 'all'

	configDefaults:
		highlightAuthor: ''
		sourceFilter: 'all'

	activate: (state) ->
		@itemChangedSubscription = atom.workspaceView.on 'pane:active-item-changed', (e, item) =>
			if item.is? '.settings-view'
				@settingsViewActive(item)

		@itemRemovedSubscription = atom.workspaceView.on 'pane:item-removed', (e, item) =>
			@packagesChanged = true

			if item.is? '.settings-view'
				@settingsViewRemoved()

		@disabledPackagesSubscription = atom.config.observe 'core.disabledPackages', callNow: false, (disabledPackages, {previous}) =>
			@packagesChanged = true

			if @settingsView and @settingsView.is ':visible'
				@updatePackageClasses()

		@confSubscription = atom.config.observe 'enhanced-package-list.highlightAuthor', (author) =>
			@packagesChanged = true

			@highlightAuthor = author
			if @settingsView and @settingsView.is ':visible'
				@updatePackageClasses()

		@filterConfSubscription = atom.config.observe 'enhanced-package-list.sourceFilter', (filter) =>
			@sourceFilter = filter

	deactivate: ->
		@itemAddedSubscription?.off()
		@itemRemovedSubscription?.off()
		@disabledPackagesSubscription?.off()
		@confSubscription?.off()
		@filterConfSubscription?.off()

	settingsViewActive: (@settingsView) ->
		unless @settingsView.hasClass('enhanced-package-list')
			{$, $$} = require('atom')
			path = require 'path'
			_ = require path.join atom.packages.resourcePath, 'node_modules', 'underscore-plus'
			fuzzaldrin = require path.join atom.packages.resourcePath, 'node_modules', 'fuzzaldrin'

			filter = $$ ->
				@div class: 'package-source-filter', =>
					@div class: 'btn-group', =>
						@button 'data-source': 'all', class: 'btn', 'All'
						@button 'data-source': 'core', class: 'btn', 'Core'
						@button 'data-source': 'user', class: 'btn', 'User'

			filter.find('[data-source=' + @sourceFilter + ']').addClass 'selected'

			filter.on 'click', '.btn', (e) =>
				btn = $(e.target)
				atom.config.set 'enhanced-package-list.sourceFilter', btn.attr 'data-source'
				filter.find('.selected').removeClass 'selected'
				btn.addClass 'selected'
				@settingsView.filterPackages()

			@settingsView.find('.settings-filter').before filter

			thisPackage = this

			@settingsView.filterPackages = ->
				filterText = @filterEditor.getEditor().getText()
				all = _.map @panelPackages.children(), (item) ->
					element: $(item)
					text: $(item).text()
				active = fuzzaldrin.filter(all, filterText, key: 'text')

				unless thisPackage.sourceFilter is 'all'
					active = _.filter active, (item) ->
						bundled = item.element.hasClass 'bundled-package'
						return if thisPackage.sourceFilter is 'core' then bundled else not bundled

				_.each all, ({element}) -> element.hide()
				_.each active, ({element}) -> element.show()

			@settingsView.addClass('enhanced-package-list')

		@updatePackageClasses @settingsView

	settingsViewRemoved: ->
		@settingsView = null

	updatePackageClasses: ()->
		return unless @settingsView

		return unless @packagesChanged

		names = atom.packages.getAvailablePackageNames()

		for name in names
			list_item = @settingsView.find(".panels-packages [name=#{name}]")

			if atom.packages.isBundledPackage(name)
				list_item.addClass('bundled-package')
			else
				list_item.removeClass('bundled-package')

			if atom.packages.isPackageDisabled(name)
				list_item.addClass('disabled-package')
			else
				list_item.removeClass('disabled-package')

			if metadata = atom.packages.getLoadedPackage(name)
				if metadata.isCompatible and not metadata.isCompatible()
					list_item.addClass('incompatible-package')
				else
					list_item.removeClass('incompatible-package')

			if @highlightAuthor and list_item.find('.package-author').text() is @highlightAuthor
				list_item.addClass('author-highlight')
			else
				list_item.removeClass('author-highlight')

		@settingsView.filterPackages()
		@packagesChanged = false

		return
