use std::collections::VecDeque;

use clap::{Arg, ArgMatches, Command};
use ratatui::text::Line;

use crate::app::Command as AppCommand;

pub fn cli() -> Command {
    Command::new("repl")
        .no_binary_name(true)
        .subcommand_required(true)
        .arg_required_else_help(false)
        .disable_help_flag(true)
        .disable_help_subcommand(true)
        .disable_version_flag(true)
        .subcommand(Command::new("help").about("Show available commands"))
        .subcommand(
            Command::new("echo")
                .about("Echo arguments back")
                .arg(Arg::new("words").num_args(0..).trailing_var_arg(true)),
        )
        .subcommand(Command::new("ping").about("Emit a tracing event and reply pong"))
        .subcommand(Command::new("warn").about("Emit a tracing warning"))
        .subcommand(Command::new("error").about("Emit a tracing error"))
        .subcommand(Command::new("clear").about("Clear the scrollback"))
        .subcommand(Command::new("exit").alias("quit").about("Exit the application"))
}

pub fn dispatch(line: &str, out: &mut VecDeque<Line<'static>>) -> Option<AppCommand> {
    let argv = match shlex::split(line) {
        Some(parts) if !parts.is_empty() => parts,
        _ => return None,
    };

    match cli().try_get_matches_from(&argv) {
        Err(e) => {
            for l in e.to_string().lines() {
                out.push_back(Line::from(l.to_string()));
            }
            None
        }
        Ok(matches) => match matches.subcommand() {
            Some(("help", _)) => {
                help(out);
                None
            }
            Some(("echo", sub)) => {
                echo(sub, out);
                None
            }
            Some(("ping", _)) => {
                ping(out);
                None
            }
            Some(("warn", _)) => {
                warn(out);
                None
            }
            Some(("error", _)) => {
                error(out);
                None
            }
            Some(("clear", _)) => {
                out.clear();
                None
            }
            Some(("exit", _)) => {
                tracing::info!(target: "repl::exit", "exit requested from REPL");
                Some(AppCommand::Quit)
            }
            _ => None,
        },
    }
}

fn help(out: &mut VecDeque<Line<'static>>) {
    for l in [
        "Commands:",
        "  help          show this help",
        "  echo [words]  print arguments",
        "  ping          emit info-level tracing event, reply pong",
        "  warn          emit warn-level tracing event",
        "  error         emit error-level tracing event",
        "  clear         clear the scrollback",
        "  exit | quit   exit the application",
    ] {
        out.push_back(Line::from(l));
    }
}

fn echo(sub: &ArgMatches, out: &mut VecDeque<Line<'static>>) {
    let words: Vec<&str> = sub
        .get_many::<String>("words")
        .map(|v| v.map(String::as_str).collect())
        .unwrap_or_default();
    let msg = words.join(" ");
    tracing::info!(target: "repl::echo", message = %msg, "echo invoked");
    out.push_back(Line::from(msg));
}

fn ping(out: &mut VecDeque<Line<'static>>) {
    tracing::info!(target: "repl::ping", "ping invoked");
    out.push_back(Line::from("pong"));
}

fn warn(out: &mut VecDeque<Line<'static>>) {
    tracing::warn!(target: "repl::warn", "warn invoked from REPL");
    out.push_back(Line::from("logged a warning"));
}

fn error(out: &mut VecDeque<Line<'static>>) {
    tracing::error!(target: "repl::error", "error invoked from REPL");
    out.push_back(Line::from("logged an error"));
}
