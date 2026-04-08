type="text/javascript"
//# sourceURL=form.js

'use strict';

function ensureShowPasswordToggle(password, toggleId, checkboxId) {
  let toggle = $('#' + toggleId);

  if (toggle.length > 0) {
    return toggle;
  }

  const wrapper = $(
    '<label id="' + toggleId + '" style="display:inline-flex;align-items:center;gap:0.35rem;margin-left:0.75rem;font-weight:normal;white-space:nowrap;">' +
      '<input type="checkbox" id="' + checkboxId + '" />' +
      '<span>Show</span>' +
    '</label>'
  );

  password.after(wrapper);
  return wrapper;
}

function setPasswordVisibility(password, shouldShow) {
  password.attr('type', shouldShow ? 'text' : 'password');
}

function toggleCustomAdminPassword() {
  const checkbox = $('#batch_connect_session_context_use_custom_admin_password');
  const password = $('#batch_connect_session_context_cryosparc_admin_password');
  const toggle = ensureShowPasswordToggle(
    password,
    'cryosparc_admin_password_show_toggle',
    'cryosparc_admin_password_show_checkbox'
  );
  const showCheckbox = $('#cryosparc_admin_password_show_checkbox');
  const enabled = checkbox.is(':checked');

  password.parent().toggle(enabled);
  toggle.toggle(enabled);
  password.prop('required', enabled);

  if (!enabled) {
    password.val('');
    password[0].setCustomValidity('');
    showCheckbox.prop('checked', false);
    setPasswordVisibility(password, false);
  }
}

$(function() {
  const checkbox = $('#batch_connect_session_context_use_custom_admin_password');
  const password = $('#batch_connect_session_context_cryosparc_admin_password');
  const toggle = ensureShowPasswordToggle(
    password,
    'cryosparc_admin_password_show_toggle',
    'cryosparc_admin_password_show_checkbox'
  );
  const showCheckbox = $('#cryosparc_admin_password_show_checkbox');
  const licenseId = $('#batch_connect_session_context_cryosparc_license_id');
  const licenseToggle = ensureShowPasswordToggle(
    licenseId,
    'cryosparc_license_id_show_toggle',
    'cryosparc_license_id_show_checkbox'
  );
  const licenseShowCheckbox = $('#cryosparc_license_id_show_checkbox');

  if (checkbox.length === 0 || password.length === 0) {
    return;
  }

  toggle.css('display', 'none');
  setPasswordVisibility(password, false);
  licenseToggle.css('display', 'inline-flex');
  setPasswordVisibility(licenseId, false);

  toggleCustomAdminPassword();

  checkbox.on('change', function() {
    toggleCustomAdminPassword();
  });

  showCheckbox.on('change', function() {
    setPasswordVisibility(password, showCheckbox.is(':checked'));
  });

  licenseShowCheckbox.on('change', function() {
    setPasswordVisibility(licenseId, licenseShowCheckbox.is(':checked'));
  });

  password.on('input', function() {
    if (checkbox.is(':checked') && password.val().trim() === '') {
      password[0].setCustomValidity('Enter a custom admin password or uncheck the option.');
    } else {
      password[0].setCustomValidity('');
    }
  });

  $('form').on('submit', function(event) {
    if (checkbox.is(':checked') && password.val().trim() === '') {
      password[0].setCustomValidity('Enter a custom admin password or uncheck the option.');
      password[0].reportValidity();
      event.preventDefault();
      return false;
    }

    password[0].setCustomValidity('');
    return true;
  });
});
