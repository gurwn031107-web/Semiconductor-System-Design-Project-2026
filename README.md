# Semiconductor System Design Project 2026

온디바이스 AI 반도체 시스템 설계 과정에서 Vivado와 VCS/Verdi로 실습한 RTL 설계, 검증 코드를 정리한 저장소입니다.
Verilog 기초 회로부터 Basys-3 주변장치(UART, FIFO, 센서), RV32I CPU와 APB 버스, SystemVerilog 테스트벤치와 UVM 검증까지 날짜순으로 정리했습니다.

## 구성

| 폴더 | 분야 | 핵심 내용 | 도구 |
|---|---|---|---|
| [`2026_Verilog_Project`](2026_Verilog_Project) | RTL 설계 기초 | 게이트, 가산기, FND, FSM, 스톱워치/시계, UART, FIFO, RAM, 초음파(SR04), 온습도(DHT11) 센서, Basys-3 구현 | Verilog, Vivado, Basys-3 |
| [`2026_System_Verilog_Project`](2026_System_Verilog_Project) | CPU / SoC 설계 | Dedicated CPU, RV32I Single-cycle → Multi-cycle, APB Master + RAM / GPI / GPO / GPIO | SystemVerilog, Vivado, VCS, Verdi |
| [`2026_UVM_Project`](2026_UVM_Project) | 기능 검증 | SV 클래스 테스트벤치, OOP, Adder / Counter / RAM UVM, FIFO 커버리지 | SystemVerilog, UVM 1.2, VCS |

> 이 과정을 바탕으로 한 팀 프로젝트: [RV32I Multi-Cycle CPU + UVM](https://github.com/gurwn031107-web/proj_rv32i_multi_cycle_cpu)

## 2026_Verilog_Project

| 폴더 | 날짜 | 내용 |
|---|---|---|
| `01_gates` | 07/15 | AND, NAND, OR, NOR, XOR 등 기본 게이트, 스위치 → LED 핀 설정 |
| `02_adder` | 07/16 | 반가산기 → 전가산기 → 4비트 / 8비트 가산기 계층 설계 |
| `03_adder_fnd` | 07/21 | 가산 결과를 FND에 표시, 클럭 분주기(`clk_div`) |
| `04_verilog_basics` | 07/21~24 | MUX, blocking / non-blocking 차이, `$display` vs `$strobe` 시뮬레이션 |
| `05_counter_10000` | 07/22~24 | 0~9999 카운터 + 제어 유닛(STOP / RUN / CLEAR / MODE), 버튼 디바운스, FND 표시 |
| `06_fsm` | 07/23~27 | Moore FSM(스위치로 LED 상태 전환), Moore / Mealy 비교, 시퀀스 검출기(Mealy) |
| `07_btn_debounce` | 07/27 | 버튼 디바운스 회로와 테스트벤치 |
| `08_stopwatch` | 07/28 | 스톱워치 (시, 분, 초, 1/100초) |
| `09_stopwatch_watch` | 07/31~08/02 | 스톱워치 + 시계 통합: 제어 유닛, 데이터패스 분리, 버튼 4개, 스위치로 모드 / 시간 설정 |
| `10_uart` | 08/05 | UART 송수신(16배 오버샘플링 baud tick), 루프백, ASCII 명령으로 스톱워치/시계 제어 |
| `11_ram` | 08/10 | 64×8 RAM, 8비트 레지스터, Block Memory Generator IP |
| `12_fifo` | 08/10 | 포인터 기반 FIFO (full / empty 판단) |
| `13_uart_fifo_loopback` | 08/11 | UART RX → FIFO → TX 루프백 |
| `14_sr04_ultrasonic` | 08/12 | HC-SR04 초음파 거리 측정 컨트롤러, FND 표시 |
| `15_dht11` | 08/13 | DHT11 온습도 센서 컨트롤러 (START → WAIT → SYNC → DATA, 체크섬 확인) |
| `16_uart_sensor_mini_project` | 08/17 | **미니 프로젝트**: 스톱워치, 시계, 초음파, 온습도를 하나로 통합, UART ASCII 명령으로 제어하고 측정값 전송 |

## 2026_System_Verilog_Project

| 폴더 | 내용 |
|---|---|
| `01_dedicated_cpu` | 레지스터 파일 + ALU 데이터패스와 FSM 제어기로 구성한 전용 프로세서 |
| `02_dedicated_counter_cpu` | 레지스터, MUX, ALU, 비교기로 0 ~ 10 카운터를 수행하는 전용 프로세서 |
| `03_rv32i_single_cycle` | RV32I 싱글사이클: R / I / S / L / B / U(LUI, AUIPC) / J(JAL, JALR) 명령, WB MUX, ROM 통합 테스트, 점프, U-type 테스트벤치 |
| `04_rv32i_multi_cycle` | 싱글사이클을 멀티사이클로 변환 (`FETCH → DECODE → EXECUTE → MEM → WB`), 자동 검사 테스트벤치, Vivado 프로젝트 생성 Tcl |
| `05_apb_master` | APB Master 단계별 확장: 단일 슬레이브 → 5개 → UART 포함 → 7개 슬레이브 |
| `06_rv32i_multicycle_apb` | 멀티사이클 CPU + APB Master, APB RAM / GPI / GPO / GPIO 슬레이브, R/I-Type UVM 테스트벤치 |

## 2026_UVM_Project

| 폴더 | 날짜 | DUT | 내용 |
|---|---|---|---|
| `01_adder_sv_tb` | 08/18 | 8-bit Adder | SV 클래스 테스트벤치: transaction, generator, driver, monitor, scoreboard, mailbox / event / virtual interface |
| `02_register_sv_tb` | 08/19 | 8-bit Register | 레지스터 랜덤 검증, `fork-join` / `join_any` / `join_none` 실습 |
| `03_hello_uvm` | 08/21 | - | SystemVerilog 클래스, 상속, `super.new()` 기초 |
| `04_sv_oop` | 08/24 | - | OOP 예제 8개: 상속, static 멤버, virtual 함수와 다형성 |
| `05_adder_uvm` | 08/26 | 8-bit Adder | sequence → driver → monitor → scoreboard 기본 UVM 구조, 랜덤 100회 |
| `06_counter_uvm` | 08/26 | 3-bit Counter | enable / reset 시퀀스 분리, tick 출력 검증 |
| `07_ram_uvm` | 08/31 | 256×8 RAM | write / read 랜덤 검증 + `uvm_subscriber` 기능 커버리지, 데이터 값 커버리지 버전 |
| `08_fifo_sv_tb` | 09/05 | 8-bit × 16 FIFO | 클래스 테스트벤치, full / empty 경계, 상태 전이 커버리지 버전 |

## 실행

- **Vivado** (`2026_Verilog_Project`, `03`~`05` SV 프로젝트): 새 프로젝트에 소스, 테스트벤치, `.xdc`를 추가하고 Behavioral Simulation 또는 Basys-3 비트스트림 생성
- **VCS** (Makefile이 있는 폴더):
  ```bash
  make run     # 컴파일
  make simv    # 시뮬레이션
  make verdi   # 파형 확인
  ```

> Vivado 프로젝트 파일(`.xpr`, `.cache`, `.runs`, `.sim`), VCS 빌드 산출물, 수업 배포 자료는 저장소에서 제외하고 직접 작성한 소스만 올렸습니다.
