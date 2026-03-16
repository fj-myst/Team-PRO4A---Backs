import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app_theme.dart';
import '../../services/announcement_service.dart';

class EditAnnouncementScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;

  const EditAnnouncementScreen(
      {super.key, required this.announcement});

  @override
  State<EditAnnouncementScreen> createState() =>
      _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState
    extends State<EditAnnouncementScreen> {
  final _service = AnnouncementService();

  late TextEditingController _titleController;
  late TextEditingController _authorityController;
  late TextEditingController _toPresideController;
  late TextEditingController _invitedOrganizationsController;
  late TextEditingController _invitedNamesController;
  late TextEditingController _tasksController;
  late TextEditingController _otherVenueController;
  late List<TextEditingController> _agendaControllers;

  late String _attendeeType;
  late List<String> _selectedAttendeeUnitIds;
  late Map<String, String> _specificPersonnelPerUnit;
  late bool _needsTechAssist;
  late bool _isOtherVenue;

  String? _selectedVenueId;
  String? _selectedVenueName;
  DateTime? _selectedDateTime;

  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _venues = [];

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final a = widget.announcement;

    _titleController =
        TextEditingController(text: a['title'] ?? '');
    _authorityController =
        TextEditingController(text: a['authority'] ?? '');
    _toPresideController =
        TextEditingController(text: a['toPreside'] ?? '');
    _invitedOrganizationsController =
        TextEditingController(
            text: a['invitedOrganizations'] ?? '');
    _invitedNamesController =
        TextEditingController(text: a['invitedNames'] ?? '');
    _tasksController =
        TextEditingController(text: a['tasks'] ?? '');
    _otherVenueController = TextEditingController();

    final agendaItems =
        List<String>.from(a['agendaItems'] ?? ['']);
    _agendaControllers = agendaItems
        .map((item) => TextEditingController(text: item))
        .toList();

    _attendeeType = a['attendeeType'] ?? 'Physical';
    _selectedAttendeeUnitIds =
        List<String>.from(a['attendeeUnitIds'] ?? []);
    _specificPersonnelPerUnit =
        Map<String, String>.from(
            a['specificPersonnelPerUnit'] ?? {});
    _needsTechAssist = a['needsTechAssist'] ?? false;
    _selectedVenueId = a['venueId'];
    _selectedVenueName = a['venueName'];
    _isOtherVenue = a['venueId'] == 'others';

    if (a['dateTime'] != null) {
      _selectedDateTime =
          (a['dateTime'] as Timestamp).toDate();
    }

    _loadData();
  }

  void _loadData() async {
    final venues = await _service.getVenues();
    final units = await _service.getUnits();
    setState(() {
      _venues = venues;
      _units = units;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorityController.dispose();
    _toPresideController.dispose();
    _invitedOrganizationsController.dispose();
    _invitedNamesController.dispose();
    _tasksController.dispose();
    _otherVenueController.dispose();
    for (var c in _agendaControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Announcement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // 1. Title
                _buildLabel('1.  Title *'),
                const SizedBox(height: 8),
                _buildTextField(
                    controller: _titleController,
                    hint: 'Enter announcement title'),
                const SizedBox(height: 24),

                // 2. Authority
                _buildLabel('2.  Authority *'),
                const SizedBox(height: 8),
                _buildTextField(
                    controller: _authorityController,
                    hint: 'e.g. Office of the President'),
                const SizedBox(height: 24),

                // 3. To Preside
                _buildLabel('3.  To Preside *'),
                const SizedBox(height: 8),
                _buildTextField(
                    controller: _toPresideController,
                    hint: 'e.g. Dr. Juan dela Cruz'),
                const SizedBox(height: 24),

                // 4. Attendees
                _buildLabel('4.  Attendees *'),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ['Physical', 'Virtual']
                        .map((type) {
                      final isSelected =
                          _attendeeType == type;
                      return GestureDetector(
                        onTap: () => setState(
                            () => _attendeeType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                type == 'Physical'
                                    ? Icons.person
                                    : Icons.video_call,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                type,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _buildUnitMultiSelect(),
                const SizedBox(height: 24),

                // 5. Invited to Attend
                _buildLabel('5.  Invited to Attend'),
                const SizedBox(height: 4),
                const Text(
                  'External people or organizations',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                    controller:
                        _invitedOrganizationsController,
                    hint: 'Organizations'),
                const SizedBox(height: 8),
                _buildTextField(
                    controller: _invitedNamesController,
                    hint: 'Specific names'),
                const SizedBox(height: 24),

                // 6. Agenda
                _buildLabel('6.  Agenda *'),
                const SizedBox(height: 12),
                ..._agendaControllers
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller:
                                _agendaControllers[index],
                            decoration: _inputDecoration(
                                'Agenda item ${index + 1}'),
                          ),
                        ),
                        if (_agendaControllers.length > 1)
                          IconButton(
                            icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () => setState(() =>
                                _agendaControllers
                                    .removeAt(index)),
                          ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setState(() =>
                      _agendaControllers
                          .add(TextEditingController())),
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppTheme.primaryBlue),
                  label: const Text('Add Agenda Item',
                      style: TextStyle(
                          color: AppTheme.primaryBlue)),
                ),
                const SizedBox(height: 24),

                // 7. Date & Time
                _buildLabel('7.  Date & Time *'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDateTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.grey.shade400),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDateTime == null
                              ? 'Select date and time'
                              : '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year}  ${_selectedDateTime!.hour}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: _selectedDateTime == null
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 8. Venue
                _buildLabel('8.  Venue *'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedVenueId,
                  hint: const Text('Select a venue'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8)),
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                  ),
                  items: [
                    ..._venues.map((venue) =>
                        DropdownMenuItem<String>(
                          value: venue['id'],
                          child: Row(
                            children: [
                              Text(venue['name'] ?? ''),
                              if (venue[
                                      'requiresTechAssist'] ==
                                  true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      horizontal: 6,
                                      vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange
                                        .withOpacity(0.2),
                                    borderRadius:
                                        BorderRadius.circular(
                                            4),
                                  ),
                                  child: const Text(
                                    'Tech Required',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )),
                    const DropdownMenuItem<String>(
                      value: 'others',
                      child: Text('Others'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedVenueId = value;
                      _isOtherVenue = value == 'others';
                      if (!_isOtherVenue && value != null) {
                        final venue = _venues.firstWhere(
                            (v) => v['id'] == value);
                        _selectedVenueName = venue['name'];
                        _needsTechAssist =
                            venue['requiresTechAssist'] ==
                                true;
                      } else {
                        _selectedVenueName = null;
                        _needsTechAssist = false;
                      }
                    });
                  },
                ),
                if (_isOtherVenue) ...[
                  const SizedBox(height: 8),
                  _buildTextField(
                      controller: _otherVenueController,
                      hint: 'Please specify the venue'),
                ],
                const SizedBox(height: 16),

                // Tech Assistance
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _needsTechAssist
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _needsTechAssist
                          ? Colors.orange
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('Need Tech Assistance?',
                          style: TextStyle(
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _needsTechAssist,
                            onChanged: (val) => setState(
                                () =>
                                    _needsTechAssist = true),
                            activeColor: Colors.orange,
                          ),
                          const Text('Yes'),
                          const SizedBox(width: 24),
                          Radio<bool>(
                            value: false,
                            groupValue: _needsTechAssist,
                            onChanged: (val) => setState(
                                () =>
                                    _needsTechAssist = false),
                            activeColor: Colors.orange,
                          ),
                          const Text('No'),
                          if (_needsTechAssist) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius:
                                    BorderRadius.circular(
                                        10),
                              ),
                              child: const Text(
                                'Auto-set by venue',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 9. Tasks
                _buildLabel('9.  Tasks'),
                const SizedBox(height: 4),
                const Text(
                  'Optional',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tasksController,
                  maxLines: 4,
                  decoration: _inputDecoration(
                      'e.g. Prepare projector...'),
                ),
                const SizedBox(height: 32),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorMessage,
                                style: const TextStyle(
                                    color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(_isLoading
                        ? 'Saving...'
                        : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── HELPERS ──

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) =>
      TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: _inputDecoration(hint));

  InputDecoration _inputDecoration(String hint) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      );

  Widget _buildUnitMultiSelect() {
    return InkWell(
      onTap: () async {
        final result = await showDialog<List<String>>(
          context: context,
          builder: (context) => _MultiSelectDialog(
            items: _units,
            selectedIds: _selectedAttendeeUnitIds,
            labelKey: 'name',
            title: 'Select Units to Attend',
          ),
        );
        if (result != null) {
          setState(() => _selectedAttendeeUnitIds = result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.business,
                color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedAttendeeUnitIds.isEmpty
                  ? const Text('Select units',
                      style: TextStyle(color: Colors.grey))
                  : Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _selectedAttendeeUnitIds
                          .map((id) {
                        final unit = _units.firstWhere(
                            (u) => u['id'] == id,
                            orElse: () => {'name': id});
                        return Chip(
                          label: Text(unit['name'] ?? id,
                              style: const TextStyle(
                                  fontSize: 12)),
                          backgroundColor: AppTheme
                              .primaryBlue
                              .withOpacity(0.1),
                          onDeleted: () => setState(() =>
                              _selectedAttendeeUnitIds
                                  .remove(id)),
                        );
                      }).toList(),
                    ),
            ),
            const Icon(Icons.arrow_drop_down,
                color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate:
          DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedDateTime != null
          ? TimeOfDay.fromDateTime(_selectedDateTime!)
          : TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(date.year, date.month,
          date.day, time.hour, time.minute);
    });
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(
          () => _errorMessage = 'Please enter a title.');
      return;
    }
    if (_authorityController.text.trim().isEmpty) {
      setState(() =>
          _errorMessage = 'Please enter the authority.');
      return;
    }
    if (_toPresideController.text.trim().isEmpty) {
      setState(() => _errorMessage =
          'Please enter who will preside.');
      return;
    }
    if (_selectedAttendeeUnitIds.isEmpty) {
      setState(() => _errorMessage =
          'Please select at least one attendee unit.');
      return;
    }
    if (_agendaControllers
        .every((c) => c.text.trim().isEmpty)) {
      setState(() => _errorMessage =
          'Please add at least one agenda item.');
      return;
    }
    if (_selectedDateTime == null) {
      setState(() => _errorMessage =
          'Please select a date and time.');
      return;
    }
    if (_selectedVenueId == null) {
      setState(() =>
          _errorMessage = 'Please select a venue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final venueName = _isOtherVenue
        ? _otherVenueController.text.trim()
        : _selectedVenueName ?? '';

    final agendaItems = _agendaControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final result = await _service.updateAnnouncement(
      announcementId: widget.announcement['id'],
      title: _titleController.text.trim(),
      authority: _authorityController.text.trim(),
      toPreside: _toPresideController.text.trim(),
      attendeeType: _attendeeType,
      attendeeUnitIds: _selectedAttendeeUnitIds,
      specificPersonnelPerUnit: _specificPersonnelPerUnit,
      invitedOrganizations:
          _invitedOrganizationsController.text.trim(),
      invitedNames: _invitedNamesController.text.trim(),
      agendaItems: agendaItems,
      dateTime: _selectedDateTime!,
      venueId:
          _isOtherVenue ? 'others' : _selectedVenueId!,
      venueName: venueName,
      needsTechAssist: _needsTechAssist,
      tasks: _tasksController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() => _errorMessage =
          result['message'] ?? 'Error occurred.');
    }
  }
}

// ── MULTI SELECT DIALOG ──
class _MultiSelectDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<String> selectedIds;
  final String labelKey;
  final String title;

  const _MultiSelectDialog({
    required this.items,
    required this.selectedIds,
    required this.labelKey,
    required this.title,
  });

  @override
  State<_MultiSelectDialog> createState() =>
      _MultiSelectDialogState();
}

class _MultiSelectDialogState
    extends State<_MultiSelectDialog> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: widget.items.isEmpty
            ? const Text('No items found.',
                style: TextStyle(color: Colors.grey))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isSelected =
                      _tempSelected.contains(item['id']);
                  return CheckboxListTile(
                    title:
                        Text(item[widget.labelKey] ?? ''),
                    value: isSelected,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (val) => setState(() {
                      if (val == true) {
                        _tempSelected.add(item['id']);
                      } else {
                        _tempSelected.remove(item['id']);
                      }
                    }),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.pop(context, _tempSelected),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}