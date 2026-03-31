use std::collections::VecDeque;
use std::time::Duration;

#[derive(Clone, Debug)]
enum EventType {
    Job,
    #[allow(dead_code)]
    NewJob,
}

#[derive(Clone, Debug)]
struct QMember {
    #[allow(dead_code)]
    event_type: EventType,
    #[allow(dead_code)]
    serial: i32,
    #[allow(dead_code)]
    start_time: Duration,
    total_time: Duration,
    time_so_far: Duration,
    n_slices: i32,
}

fn add_new_event(queue: &mut VecDeque<QMember>, event_type: EventType, total_time: Duration, m_serial: i32, m_time: Duration) -> i32 {
    queue.push_back(QMember {
        event_type,
        serial: m_serial,
        start_time: m_time,
        total_time,
        time_so_far: Duration::ZERO,
        n_slices: 0,
    });
    m_serial + 1
}

fn list_queue(current_time: Duration, queue: &VecDeque<QMember>) {
    let time_remaining: Duration = queue.iter()
        .map(|m| m.total_time - m.time_so_far)
        .sum();
    println!("{:7.2}	jobs: {}	remaining: {:7.2}", current_time.as_secs_f32(), queue.len(), time_remaining.as_secs_f32());
}

fn main() {
    let time_window = Duration::from_secs_f32(1050.0);
    let time_slice = Duration::from_secs_f32(2.0);
    let task_switch_overhead = Duration::from_millis(500);

    let mut m_serial: i32 = 0;
    let mut m_time = Duration::ZERO;
    let mut q: VecDeque<QMember> = VecDeque::new();
    let mut next_job_arrival = Duration::ZERO;

    for _i in 1..10 {
        let run_time = Duration::from_secs_f32(rand::random_range(2.0_f32..20.0));
        m_serial = add_new_event(&mut q, EventType::Job, run_time, m_serial, m_time);
        println!("addedEvent {m_serial}");
    }

    list_queue(m_time, &q);

    while m_time < time_window && !q.is_empty() {
        if m_time > next_job_arrival {
            let run_time = Duration::from_secs_f32(rand::random_range(2.0_f32..20.0));
            m_serial = add_new_event(&mut q, EventType::Job, run_time, m_serial, m_time);
            next_job_arrival += Duration::from_secs(20);
        }
        let mut job = q.pop_front().expect("queue was empty");
        if (job.total_time - job.time_so_far) > time_slice {
            job.time_so_far += time_slice;
            job.n_slices += 1;
            q.push_back(job);
            m_time += time_slice + task_switch_overhead;
        } else {
            m_time += (job.total_time - job.time_so_far) + task_switch_overhead;
            job.time_so_far = job.total_time;
            println!("finished job - expended {:.2}", job.total_time.as_secs_f32());
        }
        list_queue(m_time, &q);
    }
}
