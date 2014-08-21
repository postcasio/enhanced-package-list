module.exports =
	settingsView: null
	itemChangedSubscription: null
	itemRemovedSubscription: null
	disabledPackagesSubscription: null
	confSubscription: null

	highlightAuthor: null
	packagesChanged: true

	configDefaults:
		highlightAuthor: ''

	activate: (state) ->
		$ = require('atom').$

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

	deactivate: ->
		@itemAddedSubscription?.off()
		@itemRemovedSubscription?.off()
		@disabledPackagesSubscription?.off()
		@confSubscription?.off()

	settingsViewActive: (@settingsView) ->
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
			console.log @highlightAuthor
			console.log list_item.find('.package-author').text()
			if @highlightAuthor and list_item.find('.package-author').text() is @highlightAuthor
				list_item.addClass('author-highlight')
			else
				list_item.removeClass('author-highlight')


		@packagesChanged = false

		return
