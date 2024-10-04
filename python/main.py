from flask import Flask, jsonify, request
import json
from datetime import datetime, timedelta

app = Flask(__name__)

STUDENT_DATA_FILE = 'students.json'
HISTORY_DATA_FILE = 'history.json'
LOCATIONS_DATA_FILE = 'locations.json'
ACTIVE_PASSES_FILE = 'active_passes.json'

def load_data(file_name):
    
    with open(file_name, 'r') as file:
        return json.load(file)

def save_data(file_name, data):
    with open(file_name, 'w') as file:
        json.dump(data, file)

def load_active_passes():
    try:
        with open(ACTIVE_PASSES_FILE, 'r') as file:
            return json.load(file)
    except FileNotFoundError:
        return {}

def save_active_passes(active_passes):
    with open(ACTIVE_PASSES_FILE, 'w') as file:
        json.dump(active_passes, file)

@app.route('/students', methods=['GET', 'POST'])
def handle_students():
    students = load_data(STUDENT_DATA_FILE)
    if request.method == 'GET':
        return jsonify(students)
    elif request.method == 'POST':
        new_student = request.json
        students[new_student['id']] = new_student
        save_data(STUDENT_DATA_FILE, students)
        return jsonify(new_student), 201

@app.route('/students/<student_id>', methods=['GET'])
def get_student(student_id):
    students = load_data(STUDENT_DATA_FILE)
    student = students.get(student_id)
    if student:
        return jsonify(student)
    else:
        return jsonify({"error": "Student not found"}), 404

@app.route('/history', methods=['GET', 'POST'])
def handle_history():
    history = load_data(HISTORY_DATA_FILE)
    if request.method == 'GET':
        return jsonify(history)
    elif request.method == 'POST':
        new_entry = request.json
        history[new_entry['event_id']] = new_entry
        save_data(HISTORY_DATA_FILE, history)
        return jsonify(new_entry), 201

@app.route('/locations', methods=['GET'])
def get_locations():
    locations = load_data(LOCATIONS_DATA_FILE)
    return jsonify(locations)


@app.route('/request_pass', methods=['POST'])
def request_pass():
    pass_request = request.json
    student_id = pass_request['student_id']
    from_location = pass_request['from_location']
    to_location = pass_request['to_location']
    duration_minutes = pass_request['duration_minutes']
    
    start_time = datetime.now()
    end_time = start_time + timedelta(minutes=duration_minutes)
    
    new_entry = {
        'event_id': f"{student_id}_{start_time.isoformat()}",
        'student_id': student_id,
        'from_location': from_location,
        'to_location': to_location,
        'start_time': start_time.isoformat(),
        'end_time': end_time.isoformat(),
        'status': 'approved'
    }
    
    # Add to active passes
    active_passes = load_active_passes()
    active_passes[new_entry['event_id']] = new_entry
    save_active_passes(active_passes)
    
    # Add to history
    history = load_data(HISTORY_DATA_FILE)
    history[new_entry['event_id']] = new_entry
    save_data(HISTORY_DATA_FILE, history)
    
    return jsonify(new_entry), 201

@app.route('/active_passes', methods=['GET'])
def get_active_passes():
    current_time = datetime.now()
    active_passes = load_active_passes()
    active_pass_list = []
    for pass_entry in active_passes.values():
        end_time = datetime.fromisoformat(pass_entry['end_time'])
        if end_time > current_time and pass_entry.get('status') != 'cancelled':
            remaining_time = end_time - current_time
            pass_entry['remaining_time'] = str(remaining_time)
            active_pass_list.append(pass_entry)
    return jsonify(active_pass_list)

@app.route('/teachers/<teacher_id>', methods=['GET'])
def get_teacher(teacher_id):
    locations = load_data(LOCATIONS_DATA_FILE)
    teacher = next((loc for loc in locations if loc['teacher_id'] == teacher_id), None)
    if teacher:
        return jsonify(teacher)
    else:
        return jsonify({"error": "Teacher not found"}), 404

@app.route('/active_passes_for_teacher/<teacher_id>', methods=['GET'])
def get_active_passes_for_teacher(teacher_id):
    active_passes = load_active_passes()
    current_time = datetime.now()
    teacher = next((loc for loc in load_data(LOCATIONS_DATA_FILE) if loc['teacher_id'] == teacher_id), None)
    
    if not teacher:
        return jsonify({"error": "Teacher not found"}), 404
    
    teacher_room = teacher['room_number']  # Changed this line
    teacher_passes = []
    
    for pass_entry in active_passes.values():
        end_time = datetime.fromisoformat(pass_entry['end_time'])
        if end_time > current_time and (pass_entry['from_location'] == teacher_room or pass_entry['to_location'] == teacher_room):
            remaining_time = end_time - current_time
            pass_entry['remaining_time'] = str(remaining_time)
            teacher_passes.append(pass_entry)
    
    return jsonify(teacher_passes)

@app.route('/cancel_pass/<event_id>', methods=['DELETE'])
def cancel_pass(event_id):
    active_passes = load_active_passes()
    history = load_data(HISTORY_DATA_FILE)
    
    if event_id in active_passes:
        del active_passes[event_id]
        save_active_passes(active_passes)
        
        if event_id in history:
            history[event_id]['status'] = 'cancelled'
            save_data(HISTORY_DATA_FILE, history)
        
        return jsonify({"message": "Pass canceled successfully"}), 200
    else:
        return jsonify({"error": "Pass not found"}), 404

if __name__ == '__main__':
    app.run(debug=True)