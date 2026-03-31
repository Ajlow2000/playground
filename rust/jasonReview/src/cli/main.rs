use std::collections::VecDeque;
use rand::Rng;

#[derive(Clone, Debug)]
enum EventType { 
    job,
    new_job
}

#[derive(Clone, Debug)]
struct QMember {
    event_type: EventType,
    serial: i32,
    start_time: f32,
    total_time: f32,
    time_so_far: f32,
    n_slices: i32,
}

fn add_new_event(queue: &mut VecDeque<QMember>, event_type: EventType, total_time: f32, mut m_serial:i32, m_time: f32) -> i32 {
    queue.push_back(QMember {
        event_type: event_type,
        serial: m_serial,
        start_time: m_time,
        total_time: total_time,
        time_so_far: 0.0,
        n_slices: 0
    });
    m_serial + 1
}

fn list_queue(currentTime: f32, queue: &VecDeque<QMember>) {
	let mut time_remaining: f32 = 0.0;
    for member in queue.iter() {
		time_remaining += member.total_time - member.time_so_far;
    }
	println!("{currentTime:7.2}	jobs: {}	remaining: {time_remaining:7.2}", queue.len(), );
}

fn main() {

	let time_window: f32 = 1050.0;
	let time_slice: f32 = 2.0;
	let task_switch_overhead: f32 = 0.5; 

    let mut m_serial: i32 = 0;  
    let mut m_time: f32 = 0.0;
    let mut q: VecDeque<QMember> = VecDeque::new();
    let mut nextJobArrival: f32 = 0.0;

    for i in 1..10 { 
		let runTime: f32 = rand::random_range(2.0..20.00);
        m_serial = add_new_event(&mut q, EventType::job, runTime, m_serial, m_time);
        println!("addedEvent {m_serial}");
    }

    list_queue(m_time, &q);

	while (m_time < time_window && !q.is_empty()) {
		if (m_time > nextJobArrival) {
			let runTime: f32 = rand::random_range(2.0..20.00);
			m_serial = add_new_event(&mut q, EventType::job, runTime, m_serial, m_time);
			nextJobArrival += 20.0; 
		}
		let mut job = q.pop_front().unwrap();
		if ((job.total_time - job.time_so_far) > time_slice) {
			job.time_so_far += time_slice;	
			job.n_slices += 1;
			q.push_back(job);
			m_time += time_slice + task_switch_overhead;
		} else {
			m_time += (job.total_time - job.time_so_far) + task_switch_overhead;
			job.time_so_far = job.total_time;
			println!("finished job - expended {}", job.total_time);
		}
		list_queue(m_time, &q);
		
	}
}
