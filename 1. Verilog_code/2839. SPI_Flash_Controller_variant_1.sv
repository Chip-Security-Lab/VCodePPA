//SystemVerilog
// Top-level SPI Flash Controller with deeper pipelining for higher frequency

module SPI_Flash_Controller #(
    parameter ADDR_WIDTH = 24
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  start,
    input  wire [7:0]            cmd,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [7:0]            wr_data,
    output wire [7:0]            rd_data,
    output wire                  ready,
    output wire                  sclk,
    output wire                  cs_n,
    output wire                  mosi,
    input  wire                  miso
);

    // Internal pipelined signals (now 4 stages)
    wire [3:0]            state_stage1, state_stage2, state_stage3, state_stage4;
    wire [ADDR_WIDTH-1:0] addr_reg_stage1, addr_reg_stage2, addr_reg_stage3, addr_reg_stage4;
    wire [7:0]            cmd_reg_stage1, cmd_reg_stage2, cmd_reg_stage3, cmd_reg_stage4;
    wire [7:0]            shift_reg_stage1, shift_reg_stage2, shift_reg_stage3, shift_reg_stage4;
    wire [2:0]            phase_cnt_stage1, phase_cnt_stage2, phase_cnt_stage3, phase_cnt_stage4;
    wire [7:0]            byte_cnt_stage1, byte_cnt_stage2, byte_cnt_stage3, byte_cnt_stage4;
    wire [7:0]            data_len_stage1, data_len_stage2, data_len_stage3, data_len_stage4;
    wire                  sclk_int_stage1, sclk_int_stage2, sclk_int_stage3, sclk_int_stage4;
    wire                  cs_n_int_stage1, cs_n_int_stage2, cs_n_int_stage3, cs_n_int_stage4;
    wire                  ready_int;
    wire [7:0]            rd_data_stage4;

    // FSM and Pipeline Control (deeper pipeline)
    SPI_Flash_FSM #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_fsm (
        .clk                   (clk),
        .rst                   (rst),
        .start                 (start),
        .cmd                   (cmd),
        .addr                  (addr),
        .wr_data               (wr_data),
        .miso                  (miso),
        .state_stage1          (state_stage1),
        .state_stage2          (state_stage2),
        .state_stage3          (state_stage3),
        .state_stage4          (state_stage4),
        .cmd_reg_stage1        (cmd_reg_stage1),
        .cmd_reg_stage2        (cmd_reg_stage2),
        .cmd_reg_stage3        (cmd_reg_stage3),
        .cmd_reg_stage4        (cmd_reg_stage4),
        .addr_reg_stage1       (addr_reg_stage1),
        .addr_reg_stage2       (addr_reg_stage2),
        .addr_reg_stage3       (addr_reg_stage3),
        .addr_reg_stage4       (addr_reg_stage4),
        .shift_reg_stage1      (shift_reg_stage1),
        .shift_reg_stage2      (shift_reg_stage2),
        .shift_reg_stage3      (shift_reg_stage3),
        .shift_reg_stage4      (shift_reg_stage4),
        .phase_cnt_stage1      (phase_cnt_stage1),
        .phase_cnt_stage2      (phase_cnt_stage2),
        .phase_cnt_stage3      (phase_cnt_stage3),
        .phase_cnt_stage4      (phase_cnt_stage4),
        .byte_cnt_stage1       (byte_cnt_stage1),
        .byte_cnt_stage2       (byte_cnt_stage2),
        .byte_cnt_stage3       (byte_cnt_stage3),
        .byte_cnt_stage4       (byte_cnt_stage4),
        .data_len_stage1       (data_len_stage1),
        .data_len_stage2       (data_len_stage2),
        .data_len_stage3       (data_len_stage3),
        .data_len_stage4       (data_len_stage4),
        .sclk_int_stage1       (sclk_int_stage1),
        .sclk_int_stage2       (sclk_int_stage2),
        .sclk_int_stage3       (sclk_int_stage3),
        .sclk_int_stage4       (sclk_int_stage4),
        .cs_n_int_stage1       (cs_n_int_stage1),
        .cs_n_int_stage2       (cs_n_int_stage2),
        .cs_n_int_stage3       (cs_n_int_stage3),
        .cs_n_int_stage4       (cs_n_int_stage4),
        .ready                 (ready_int),
        .rd_data_stage4        (rd_data_stage4)
    );

    // SPI Output Interface (now connected to stage4)
    SPI_Flash_Output u_output (
        .shift_reg_stage4      (shift_reg_stage4),
        .sclk_int_stage4       (sclk_int_stage4),
        .cs_n_int_stage4       (cs_n_int_stage4),
        .rd_data_stage4        (rd_data_stage4),
        .mosi                  (mosi),
        .sclk                  (sclk),
        .cs_n                  (cs_n),
        .rd_data               (rd_data)
    );

    // Ready Signal Assign
    assign ready = ready_int;

