class MessagePanel extends HTMLElement
	initialize: (message) ->
		@textContent = message
		btn = document.createElement 'button'
		btn.textContent = 'Close'
		btn.classList.add 'btn', 'pull-right'
		@appendChild btn

	attach: ->
		@panel = atom.workspace.addBottomPanel item: this

	destroy: ->
		@panel.destroy()

module.exports = document.registerElement 'epl-message-panel', prototype: MessagePanel.prototype
