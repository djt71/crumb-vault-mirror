#!/usr/bin/env python3
"""
bridge-watcher.py — Persistent kqueue daemon for the crumb-tess-bridge.

Watches _openclaw/inbox/ for new .json request files and dispatches
processing via bridge-processor.js. Designed to run under launchd with
KeepAlive=true.

Exit codes:
  0 = clean shutdown (SIGTERM/SIGINT)
  1 = configuration error
  2 = inbox directory inaccessible
  3 = kqueue setup failure
"""

import fcntl
import json
import logging
import os
import re
import select
import signal
import subprocess
import sys
import time
from collections import deque
from contextlib import contextmanager
from pathlib import Path





# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

class Config:
    """Environment-based configuration with sensible defaults."""

    def __init__(self):
        self.vault_root = Path(os.environ.get(
            'CRUMB_VAULT_ROOT', os.getcwd()))
        self.inbox = Path(os.environ.get(
            'CRUMB_BRIDGE_INBOX',
            self.vault_root / '_openclaw' / 'inbox'))
        self.outbox = Path(os.environ.get(
            'CRUMB_BRIDGE_OUTBOX',
            self.vault_root / '_openclaw' / 'outbox'))
        self.lock_path = Path(os.environ.get(
            'CRUMB_BRIDGE_LOCK',
            self.vault_root / '_openclaw' / '.bridge.lock'))
        self.kill_switch = Path(os.environ.get(
            'CRUMB_BRIDGE_KILL_SWITCH',
            self.vault_root / '_openclaw' / '.bridge-disabled'))
        self.processed_ids_path = Path(os.environ.get(
            'CRUMB_BRIDGE_PROCESSED_IDS',
            self.vault_root / '_openclaw' / '.processed-ids'))
        self.processor_script = Path(os.environ.get(
            'CRUMB_BRIDGE_PROCESSOR',
            self.vault_root / 'Projects' / 'crumb-tess-bridge' / 'src' /
            'crumb' / 'scripts' / 'bridge-processor.js'))
        self.node_bin = os.environ.get('CRUMB_BRIDGE_NODE', 'node')
        self.use_claude = os.environ.get('CRUMB_BRIDGE_USE_CLAUDE', '') == '1'
        self.claude_bin = os.environ.get('CRUMB_BRIDGE_CLAUDE', 'claude')
        self.verify_governance_script = Path(os.environ.get(
            'CRUMB_BRIDGE_VERIFY_GOVERNANCE',
            self.vault_root / 'Projects' / 'crumb-tess-bridge' / 'src' /
            'crumb' / 'scripts' / 'verify-governance.js'))
        self.alerts_dir = Path(os.environ.get(
            'CRUMB_BRIDGE_ALERTS',
            self.vault_root / '_openclaw' / 'alerts'))
        self.dispatch_dir = Path(os.environ.get(
            'CRUMB_BRIDGE_DISPATCH_DIR',
            self.vault_root / '_openclaw' / 'dispatch'))
        self.transcripts_dir = Path(os.environ.get(
            'CRUMB_BRIDGE_TRANSCRIPTS',
            self.vault_root / '_openclaw' / 'transcripts'))

        # Phase 2 dispatch engine module path
        self.dispatch_engine_path = Path(os.environ.get(
            'CRUMB_BRIDGE_DISPATCH_ENGINE',
            self.vault_root / 'Projects' / 'crumb-tess-bridge' / 'src' /
            'watcher'))

        # Rate limiting
        self.rate_limit_max = int(os.environ.get(
            'CRUMB_BRIDGE_RATE_MAX', '60'))
        self.rate_limit_window = int(os.environ.get(
            'CRUMB_BRIDGE_RATE_WINDOW', '3600'))  # seconds

        # Subprocess timeout (60s for Phase 1 direct-node ops;
        # increase to 300+ for Phase 2 claude --print)
        self.process_timeout = int(os.environ.get(
            'CRUMB_BRIDGE_PROCESS_TIMEOUT', '60'))

        # Fallback scan interval
        self.fallback_interval = int(os.environ.get(
            'CRUMB_BRIDGE_FALLBACK_INTERVAL', '60'))

        # pgrep check
        self.skip_pgrep = os.environ.get(
            'CRUMB_BRIDGE_SKIP_PGREP', '') == '1'

    def validate(self):
        """Validate configuration. Returns list of errors."""
        errors = []
        if not self.inbox.is_dir():
            errors.append(f'Inbox directory does not exist: {self.inbox}')
        if not self.processor_script.is_file():
            errors.append(
                f'Processor script not found: {self.processor_script}')
        if self.rate_limit_max < 1:
            errors.append(
                f'Rate limit max must be >= 1, got {self.rate_limit_max}')
        if self.process_timeout < 1:
            errors.append(
                f'Process timeout must be >= 1, got {self.process_timeout}')
        return errors


# ---------------------------------------------------------------------------
# Structured JSON logging
# ---------------------------------------------------------------------------