endmodule

// =======================================================================
// 子模块1：SPI_Flash_FSM
// 功能：实现SPI Flash控制器的主状态机、加深流水线结构
// =======================================================================
module SPI_Flash_FSM #(
    parameter ADDR_WIDTH = 24
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  start,
    input  wire [7:0]            cmd,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [7:0]            wr_data,
    input  wire                  miso,

    output reg  [3:0]            state_stage1,
    output reg  [3:0]            state_stage2,
    output reg  [3:0]            state_stage3,
    output reg  [3:0]            state_stage4,
    output reg  [7:0]            cmd_reg_stage1,
    output reg  [7:0]            cmd_reg_stage2,
    output reg  [7:0]            cmd_reg_stage3,
    output reg  [7:0]            cmd_reg_stage4,
    output reg  [ADDR_WIDTH-1:0] addr_reg_stage1,
    output reg  [ADDR_WIDTH-1:0] addr_reg_stage2,
    output reg  [ADDR_WIDTH-1:0] addr_reg_stage3,
    output reg  [ADDR_WIDTH-1:0] addr_reg_stage4,
    output reg  [7:0]            shift_reg_stage1,
    output reg  [7:0]            shift_reg_stage2,
    output reg  [7:0]            shift_reg_stage3,
    output reg  [7:0]            shift_reg_stage4,
    output reg  [2:0]            phase_cnt_stage1,
    output reg  [2:0]            phase_cnt_stage2,
    output reg  [2:0]            phase_cnt_stage3,
    output reg  [2:0]            phase_cnt_stage4,
    output reg  [7:0]            byte_cnt_stage1,
    output reg  [7:0]            byte_cnt_stage2,
    output reg  [7:0]            byte_cnt_stage3,
    output reg  [7:0]            byte_cnt_stage4,
    output reg  [7:0]            data_len_stage1,
    output reg  [7:0]            data_len_stage2,
    output reg  [7:0]            data_len_stage3,
    output reg  [7:0]            data_len_stage4,
    output reg                   sclk_int_stage1,
    output reg                   sclk_int_stage2,
    output reg                   sclk_int_stage3,
    output reg                   sclk_int_stage4,
    output reg                   cs_n_int_stage1,
    output reg                   cs_n_int_stage2,
    output reg                   cs_n_int_stage3,
    output reg                   cs_n_int_stage4,
    output reg                   ready,
    output reg  [7:0]            rd_data_stage4
);

    // 状态机状态定义
    localparam IDLE        = 4'd0,
               CMD_STAGE1  = 4'd1,
               CMD_STAGE2  = 4'd2,
               ADDR_STAGE1 = 4'd3,
               ADDR_STAGE2 = 4'd4,
               DATA_STAGE1 = 4'd5,
               DATA_STAGE2 = 4'd6,
               DONE        = 4'd7;

    // Stage 1: 控制主状态
    reg [3:0]    next_state_stage1;
    reg [7:0]    next_cmd_reg_stage1;
    reg [ADDR_WIDTH-1:0] next_addr_reg_stage1;
    reg [7:0]    next_shift_reg_stage1;
    reg [2:0]    next_phase_cnt_stage1;
    reg [7:0]    next_byte_cnt_stage1;
    reg [7:0]    next_data_len_stage1;
    reg          next_sclk_int_stage1;
    reg          next_cs_n_int_stage1;
    reg          next_ready;

    always @(*) begin
        // Default assignments
        next_state_stage1      = state_stage1;
        next_cmd_reg_stage1    = cmd_reg_stage1;
        next_addr_reg_stage1   = addr_reg_stage1;
        next_shift_reg_stage1  = shift_reg_stage1;
        next_phase_cnt_stage1  = phase_cnt_stage1;
        next_byte_cnt_stage1   = byte_cnt_stage1;
        next_data_len_stage1   = data_len_stage1;
        next_sclk_int_stage1   = sclk_int_stage1;
        next_cs_n_int_stage1   = cs_n_int_stage1;
        next_ready             = ready;
        case (state_stage1)
            IDLE: begin
                if (start) begin
                    next_cmd_reg_stage1   = cmd;
                    next_addr_reg_stage1  = addr;
                    next_state_stage1     = CMD_STAGE1;
                    next_phase_cnt_stage1 = 3'd0;
                    next_byte_cnt_stage1  = 8'd0;
                    // 命令解码
                    case (cmd)
                        8'h03: next_data_len_stage1 = 8; // READ
                        8'h02: next_data_len_stage1 = 8; // PAGE PROGRAM
                        8'h06: next_data_len_stage1 = 0; // WREN
                        default: next_data_len_stage1 = 0;
                    endcase
                    next_shift_reg_stage1 = cmd;
                    next_sclk_int_stage1  = 1'b0;
                    next_cs_n_int_stage1  = 1'b0;
                    next_ready            = 1'b0;
                end else begin
                    next_sclk_int_stage1  = 1'b0;
                    next_cs_n_int_stage1  = 1'b1;
                    next_ready            = 1'b1;
                end
            end
            CMD_STAGE1: begin
                if (phase_cnt_stage1 == 3'd7) begin
                    next_state_stage1     = CMD_STAGE2;
                    next_phase_cnt_stage1 = 3'd0;
                end else begin
                    next_phase_cnt_stage1 = phase_cnt_stage1 + 1'b1;
                end
                next_sclk_int_stage1 = ~sclk_int_stage1;
                next_cs_n_int_stage1 = 1'b0;
                next_ready           = 1'b0;
            end
            CMD_STAGE2: begin
                if (cmd_reg_stage1[7])
                    next_state_stage1 = ADDR_STAGE1;
                else
                    next_state_stage1 = DATA_STAGE1;
                next_shift_reg_stage1 = addr_reg_stage1[ADDR_WIDTH-1 -: 8];
                next_phase_cnt_stage1 = 3'd0;
                next_sclk_int_stage1  = ~sclk_int_stage1;
                next_cs_n_int_stage1  = 1'b0;
                next_ready            = 1'b0;
            end
            ADDR_STAGE1: begin
                if (phase_cnt_stage1 == 3'd7) begin
                    next_state_stage1     = ADDR_STAGE2;
                    next_phase_cnt_stage1 = 3'd0;
                end else begin
                    next_phase_cnt_stage1 = phase_cnt_stage1 + 1'b1;
                end
                next_sclk_int_stage1 = ~sclk_int_stage1;
                next_cs_n_int_stage1 = 1'b0;
                next_ready           = 1'b0;
            end
            ADDR_STAGE2: begin
                if (phase_cnt_stage1 == ((ADDR_WIDTH/8)-1)) begin
                    next_state_stage1     = DATA_STAGE1;
                    next_phase_cnt_stage1 = 3'd0;
                    next_shift_reg_stage1 = wr_data;
                end else begin
                    next_phase_cnt_stage1 = phase_cnt_stage1 + 1'b1;
                    next_shift_reg_stage1 = addr_reg_stage1[ADDR_WIDTH-1 - (phase_cnt_stage1+1)*8 -: 8];
                end
                next_sclk_int_stage1 = ~sclk_int_stage1;
                next_cs_n_int_stage1 = 1'b0;
                next_ready           = 1'b0;
            end
            DATA_STAGE1: begin
                if (phase_cnt_stage1 == 3'd7) begin
                    next_state_stage1     = DATA_STAGE2;
                    next_phase_cnt_stage1 = 3'd0;
                end else begin
                    next_phase_cnt_stage1 = phase_cnt_stage1 + 1'b1;
                end
                next_sclk_int_stage1 = ~sclk_int_stage1;
                next_cs_n_int_stage1 = 1'b0;
                next_ready           = 1'b0;
            end
            DATA_STAGE2: begin
                if (byte_cnt_stage1 == data_len_stage1) begin
                    next_state_stage1 = DONE;
                end else begin
                    next_byte_cnt_stage1 = byte_cnt_stage1 + 1'b1;
                    next_state_stage1    = DATA_STAGE1;
                end
                next_sclk_int_stage1 = ~sclk_int_stage1;
                next_cs_n_int_stage1 = 1'b0;
                next_ready           = 1'b0;
            end
            DONE: begin
                next_state_stage1 = IDLE;
                next_sclk_int_stage1 = 1'b0;
                next_cs_n_int_stage1 = 1'b1;
                next_ready           = 1'b1;
            end
            default: begin
                next_state_stage1 = IDLE;
                next_sclk_int_stage1 = 1'b0;
                next_cs_n_int_stage1 = 1'b1;
                next_ready           = 1'b1;
            end
        endcase
    end

    // Stage 1 Registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage1       <= IDLE;
            cmd_reg_stage1     <= 8'd0;
            addr_reg_stage1    <= {ADDR_WIDTH{1'b0}};
            shift_reg_stage1   <= 8'd0;
            phase_cnt_stage1   <= 3'd0;
            byte_cnt_stage1    <= 8'd0;
            data_len_stage1    <= 8'd0;
            sclk_int_stage1    <= 1'b0;
            cs_n_int_stage1    <= 1'b1;
            ready              <= 1'b1;
        end else begin
            state_stage1       <= next_state_stage1;
            cmd_reg_stage1     <= next_cmd_reg_stage1;
            addr_reg_stage1    <= next_addr_reg_stage1;
            shift_reg_stage1   <= next_shift_reg_stage1;
            phase_cnt_stage1   <= next_phase_cnt_stage1;
            byte_cnt_stage1    <= next_byte_cnt_stage1;
            data_len_stage1    <= next_data_len_stage1;
            sclk_int_stage1    <= next_sclk_int_stage1;
            cs_n_int_stage1    <= next_cs_n_int_stage1;
            ready              <= next_ready;
        end
    end

    // Stage 2: SPI Shift Register (bit-shift & MISO sample, separated for pipelining)
    reg [7:0] shift_reg_stage2_next;
    always @(*) begin
        shift_reg_stage2_next = shift_reg_stage1;
        if (state_stage1 != IDLE && ~sclk_int_stage1) begin
            shift_reg_stage2_next = {shift_reg_stage1[6:0], miso};
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage2        <= IDLE;
            cmd_reg_stage2      <= 8'd0;
            addr_reg_stage2     <= {ADDR_WIDTH{1'b0}};
            shift_reg_stage2    <= 8'd0;
            phase_cnt_stage2    <= 3'd0;
            byte_cnt_stage2     <= 8'd0;
            data_len_stage2     <= 8'd0;
            sclk_int_stage2     <= 1'b0;
            cs_n_int_stage2     <= 1'b1;
        end else begin
            state_stage2        <= state_stage1;
            cmd_reg_stage2      <= cmd_reg_stage1;
            addr_reg_stage2     <= addr_reg_stage1;
            shift_reg_stage2    <= shift_reg_stage2_next;
            phase_cnt_stage2    <= phase_cnt_stage1;
            byte_cnt_stage2     <= byte_cnt_stage1;
            data_len_stage2     <= data_len_stage1;
            sclk_int_stage2     <= sclk_int_stage1;
            cs_n_int_stage2     <= cs_n_int_stage1;
        end
    end

    // Stage 3: Address/Phase/Byte/Shift pipeline registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage3        <= IDLE;
            cmd_reg_stage3      <= 8'd0;
            addr_reg_stage3     <= {ADDR_WIDTH{1'b0}};
            shift_reg_stage3    <= 8'd0;
            phase_cnt_stage3    <= 3'd0;
            byte_cnt_stage3     <= 8'd0;
            data_len_stage3     <= 8'd0;
            sclk_int_stage3     <= 1'b0;
            cs_n_int_stage3     <= 1'b1;
        end else begin
            state_stage3        <= state_stage2;
            cmd_reg_stage3      <= cmd_reg_stage2;
            addr_reg_stage3     <= addr_reg_stage2;
            shift_reg_stage3    <= shift_reg_stage2;
            phase_cnt_stage3    <= phase_cnt_stage2;
            byte_cnt_stage3     <= byte_cnt_stage2;
            data_len_stage3     <= data_len_stage2;
            sclk_int_stage3     <= sclk_int_stage2;
            cs_n_int_stage3     <= cs_n_int_stage2;
        end
    end

    // Stage 4: Output and data latch
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage4        <= IDLE;
            cmd_reg_stage4      <= 8'd0;
            addr_reg_stage4     <= {ADDR_WIDTH{1'b0}};
            shift_reg_stage4    <= 8'd0;
            phase_cnt_stage4    <= 3'd0;
            byte_cnt_stage4     <= 8'd0;
            data_len_stage4     <= 8'd0;
            sclk_int_stage4     <= 1'b0;
            cs_n_int_stage4     <= 1'b1;
            rd_data_stage4      <= 8'd0;
        end else begin
            state_stage4        <= state_stage3;
            cmd_reg_stage4      <= cmd_reg_stage3;
            addr_reg_stage4     <= addr_reg_stage3;
            shift_reg_stage4    <= shift_reg_stage3;
            phase_cnt_stage4    <= phase_cnt_stage3;
            byte_cnt_stage4     <= byte_cnt_stage3;
            data_len_stage4     <= data_len_stage3;
            sclk_int_stage4     <= sclk_int_stage3;
            cs_n_int_stage4     <= cs_n_int_stage3;
            // latch output only in DATA_STAGE2 or DONE
            if (state_stage3 == DATA_STAGE2)
                rd_data_stage4  <= shift_reg_stage3;
            else if (state_stage3 == DONE)
                rd_data_stage4  <= shift_reg_stage3;
        end
    end

endmodule

// =======================================================================
// 子模块2：SPI_Flash_Output
// 功能：将SPI信号和输出数据进行最后一级寄存和分发
// =======================================================================
module SPI_Flash_Output (
    input  wire [7:0] shift_reg_stage4,
    input  wire       sclk_int_stage4,
    input  wire       cs_n_int_stage4,
    input  wire [7:0] rd_data_stage4,
    output wire       mosi,
    output wire       sclk,
    output wire       cs_n,
    output wire [7:0] rd_data
);
    // MOSI为最高位，SCLK/CS_N为寄存后的信号
    assign mosi    = shift_reg_stage4[7];
    assign sclk    = sclk_int_stage4;
    assign cs_n    = cs_n_int_stage4;
    assign rd_data = rd_data_stage4;
endmodule