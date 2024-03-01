max_size = 1024 * 1024 * 1024 // 1 GiB default for https://httpd.apache.org/docs/2.4/mod/core.html#limitrequestbody

const Screen_EPrint_UploadMethod_File = Class.create({

	component: undefined,
	prefix: undefined,
	container: undefined,
	parameters: undefined,

	initialize: function (prefix, component, evt) {
		this.component = component;
		this.prefix = prefix;

		var div = $(prefix + '_dropbox');
		this.container = div;

		this.parameters = new Hash({
			screen: $F('screen'),
			eprintid: $F('eprintid'),
			stage: $F('stage'),
			component: component
		});

		// this.drop (evt);
	},
	dragCommence: function (evt) {
		var event = evt.memo.event;
		if (event.dataTransfer.types[0] == 'Files' || event.dataTransfer.types[0] == 'application/x-moz-file') {
			this.container.addClassName('ep_dropbox');
			$(this.prefix + '_dropbox_help').show();
			$(this.prefix + '_file').hide();
		}
	},
	dragFinish: function (evt) {
		this.container.removeClassName('ep_dropbox');
		$(this.prefix + '_dropbox_help').hide();
		$(this.prefix + '_file').show();
	},
	/*
	 * Handle a drop event on the HTML element
	 */
	drop: function (evt) {

		var files = evt.dataTransfer.files;
		var count = files.length;

		if (count == 0)
			return;

		this.handleFiles(files);
	},
	/*
	 * Handle a list of files dropped
	 */
	handleFiles: function (files) {
		// User dropped a lot of files, did they really mean to?
		if (files.length > 5) {
			eprints.currentRepository().phrase(
				{
					'Plugin/Screen/EPrint/UploadMethod/File:confirm_bulk_upload': {
						'n': files.length
					}
				},
				(function (phrases) {
					if (confirm(phrases['Plugin/Screen/EPrint/UploadMethod/File:confirm_bulk_upload']))
						for (var i = 0; i < files.length; ++i)
							if (this.checkFilesize(files[i])) {
								this.processFile(files[i]);
							}
				}).bind(this)
			);
		}
		else
			for (var i = 0; i < files.length; ++i)
				if (this.checkFilesize(files[i])) {
					this.processFile(files[i]);
				}
	},
	/*
	 * Check file size before uploading.
	 */
	checkFilesize: function (file) {

		if (file.size < max_size) {
			return true;
		}

		const max_size_mib = max_size / 1024 / 1024;

		eprints.currentRepository().phrase(
			{ 'Plugin/Screen/EPrint/UploadMethod/File:filesize_too_big': {} },
			function (phrase) {
				alert(file.name + ": \n" + phrase["Plugin/Screen/EPrint/UploadMethod/File:filesize_too_big"] + max_size_mib + " MiB.");
			}
		);

		return false;
	},
	/*
	 * Process a single file.
	 */
	processFile: function (file) {

		const fileFormId = `${this.prefix}_file`;

		const input = document.getElementById(fileFormId);
		const form = input.closest('form');
		const formData = new FormData(form);

		formData.set(fileFormId, file);

		UploadMethod_process_file(form, formData, this.prefix, this.component, file.name);
	},
});

function UploadMethod_process_file(form, formData, prefix, component, fileLabel) {

	const uuid = generate_uuid();
	const progress = `${uuid}_progress`;

	const xhr = new XMLHttpRequest();

	// progress status
	const progressRow = document.createElement('div');
	progressRow.setAttribute('id', progress);

	const progressContainer = progressRow;

	// file name
	const fileNameDiv = document.createElement('div');
	fileNameDiv.append(fileLabel);

	progressRow.append(fileNameDiv);

	// file size
	progressContainer.progress_size = document.createElement('div');
	progressRow.append(progressContainer.progress_size);

	// progress bar
	const progressBarDiv = document.createElement('div');

	progressRow.append(progressBarDiv);
	progressContainer.progress_bar = new EPrintsProgressBar({}, progressBarDiv);

	// progress text
	progressContainer.progress_info = document.createElement('div');
	progressRow.append(progressContainer.progress_info);

	// cancel button
	const cancelButton = new Element('button');

	cancelButton.innerHTML = 'Cancel';
	cancelButton.setAttribute('class', 'ep_form_action_button');

	cancelButton.addEventListener('click', function () {
		xhr.abort();
		progressRow.remove();
	});

	const cancelDiv = document.createElement('div');
	cancelDiv.append(cancelButton);
	progressRow.append(cancelDiv);

	eprints.currentRepository().phrase({ 'lib/submissionform:action_cancel': {} }, function (phrases) {
		cancelButton.innerHTML = phrases['lib/submissionform:action_cancel'];
	});

	document.getElementById(`${prefix}_progress_table`).append(progressRow);

	// Build the upload URL.

	const uploadUrl = new URL(form.getAttribute('action'), window.location.href);

	uploadUrl.searchParams.set('progressid', uuid);
	uploadUrl.searchParams.set('ajax', 'add_format');

	// Mark this request as an internal button to the server code. Internal
	// buttons will keep the user on the same stage in the workflow.

	formData.set(`_internal_${prefix}_add_format`, 'Upload');

	// Only process this particular component.

	formData.set('component', component);

	// Do the upload using XMLHttpRequest instead of Fetch so that we can get
	// upload progress at the same time. A FormData object is used so that
	// the upload content does not need to fit inside browser memory.

	xhr.addEventListener('load', function () {

		const matches = xhr.responseText.match(/UploadMethod_file_stop\( '([0-9A-F]*)', ([0-9]*) \)/);

		if (matches) {

			const uuid = matches[1];
			const docid = matches[2];

			progressRow.remove();

			if (docid) {
				Component_Documents.instances.invoke('refresh_document', docid);
			}
		}
	});

	xhr.upload.addEventListener('progress', function (event) {

		const percent = Math.floor(event.loaded / event.total * 100);

		progressContainer.progress_bar.update(percent / 100, percent + '%');
		progressContainer.progress_info.update(percent + '%');
		progressContainer.progress_size.update(human_filesize(event.total));
	});

	xhr.open('POST', uploadUrl);
	xhr.send(formData);
}

function UploadMethod_file_change(input, component, prefix) {

	if (input.value) {

		const form = input.closest('form');
		const formData = new FormData(form);
		const fileLabel = input.value.replace(/.*[^\\/][\\/]/, '');

		UploadMethod_process_file(form, formData, prefix, component, fileLabel);
	}
}