class JsonFormatter(logging.Formatter):
    """Emit structured JSON log lines to stdout."""

    def format(self, record):
        entry = {
            'ts': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(record.created)),
            'level': record.levelname.lower(),
            'msg': record.getMessage(),
        }
        if hasattr(record, 'request_id'):
            entry['request_id'] = record.request_id
        if hasattr(record, 'filename_'):
            entry['file'] = record.filename_
        if hasattr(record, 'error_code'):
            entry['error_code'] = record.error_code
        if hasattr(record, 'extra_fields'):
            entry.update(record.extra_fields)
        return json.dumps(entry)


def setup_logging():
    logger = logging.getLogger('bridge-watcher')
    logger.setLevel(logging.INFO)
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JsonFormatter())
    logger.addHandler(handler)
    return logger


def log_event(logger, level, msg, **kwargs):
    """Log with optional structured fields."""
    record = logger.makeRecord(
        'bridge-watcher', level, '', 0, msg, (), None)
    for k, v in kwargs.items():
        setattr(record, k, v)
    logger.handle(record)


# ---------------------------------------------------------------------------
# Rate limiter
# ---------------------------------------------------------------------------

class SlidingWindowRateLimiter:
    """Sliding window rate limiter using a deque of timestamps."""

    def __init__(self, max_requests, window_seconds):
        self.max_requests = max_requests
        self.window = window_seconds
        self.timestamps = deque()

    def seed_from_processed_ids(self, processed_ids_path, logger=None):
        """Seed rate limiter from .processed-ids file by parsing UUIDv7
        timestamps. Skips malformed entries with a warning."""
        try:
            content = processed_ids_path.read_text()
        except FileNotFoundError:
            return
        except OSError as e:
            if logger:
                log_event(logger, logging.WARNING,
                          f'Cannot read .processed-ids: {e}')
            return

        now = time.time()
        cutoff = now - self.window
        for line in content.strip().split('\n'):
            line = line.strip()
            if not line:
                continue
            ts = parse_uuidv7_timestamp(line)
            if ts is None:
                if logger:
                    log_event(logger, logging.WARNING,
                              f'Malformed UUIDv7 in .processed-ids, skipping',
                              extra_fields={'entry': line[:50]})
                continue
            if ts > cutoff:
                self.timestamps.append(ts)

    def allow(self):
        """Check if a request is allowed. Does NOT record it."""
        now = time.time()
        self._evict(now)
        return len(self.timestamps) < self.max_requests

    def record(self):
        """Record a request timestamp."""
        now = time.time()
        self._evict(now)
        self.timestamps.append(now)

    def _evict(self, now):
        cutoff = now - self.window
        while self.timestamps and self.timestamps[0] <= cutoff:
            self.timestamps.popleft()


def parse_uuidv7_timestamp(uuid_str):
    """Extract Unix timestamp (seconds) from a UUIDv7 string.
    Returns None if the string is not a valid UUIDv7."""
    # UUIDv7 format: xxxxxxxx-xxxx-7xxx-yxxx-xxxxxxxxxxxx
    # First 48 bits (12 hex chars) encode milliseconds since epoch
    cleaned = uuid_str.replace('-', '')
    if len(cleaned) != 32:
        return None
    # Check version nibble (position 12) is '7'
    if cleaned[12] != '7':
        return None
    try:
        ms = int(cleaned[:12], 16)
    except ValueError:
        return None
    # Sanity: reject timestamps before 2020 or after 2100
    ts = ms / 1000.0
    if ts < 1577836800 or ts > 4102444800:
        return None
    return ts


def _generate_uuidv7():
    """Generate a UUIDv7 string (time-ordered, RFC 9562)."""
    ms = int(time.time() * 1000)
    rand_bytes = os.urandom(10)
    time_high = (ms >> 16) & 0xFFFFFFFF
    time_low = ms & 0xFFFF
    rand_a = 0x7000 | (((rand_bytes[0] << 4) | (rand_bytes[1] >> 4)) & 0x0FFF)
    rand_b_high = 0x80 | (rand_bytes[2] & 0x3F)
    rand_b_rest = rand_bytes[3:9]
    return (
        f"{time_high:08x}-{time_low:04x}-{rand_a:04x}-"
        f"{rand_b_high:02x}{rand_b_rest[0]:02x}-"
        f"{rand_b_rest[1]:02x}{rand_b_rest[2]:02x}"
        f"{rand_b_rest[3]:02x}{rand_b_rest[4]:02x}"
        f"{rand_b_rest[5]:02x}{rand_bytes[9]:02x}"
    )


# ---------------------------------------------------------------------------
# .processed-ids in-memory set (CTB-030)
# ---------------------------------------------------------------------------

