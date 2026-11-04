# 🔬 Semiconductor System Design Project 2026

온디바이스 AI 반도체 시스템 설계 과정에서 실습한 코드를 **분야별로 정리한 저장소**입니다.
Linux 서버(MobaXterm 접속)에서 Synopsys VCS / Verdi로 진행한 **RTL 설계 · 검증 실습**으로, Datapath + FSM 기반 전용 프로세서에서 시작해 **RV32I CPU + APB 버스**, **UVM 검증 환경**까지 단계별로 진행했습니다.

<br>

## 📁 구성

| 폴더 | 분야 | 핵심 내용 | 도구 |
|---|---|---|---|
| [`2026_System_Verilog_Project`](2026_System_Verilog_Project) | CPU / SoC 설계 | Dedicated CPU, RV32I Multi-cycle CPU, APB Master + RAM/GPI/GPO/GPIO | SystemVerilog, VCS, Verdi |
| [`2026_UVM_Project`](2026_UVM_Project) | 기능 검증 | SV 클래스 기초, Adder/Counter/RAM UVM, FIFO 랜덤 테스트벤치 + 커버리지 | SystemVerilog, UVM 1.2, VCS |

<br>

## 🖥️ 2026_System_Verilog_Project

| 폴더 | 내용 |
|---|---|
| `01_dedicated_cpu` | 레지스터 파일 + ALU 데이터패스와 FSM 제어기로 구성한 전용 프로세서 (조건 `< 10` 반복 연산) |
| `02_dedicated_counter_cpu` | 레지스터·MUX·ALU·비교기로 0 ~ 10 카운터를 수행하는 전용 프로세서 |
| `03_rv32i_multicycle_apb` | RV32I 멀티사이클 CPU (`FETCH → DECODE → EXECUTE → MEMORY → WB`) + APB Master, APB RAM / GPI / GPO / GPIO 슬레이브, R/I-Type UVM 테스트벤치 |

> 팀 프로젝트로 확장한 버전 → [proj_rv32i_multi_cycle_cpu](https://github.com/gurwn031107-web/proj_rv32i_multi_cycle_cpu)

<br>

## ✅ 2026_UVM_Project

| 폴더 | DUT | 검증 내용 |
|---|---|---|
| `01_hello_uvm` | - | SystemVerilog 클래스, 상속, `super.new()` 기초 |
| `02_adder_uvm` | 8-bit Adder | sequence → driver → monitor → scoreboard 기본 UVM 구조, 랜덤 100회 |
| `03_counter_uvm` | 3-bit Counter | enable/reset 시퀀스 분리, tick 출력 검증 |
| `04_ram_uvm` | 256×8 RAM | write/read 랜덤 검증 + `uvm_subscriber` 기반 기능 커버리지 |
| `05_fifo_sv_tb` | 8-bit × 16 FIFO | generator/driver/monitor/scoreboard 클래스 테스트벤치, full/empty 경계·상태 전이 커버리지 |

<br>

## ▶️ 시뮬레이션 실행 (Synopsys VCS)

각 폴더에서:

```bash
make run     # 컴파일
make simv    # 시뮬레이션
make verdi   # 파형 확인
```

> 빌드 산출물(`build/`, `csrc/`, `*.fsdb`, `coverage.vdb` 등)과 수업 배포 자료는 저장소에서 제외했습니다.
