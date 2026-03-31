use std::collections::VecDeque;
use std::time::Duration;

#[derive(Clone, Debug)]
enum Event {
    Job {
        total_time: Duration,
        time_so_far: Duration,
        n_slices: i32,
    },
}

fn add_new_event(queue: &mut VecDeque<Event>, total_time: Duration, m_serial: i32) -> i32 {
    queue.push_back(Event::Job {
        total_time,
        time_so_far: Duration::ZERO,
        n_slices: 0,
    });
    m_serial + 1
}

fn list_queue(current_time: Duration, queue: &VecDeque<Event>) {
    let time_remaining: Duration = queue.iter()
        .map(|e| match e {
            Event::Job { total_time, time_so_far, .. } => *total_time - *time_so_far,
        })
        .sum();
    println!("{:7.2}	jobs: {}	remaining: {:7.2}", current_time.as_secs_f32(), queue.len(), time_remaining.as_secs_f32());
}

fn main() {
    let time_window = Duration::from_secs_f32(1050.0);
    let time_slice = Duration::from_secs_f32(2.0);
    let task_switch_overhead = Duration::from_millis(500);

    let mut m_serial: i32 = 0;
    let mut m_time = Duration::ZERO;
    let mut q: VecDeque<Event> = VecDeque::new();
    let mut next_job_arrival = Duration::ZERO;

    (0..9).for_each(|_| {
        let run_time = Duration::from_secs_f32(rand::random_range(2.0_f32..20.0));
        m_serial = add_new_event(&mut q, run_time, m_serial);
        println!("addedEvent {m_serial}");
    });

    list_queue(m_time, &q);

    while m_time < time_window && !q.is_empty() {
        if m_time > next_job_arrival {
            let run_time = Duration::from_secs_f32(rand::random_range(2.0_f32..20.0));
            m_serial = add_new_event(&mut q, run_time, m_serial);
            next_job_arrival += Duration::from_secs(20);
        }
        let mut job = q.pop_front().expect("queue was empty");
        let remaining = match &job {
            Event::Job { total_time, time_so_far, .. } => *total_time - *time_so_far,
        };
        if remaining > time_slice {
            let Event::Job { time_so_far, n_slices, .. } = &mut job;
            *time_so_far += time_slice;
            *n_slices += 1;
            q.push_back(job);
            m_time += time_slice + task_switch_overhead;
        } else {
            m_time += remaining + task_switch_overhead;
            let Event::Job { total_time, .. } = job;
            println!("finished job - expended {:.2}", total_time.as_secs_f32());
        }
        list_queue(m_time, &q);
    }
}