class ProcessedIdSet:
    """In-memory set for O(1) duplicate detection, backed by .processed-ids file.

    Loads IDs from disk on construction. Records new IDs to both the in-memory
    set and the file (append). Malformed lines are skipped during load.
    """

    def __init__(self, path, logger=None):
        self._path = path
        self._logger = logger
        self._ids = set()
        self._load()

    def _load(self):
        """Load IDs from the .processed-ids file into the in-memory set."""
        try:
            content = self._path.read_text()
        except FileNotFoundError:
            return
        except OSError as e:
            if self._logger:
                log_event(self._logger, logging.WARNING,
                          f'Cannot read .processed-ids: {e}')
            return

        for line in content.strip().split('\n'):
            line = line.strip()
            if not line:
                continue
            # Accept any non-empty line as an ID (UUIDv7 or legacy format)
            self._ids.add(line)

        if self._logger:
            log_event(self._logger, logging.INFO,
                      f'Loaded {len(self._ids)} processed IDs into memory')

    def contains(self, request_id):
        """O(1) duplicate check."""
        return request_id in self._ids

    def record(self, request_id):
        """Add ID to in-memory set and append to file for persistence."""
        self._ids.add(request_id)
        try:
            with open(self._path, 'a') as f:
                f.write(request_id + '\n')
        except OSError as e:
            if self._logger:
                log_event(self._logger, logging.WARNING,
                          f'Failed to append to .processed-ids: {e}',
                          extra_fields={'request_id': request_id})

    def reload(self):
        """Reload from disk (e.g., after compaction)."""
        self._ids.clear()
        self._load()

    def __len__(self):
        return len(self._ids)

    def __contains__(self, item):
        return item in self._ids


# ---------------------------------------------------------------------------
# .processed-ids compaction (30-day UUIDv7 rotation)
# ---------------------------------------------------------------------------

def compact_processed_ids(processed_ids_path, logger=None, retention_days=30):
    """Remove entries older than retention_days from .processed-ids.
    Parses UUIDv7 timestamps; keeps entries that can't be parsed (conservative)."""
    try:
        content = processed_ids_path.read_text()
    except FileNotFoundError:
        return
    except OSError as e:
        if logger:
            log_event(logger, logging.WARNING,
                      f'Cannot read .processed-ids for compaction: {e}')
        return

    lines = content.strip().split('\n')
    if not lines or (len(lines) == 1 and not lines[0]):
        return

    cutoff = time.time() - (retention_days * 86400)
    kept = []
    removed = 0

    for line in lines:
        line = line.strip()
        if not line:
            continue
        ts = parse_uuidv7_timestamp(line)
        if ts is None:
            # Can't parse — keep it (conservative)
            kept.append(line)
        elif ts >= cutoff:
            kept.append(line)
        else:
            removed += 1

    if removed > 0:
        try:
            processed_ids_path.write_text('\n'.join(kept) + '\n' if kept else '')
            if logger:
                log_event(logger, logging.INFO,
                          f'Compacted .processed-ids: removed {removed} entries older than {retention_days}d',
                          extra_fields={'removed': removed, 'kept': len(kept)})
        except OSError as e:
            if logger:
                log_event(logger, logging.WARNING,
                          f'Failed to write compacted .processed-ids: {e}')


# ---------------------------------------------------------------------------
# Flock wrapper
# ---------------------------------------------------------------------------

