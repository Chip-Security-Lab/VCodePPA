//SystemVerilog
module SPI_Flash_Controller #(
    parameter ADDR_WIDTH = 24
)(
    input clk, rst,
    input start,
    input [7:0] cmd,
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] wr_data,
    output [7:0] rd_data,
    output reg ready,
    output sclk, cs_n,
    output mosi,
    input miso
);

// 状态机相关寄存器
reg [2:0] state, state_d1;
reg [ADDR_WIDTH-1:0] addr_reg, addr_reg_d1;
reg [7:0] cmd_reg, cmd_reg_d1;
reg [7:0] shift_reg, shift_reg_d1, shift_reg_d2;
reg [2:0] phase_cnt, phase_cnt_d1;
reg [7:0] byte_cnt, byte_cnt_d1;
reg [7:0] data_len, data_len_d1;

// SPI信号寄存器
reg sclk_int, sclk_int_d1;
reg cs_n_int, cs_n_int_d1;

// 输出assign
assign sclk = sclk_int_d1;
assign cs_n = cs_n_int_d1;
assign mosi = shift_reg_d2[7];
assign rd_data = shift_reg_d2;

// 状态编码
localparam IDLE      = 3'd0;
localparam CMD       = 3'd1;
localparam ADDR_PHASE= 3'd2;
localparam DATA_PHASE= 3'd3;
localparam DONE      = 3'd4;

// 优化命令类型判断
wire is_read_cmd     = (cmd == 8'h03);
wire is_page_prog    = (cmd == 8'h02);
wire is_wren_cmd     = (cmd == 8'h06);

// 命令需要地址的判定
wire cmd_has_addr    = is_read_cmd | is_page_prog;

// --- 第一阶段流水线（命令解析与状态转移） ---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state      <= IDLE;
        addr_reg   <= {ADDR_WIDTH{1'b0}};
        cmd_reg    <= 8'd0;
        phase_cnt  <= 3'd0;
        byte_cnt   <= 8'd0;
        data_len   <= 8'd0;
    end else begin
        case(state)
        IDLE: begin
            if (start) begin
                cmd_reg   <= cmd;
                addr_reg  <= addr;
                state     <= CMD;
                phase_cnt <= 3'd0;
                byte_cnt  <= 8'd0;
                // 命令解码优化
                data_len  <= (is_read_cmd | is_page_prog) ? 8'd8 :
                             (is_wren_cmd)               ? 8'd0 : 8'd0;
            end
        end
        CMD: begin
            if (phase_cnt == 3'd7) begin
                state     <= cmd_has_addr ? ADDR_PHASE : DATA_PHASE;
                phase_cnt <= 3'd0;
            end else begin
                phase_cnt <= phase_cnt + 1'b1;
            end
        end
        ADDR_PHASE: begin
            if (phase_cnt == (ADDR_WIDTH[2:0]-1)) begin
                state     <= DATA_PHASE;
                phase_cnt <= 3'd0;
            end else begin
                phase_cnt <= phase_cnt + 1'b1;
            end
        end
        DATA_PHASE: begin
            if (byte_cnt == data_len) begin
                state <= DONE;
            end else if (phase_cnt == 3'd7) begin
                byte_cnt  <= byte_cnt + 1'b1;
                phase_cnt <= 3'd0;
            end else begin
                phase_cnt <= phase_cnt + 1'b1;
            end
        end
        DONE: begin
            state <= IDLE;
        end
        default: state <= IDLE;
        endcase
    end
end

// --- 第二阶段流水线（状态、命令、地址、计数等寄存器） ---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state_d1     <= IDLE;
        addr_reg_d1  <= {ADDR_WIDTH{1'b0}};
        cmd_reg_d1   <= 8'd0;
        phase_cnt_d1 <= 3'd0;
        byte_cnt_d1  <= 8'd0;
        data_len_d1  <= 8'd0;
    end else begin
        state_d1     <= state;
        addr_reg_d1  <= addr_reg;
        cmd_reg_d1   <= cmd_reg;
        phase_cnt_d1 <= phase_cnt;
        byte_cnt_d1  <= byte_cnt;
        data_len_d1  <= data_len;
    end
end

// --- SPI信号生成与数据移位 ---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        sclk_int    <= 1'b0;
        cs_n_int    <= 1'b1;
        shift_reg   <= 8'd0;
        ready       <= 1'b1;
    end else begin
        if (state == IDLE) begin
            sclk_int  <= 1'b0;
            cs_n_int  <= 1'b1;
            ready     <= 1'b1;
            shift_reg <= 8'd0;
        end else begin
            sclk_int  <= ~sclk_int;
            cs_n_int  <= 1'b0;
            ready     <= 1'b0;
            if (!sclk_int)
                shift_reg <= {shift_reg[6:0], miso};
        end
    end
end

// --- SPI信号第二级流水线寄存器 ---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        sclk_int_d1   <= 1'b0;
        cs_n_int_d1   <= 1'b1;
        shift_reg_d1  <= 8'd0;
    end else begin
        sclk_int_d1   <= sclk_int;
        cs_n_int_d1   <= cs_n_int;
        shift_reg_d1  <= shift_reg;
    end
end

// --- SPI信号第三级流水线寄存器（用于rd_data和mosi输出切割）---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        shift_reg_d2 <= 8'd0;
    end else begin
        shift_reg_d2 <= shift_reg_d1;
    end
end

endmodule