import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../theme/pop_theme.dart';

/// Short Pop toast at the top of the screen: "Added to downloads", "Saved", errors.
void popToast(String message, {IconData icon = Icons.check_rounded, bool error = false, String? detail}) {
  toastification.show(
    title: Text(message, style: const TextStyle(fontFamily: Pop.font, fontWeight: FontWeight.w700)),
    description: detail == null ? null : Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
    icon: Icon(icon, color: error ? Colors.white : Pop.ink),
    style: ToastificationStyle.flat,
    type: error ? ToastificationType.error : ToastificationType.success,
    backgroundColor: error ? Pop.error : Pop.yellow,
    foregroundColor: error ? Colors.white : Pop.ink,
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.circular(999),
    alignment: Alignment.topCenter,
    autoCloseDuration: const Duration(milliseconds: 2400),
    showProgressBar: false,
    closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
    dragToClose: true,
  );
}