class BridgeLock:
    """Non-blocking flock wrapper for mutual exclusion with the interactive
    Claude wrapper and between watcher invocations."""

    def __init__(self, lock_path):
        self.lock_path = lock_path
        self._fd = None

    def acquire(self):
        """Try to acquire exclusive lock (non-blocking).
        Returns True if acquired, False if held by another process."""
        try:
            self._fd = open(self.lock_path, 'w')
            fcntl.flock(self._fd.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            return True
        except (IOError, OSError):
            if self._fd:
                self._fd.close()
                self._fd = None
            return False

    def release(self):
        """Release the lock."""
        if self._fd:
            try:
                fcntl.flock(self._fd.fileno(), fcntl.LOCK_UN)
                self._fd.close()
            except (IOError, OSError):
                pass
            self._fd = None

    @contextmanager
    def held(self):
        """Context manager: acquire lock, yield, release."""
        acquired = self.acquire()
        try:
            yield acquired
        finally:
            if acquired:
                self.release()


# ---------------------------------------------------------------------------
# pgrep check (advisory)
# ---------------------------------------------------------------------------

def interactive_claude_running(skip=False):
    """Check if an interactive Claude session is running (advisory).
    Filters out: this process, child processes, --print invocations.
    Returns True if an interactive session is likely running."""
    if skip:
        return False

    try:
        result = subprocess.run(
            ['pgrep', '-fa', 'claude'],
            capture_output=True, text=True, timeout=5)
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False

    if result.returncode != 0:
        return False

    my_pid = os.getpid()
    my_pgid = os.getpgrp()

    for line in result.stdout.strip().split('\n'):
        if not line:
            continue
        parts = line.split(None, 1)
        if len(parts) < 2:
            continue
        try:
            pid = int(parts[0])
        except ValueError:
            continue
        cmd = parts[1]

        # Skip our own process and children
        if pid == my_pid:
            continue
        try:
            if os.getpgid(pid) == my_pgid:
                continue
        except (OSError, ProcessLookupError):
            pass

        # Skip --print invocations (non-interactive)
        if '--print' in cmd:
            continue

        # Skip bridge-watcher processes
        if 'bridge-watcher' in cmd:
            continue

        # Found an interactive claude process
        return True

    return False


# ---------------------------------------------------------------------------
# Inbox scanning
# ---------------------------------------------------------------------------

def scan_inbox(inbox_path):
    """Scan inbox directory for .json files, excluding dotfiles and temp files.
    Returns sorted list of Path objects."""
    try:
        entries = list(inbox_path.iterdir())
    except (FileNotFoundError, PermissionError):
        return []

    result = []
    for entry in entries:
        if not entry.is_file():
            continue
        name = entry.name
        # Skip dotfiles, temp files, non-json
        if name.startswith('.') or name.startswith('tmp') or not name.endswith('.json'):
            continue
        result.append(entry)

    result.sort(key=lambda p: p.name)
    return result


# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

def dispatch_file(file_path, config, lock, rate_limiter, logger,
                   processed_ids=None):
    """Run the full dispatch pipeline for a single file.
    Returns True if processed, False if skipped."""

    filename = file_path.name
    request_id = filename.replace('.json', '')  # best-effort for logging

    # 0. In-memory duplicate check (CTB-030 — O(1) pre-check)
    if processed_ids is not None and processed_ids.contains(request_id):
        log_event(logger, logging.INFO,
                  'Duplicate request (in-memory), skipping',
                  request_id=request_id, filename_=filename)
        # Move to .processed/ for cleanup
        processed_dir = config.inbox / '.processed'
        processed_dir.mkdir(parents=True, exist_ok=True)
        try:
            file_path.rename(processed_dir / filename)
        except OSError as e:
            log_event(logger, logging.WARNING,
                      f'Failed to move duplicate file: {e}',
                      filename_=filename)
        return True

    # 1. Outbox existence check (crash recovery — A2)
    outbox_response = config.outbox / f'{request_id}-response.json'
    if outbox_response.exists():
        log_event(logger, logging.INFO,
                  'Outbox response already exists, moving to .processed',
                  filename_=filename)
        processed_dir = config.inbox / '.processed'
        processed_dir.mkdir(parents=True, exist_ok=True)
        try:
            file_path.rename(processed_dir / filename)
        except OSError as e:
            log_event(logger, logging.WARNING,
                      f'Failed to move already-processed file: {e}',
                      filename_=filename)
        # A1 fix: record in .processed-ids so rate limiter counts this request
        # and audit trail is complete even for crash-recovery skips
        if processed_ids is not None:
            processed_ids.record(request_id)
        else:
            try:
                with open(config.processed_ids_path, 'a') as f:
                    f.write(request_id + '\n')
            except OSError as e:
                log_event(logger, logging.WARNING,
                          f'Failed to append to .processed-ids on outbox-skip: {e}',
                          filename_=filename)
        return True

    # 2. Parse operation early for routing + non-bridge detection (CTB-035)
    operation = _parse_operation(file_path, logger)
    if operation is None:
        # Non-bridge JSON — move to .unrecognized/ without wasting rate-limit budget
        log_event(logger, logging.WARNING,
                  'Non-bridge JSON (missing operation field), moving to .unrecognized',
                  filename_=filename)
        unrecognized_dir = config.inbox / '.unrecognized'
        unrecognized_dir.mkdir(parents=True, exist_ok=True)
        try:
            file_path.rename(unrecognized_dir / filename)
        except OSError as e:
            log_event(logger, logging.WARNING,
                      f'Failed to move non-bridge file: {e}',
                      filename_=filename)
        return True

    is_phase2 = operation in _PHASE_2_OPS

    # 3. Kill-switch check
    if config.kill_switch.exists():
        log_event(logger, logging.WARNING,
                  'Kill-switch active, rejecting request',
                  filename_=filename, error_code='BRIDGE_DISABLED')
        _invoke_reject(file_path, 'BRIDGE_DISABLED',
                       'Bridge processing disabled via kill-switch',
                       retryable=False, config=config, logger=logger)
        return True

    # 4. Rate-limit check
    if not rate_limiter.allow():
        log_event(logger, logging.WARNING,
                  'Rate limit exceeded, rejecting request',
                  filename_=filename, error_code='RATE_LIMITED')
        _invoke_reject(file_path, 'RATE_LIMITED',
                       f'Rate limit exceeded ({config.rate_limit_max} requests per '
                       f'{config.rate_limit_window}s window)',
                       retryable=True, config=config, logger=logger)
        return True

    # 5. Acquire flock (non-blocking)
    if not lock.acquire():
        if is_phase2:
            if operation == 'cancel-dispatch':
                # CTB-025: Leave cancel-dispatch in inbox for stage boundary
                # detection — the running dispatch's _is_cancel_requested()
                # will find it.
                log_event(logger, logging.INFO,
                          'Lock held — leaving cancel-dispatch in inbox '
                          'for stage boundary detection',
                          filename_=filename)
                return False
            # Other Phase 2: reject with DISPATCH_CONFLICT error response
            log_event(logger, logging.WARNING,
                      'Lock held — rejecting Phase 2 request with DISPATCH_CONFLICT',
                      filename_=filename, error_code='DISPATCH_CONFLICT')
            _reject_dispatch_conflict(file_path, config, logger,
                                         processed_ids=processed_ids)
            return True
        else:
            log_event(logger, logging.INFO,
                      'Lock held by another process, skipping (will retry)',
                      filename_=filename)
            return False

    try:
        # 6. pgrep check (advisory)
        if interactive_claude_running(skip=config.skip_pgrep):
            log_event(logger, logging.INFO,
                      'Interactive Claude session detected, deferring',
                      filename_=filename)
            return False

        # 7. Route based on operation
        if is_phase2:
            success = _dispatch_phase2(file_path, operation, config, logger)
        else:
            success = _dispatch_node(file_path, config, logger)

        if success:
            rate_limiter.record()
            # Record in processed IDs set (CTB-030)
            # The downstream processor/engine also appends to the file,
            # but we update the in-memory set here for consistency.
            if processed_ids is not None:
                processed_ids.record(request_id)

        return success

    finally:
        # 8. Release flock
        lock.release()


def _dispatch_node(file_path, config, logger):
    """Invoke bridge-processor.js process <file> directly."""
    cmd = [config.node_bin, str(config.processor_script), 'process', str(file_path)]
    log_event(logger, logging.INFO,
              'Dispatching to bridge-processor.js',
              filename_=file_path.name)

    try:
        result = subprocess.run(
            cmd,
            capture_output=True, text=True,
            timeout=config.process_timeout,
            cwd=str(config.vault_root),
            env={**os.environ, 'CRUMB_VAULT_ROOT': str(config.vault_root)})
    except subprocess.TimeoutExpired:
        log_event(logger, logging.ERROR,
                  f'Processor timed out after {config.process_timeout}s, leaving for retry',
                  filename_=file_path.name, error_code='TIMEOUT')
        return False

    if result.returncode != 0:
        log_event(logger, logging.ERROR,
                  f'Processor exited with code {result.returncode}',
                  filename_=file_path.name,
                  extra_fields={'stderr': result.stderr[:500] if result.stderr else ''})
        return False

    # Parse response to extract request_id for logging and governance verification
    request_id = None
    try:
        response = json.loads(result.stdout)
        request_id = response.get('request_id', 'unknown')
        log_event(logger, logging.INFO,
                  f'Processed successfully: {response.get("status", "unknown")}',
                  request_id=request_id,
                  filename_=file_path.name)
    except (json.JSONDecodeError, KeyError):
        log_event(logger, logging.INFO,
                  'Processed (could not parse response)',
                  filename_=file_path.name)

    # Governance verification — verify response integrity post-processing
    if request_id and request_id != 'unknown':
        response_path = config.outbox / f'{request_id}-response.json'
        if response_path.exists():
            if not _verify_governance(response_path, config, logger):
                return False

    return True


# ---------------------------------------------------------------------------
# Phase 2 operation routing
# ---------------------------------------------------------------------------

# Operations routed to dispatch engine
_PHASE_2_OPS = frozenset({
    'start-task', 'invoke-skill', 'quick-fix',
    'escalation-response', 'cancel-dispatch',
})

# Dispatch-triggering operations (create new dispatches)
_DISPATCH_OPS = frozenset({'start-task', 'invoke-skill', 'quick-fix'})


def _parse_operation(file_path, logger):
    """Parse the operation field from a request JSON file.
    Returns the operation string, or None if parsing fails."""
    try:
        with open(file_path) as f:
            data = json.load(f)
        return data.get('operation')
    except (json.JSONDecodeError, OSError) as e:
        log_event(logger, logging.WARNING,
                  f'Could not parse operation from request: {e}',
                  filename_=file_path.name)
        return None



def _dispatch_phase2(file_path, operation, config, logger):
    """Route a Phase 2 operation to the dispatch engine.

    Reads the request JSON, creates a DispatchEngine, and routes based on
    the operation type. Returns True if processed, False on unexpected error.
    """
    # Ensure dispatch engine module is on sys.path
    engine_path = str(config.dispatch_engine_path)
    if engine_path not in sys.path:
        sys.path.insert(0, engine_path)

    try:
        from dispatch_engine import DispatchEngine
    except ImportError as e:
        log_event(logger, logging.ERROR,
                  f'Failed to import dispatch engine: {e}',
                  filename_=file_path.name)
        return False

    # Read request
    try:
        with open(file_path) as f:
            request = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        log_event(logger, logging.ERROR,
                  f'Failed to read request file: {e}',
                  filename_=file_path.name)
        return False

    # Create engine
    engine = DispatchEngine(
        vault_root=str(config.vault_root),
        dispatch_dir=str(config.dispatch_dir),
        outbox_path=str(config.outbox),
        transcripts_path=str(config.transcripts_dir),
        alerts_path=str(config.alerts_dir),
        inbox_path=str(config.inbox),
        processed_ids_path=str(config.processed_ids_path),
        claude_bin=config.claude_bin,
        kill_switch_path=str(config.kill_switch),
        log=logger,
    )

    log_event(logger, logging.INFO,
              f'Routing Phase 2 operation to dispatch engine: {operation}',
              filename_=file_path.name)

    # Route by operation type
    if operation in _DISPATCH_OPS:
        return engine.run_dispatch(request, file_path)
    elif operation == 'escalation-response':
        return engine.handle_escalation_response(request, file_path)
    elif operation == 'cancel-dispatch':
        return engine.handle_cancel_dispatch(request, file_path)
    else:
        log_event(logger, logging.ERROR,
                  f'Unknown Phase 2 operation: {operation}',
                  filename_=file_path.name)
        return False


def _reject_dispatch_conflict(file_path, config, logger, processed_ids=None):
    """Write a DISPATCH_CONFLICT error response when flock can't be acquired
    for a Phase 2 request. Moves file to .processed/ since the request has
    been definitively handled."""
    request_id = file_path.name.replace('.json', '')

    # Try to read the actual request_id from the file
    try:
        with open(file_path) as f:
            data = json.load(f)
        request_id = data.get('id', request_id)
    except (json.JSONDecodeError, OSError):
        pass

    # Write error response — UUIDv7 for time-ordered IDs
    response = {
        'schema_version': '1.1',
        'id': _generate_uuidv7(),
        'request_id': request_id,
        'timestamp': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        'status': 'error',
        'error': {
            'code': 'DISPATCH_CONFLICT',
            'message': 'Another dispatch or processing operation is currently active',
            'retryable': True,
        },
        'governance_check': None,
        'transcript_hash': None,
        'transcript_path': None,
    }

    config.outbox.mkdir(parents=True, exist_ok=True)
    out_path = config.outbox / f'{request_id}-response.json'
    tmp_path = config.outbox / f'.tmp-{request_id}-response.json'
    try:
        with open(tmp_path, 'w') as f:
            json.dump(response, f, indent=2)
            f.write('\n')
            f.flush()
            os.fsync(f.fileno())
        os.replace(str(tmp_path), str(out_path))
    except OSError as e:
        log_event(logger, logging.ERROR,
                  f'Failed to write DISPATCH_CONFLICT response: {e}',
                  filename_=file_path.name)
        return

    # Move to .processed
    processed_dir = config.inbox / '.processed'
    processed_dir.mkdir(parents=True, exist_ok=True)
    try:
        file_path.rename(processed_dir / file_path.name)
    except OSError as e:
        log_event(logger, logging.WARNING,
                  f'Failed to move to .processed after DISPATCH_CONFLICT: {e}',
                  filename_=file_path.name)

    # Record in .processed-ids (in-memory set + file append)
    if processed_ids is not None:
        processed_ids.record(request_id)
    else:
        try:
            with open(config.processed_ids_path, 'a') as f:
                f.write(request_id + '\n')
        except OSError as e:
            log_event(logger, logging.WARNING,
                      f'Failed to append to .processed-ids: {e}',
                      filename_=file_path.name)


def _invoke_reject(file_path, error_code, message, retryable, config, logger):
    """Invoke bridge-processor.js reject subcommand.
    Node handles JSON parsing and ID extraction (A6)."""
    cmd = [
        config.node_bin, str(config.processor_script),
        'reject', str(file_path), error_code, message,
    ]
    if retryable:
        cmd.append('--retryable')

    try:
        result = subprocess.run(
            cmd,
            capture_output=True, text=True,
            timeout=30,  # reject should be fast
            cwd=str(config.vault_root),
            env={**os.environ, 'CRUMB_VAULT_ROOT': str(config.vault_root)})
        if result.returncode != 0:
            log_event(logger, logging.ERROR,
                      f'Reject command failed (exit {result.returncode})',
                      filename_=file_path.name,
                      extra_fields={'stderr': result.stderr[:500] if result.stderr else ''})
    except subprocess.TimeoutExpired:
        log_event(logger, logging.ERROR,
                  'Reject command timed out',
                  filename_=file_path.name)


def _verify_governance(response_path, config, logger):
    """Run verify-governance.js on the response file.
    Returns True if verification passes, False if it fails or errors.
    On failure: deletes the response file and writes an alert."""
    cmd = [
        config.node_bin, str(config.verify_governance_script),
        str(response_path), '--vault-root', str(config.vault_root),
    ]
    log_event(logger, logging.INFO,
              'Running governance verification',
              extra_fields={'response_file': response_path.name})

    try:
        result = subprocess.run(
            cmd,
            capture_output=True, text=True,
            timeout=30,
            cwd=str(config.vault_root),
            env={**os.environ, 'CRUMB_VAULT_ROOT': str(config.vault_root)})
    except subprocess.TimeoutExpired:
        log_event(logger, logging.CRITICAL,
                  'Governance verification timed out',
                  extra_fields={'response_file': response_path.name})
        _discard_response(response_path, 'VERIFY_TIMEOUT',
                          'Governance verification timed out', config, logger)
        return False

    if result.returncode == 0:
        log_event(logger, logging.INFO,
                  'Governance verification passed',
                  extra_fields={'response_file': response_path.name})
        return True

    # Verification failed — parse details, discard response, write alert
    errors_summary = ''
    try:
        verification = json.loads(result.stdout)
        errors_summary = '; '.join(verification.get('errors', []))
    except (json.JSONDecodeError, KeyError):
        errors_summary = result.stdout[:500] if result.stdout else 'no output'

    log_event(logger, logging.CRITICAL,
              f'Governance verification FAILED: {errors_summary}',
              extra_fields={'response_file': response_path.name})

    _discard_response(response_path, 'GOVERNANCE_VERIFY_FAILED',
                      errors_summary, config, logger)
    return False


def _discard_response(response_path, alert_code, alert_message, config, logger):
    """Delete a response file from outbox and write an alert file."""
    # Delete the response
    try:
        response_path.unlink()
        log_event(logger, logging.WARNING,
                  'Discarded response file',
                  extra_fields={'response_file': response_path.name})
    except OSError as e:
        log_event(logger, logging.ERROR,
                  f'Failed to delete response file: {e}',
                  extra_fields={'response_file': response_path.name})

    # Write alert file for Telegram notification
    config.alerts_dir.mkdir(parents=True, exist_ok=True)
    alert = {
        'ts': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        'alert_code': alert_code,
        'message': alert_message,
        'response_file': response_path.name,
    }
    alert_filename = f'{int(time.time())}-{alert_code}.json'
    alert_path = config.alerts_dir / alert_filename
    try:
        alert_path.write_text(json.dumps(alert, indent=2) + '\n')
        log_event(logger, logging.INFO,
                  f'Alert written: {alert_filename}',
                  extra_fields={'alert_path': str(alert_path)})
    except OSError as e:
        log_event(logger, logging.ERROR,
                  f'Failed to write alert file: {e}')


# ---------------------------------------------------------------------------
# Main watcher
# ---------------------------------------------------------------------------

class BridgeWatcher:
    """Persistent kqueue watcher with fallback scanning."""

    def __init__(self, config, logger):
        self.config = config
        self.logger = logger
        self.lock = BridgeLock(config.lock_path)
        self.rate_limiter = SlidingWindowRateLimiter(
            config.rate_limit_max, config.rate_limit_window)
        self.processed_ids = None  # initialized in run() after compaction
        self._running = True
        self._kq = None
        self._inbox_fd = None

    def run(self):
        """Main entry point. Sets up signal handlers, seeds state, enters loop."""
        signal.signal(signal.SIGTERM, self._handle_signal)
        signal.signal(signal.SIGINT, self._handle_signal)

        log_event(self.logger, logging.INFO, 'Bridge watcher starting',
                  extra_fields={
                      'inbox': str(self.config.inbox),
                      'rate_limit': f'{self.config.rate_limit_max}/{self.config.rate_limit_window}s',
                      'timeout': self.config.process_timeout,
                      'use_claude': self.config.use_claude,
                      'skip_pgrep': self.config.skip_pgrep,
                  })

        # Compact .processed-ids on startup (30-day rotation)
        compact_processed_ids(
            self.config.processed_ids_path, self.logger)

        # Load processed IDs into memory (CTB-030 — after compaction)
        self.processed_ids = ProcessedIdSet(
            self.config.processed_ids_path, self.logger)

        # Seed rate limiter from .processed-ids
        self.rate_limiter.seed_from_processed_ids(
            self.config.processed_ids_path, self.logger)

        log_event(self.logger, logging.INFO,
                  f'Rate limiter seeded with {len(self.rate_limiter.timestamps)} recent entries')

        # Setup kqueue
        try:
            self._setup_kqueue()
        except OSError as e:
            log_event(self.logger, logging.ERROR,
                      f'Failed to setup kqueue: {e}')
            sys.exit(3)

        # Initial scan for any files already in inbox
        self._process_inbox()

        # Main loop
        try:
            self._main_loop()
        finally:
            self._cleanup()

        log_event(self.logger, logging.INFO, 'Bridge watcher stopped')

    def _setup_kqueue(self):
        """Set up kqueue to watch the inbox directory."""
        self._kq = select.kqueue()
        self._inbox_fd = os.open(str(self.config.inbox), os.O_RDONLY)

        ev = select.kevent(
            self._inbox_fd,
            filter=select.KQ_FILTER_VNODE,
            flags=select.KQ_EV_ADD | select.KQ_EV_CLEAR,
            fflags=select.KQ_NOTE_WRITE | select.KQ_NOTE_RENAME,
        )
        self._kq.control([ev], 0, 0)
        log_event(self.logger, logging.INFO,
                  'kqueue watching inbox directory')

    def _main_loop(self):
        """kqueue event loop with fallback scan."""
        last_scan = time.time()

        while self._running:
            # Wait for kqueue event or fallback timeout
            timeout = max(0, self.config.fallback_interval - (time.time() - last_scan))

            try:
                events = self._kq.control(None, 8, timeout)
            except InterruptedError:
                continue

            if events:
                # kqueue event — inbox changed
                log_event(self.logger, logging.DEBUG,
                          f'kqueue: {len(events)} event(s)')
                self._process_inbox()
                last_scan = time.time()
            elif time.time() - last_scan >= self.config.fallback_interval:
                # Fallback scan
                self._process_inbox()
                last_scan = time.time()

    def _process_inbox(self):
        """Scan inbox, dispatch pending files, and check escalation timeouts."""
        files = scan_inbox(self.config.inbox)

        if files:
            for file_path in files:
                if not self._running:
                    break
                # Verify file still exists (may have been processed by a
                # concurrent dispatch or moved between scan and processing)
                if not file_path.exists():
                    continue
                dispatch_file(
                    file_path, self.config, self.lock,
                    self.rate_limiter, self.logger,
                    processed_ids=self.processed_ids)

        # Check for escalation timeouts (re-reads state before transitioning
        # to avoid TOCTOU race with handle_escalation_response — A1 fix)
        self._check_escalation_timeouts()

    def _check_escalation_timeouts(self):
        """Check for blocked dispatches that have timed out, then run periodic cleanup.

        Creates a DispatchEngine for escalation timeout scanning and dispatch/state
        file cleanup. Errors are logged but never propagate — all operations are best-effort.
        """
        if not self.config.dispatch_dir.exists():
            return

        engine_path = str(self.config.dispatch_engine_path)
        if engine_path not in sys.path:
            sys.path.insert(0, engine_path)

        try:
            from dispatch_engine import DispatchEngine
        except ImportError:
            return

        try:
            engine = DispatchEngine(
                vault_root=str(self.config.vault_root),
                dispatch_dir=str(self.config.dispatch_dir),
                outbox_path=str(self.config.outbox),
                transcripts_path=str(self.config.transcripts_dir),
                alerts_path=str(self.config.alerts_dir),
                inbox_path=str(self.config.inbox),
                processed_ids_path=str(self.config.processed_ids_path),
                claude_bin=self.config.claude_bin,
                log=self.logger,
            )
        except Exception as e:
            log_event(self.logger, logging.ERROR,
                      f'Dispatch engine construction failed: {e}')
            return

        try:
            timed_out = engine.check_escalation_timeouts()
            if timed_out:
                log_event(self.logger, logging.WARNING,
                          f'Escalation timeout: {len(timed_out)} dispatch(es)',
                          extra_fields={'dispatch_ids': timed_out})
        except Exception as e:
            log_event(self.logger, logging.ERROR,
                      f'Escalation timeout check failed: {e}')

        # Periodic cleanup: stage outputs (30 days), state files (30 days)
        # Runs on every cycle — cleanup methods are lightweight (stat-only
        # scan, no file reads unless age threshold met)
        try:
            deleted_outputs = engine.cleanup_stage_outputs()
            if deleted_outputs:
                log_event(self.logger, logging.INFO,
                          f'Cleaned up {deleted_outputs} stage output(s)')

            from dispatch_state import cleanup_terminal_states
            deleted_states = cleanup_terminal_states(self.config.dispatch_dir)
            if deleted_states:
                log_event(self.logger, logging.INFO,
                          f'Cleaned up {deleted_states} terminal state(s)')
        except Exception as e:
            log_event(self.logger, logging.ERROR,
                      f'Dispatch cleanup failed: {e}')

    def _handle_signal(self, signum, frame):
        """Handle SIGTERM/SIGINT for clean shutdown."""
        sig_name = signal.Signals(signum).name
        log_event(self.logger, logging.INFO,
                  f'Received {sig_name}, shutting down')
        self._running = False

    def _cleanup(self):
        """Clean up file descriptors."""
        if self._inbox_fd is not None:
            try:
                os.close(self._inbox_fd)
            except OSError:
                pass
        if self._kq is not None:
            try:
                self._kq.close()
            except OSError:
                pass


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main():
    logger = setup_logging()
    config = Config()

    errors = config.validate()
    if errors:
        for err in errors:
            log_event(logger, logging.ERROR, err)
        sys.exit(1)

    if not config.inbox.is_dir():
        log_event(logger, logging.ERROR,
                  f'Inbox directory inaccessible: {config.inbox}')
        sys.exit(2)

    watcher = BridgeWatcher(config, logger)
    watcher.run()


if __name__ == '__main__':
    main()
