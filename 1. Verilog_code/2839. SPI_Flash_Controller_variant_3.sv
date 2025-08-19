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

// 状态定义
localparam IDLE=4'd0, CMD=4'd1, ADDR_PHASE=4'd2, DATA_PHASE=4'd3, DONE=4'd4;

// 主状态寄存器
reg [3:0] state, next_state;

// 控制相关寄存器
reg [ADDR_WIDTH-1:0] addr_reg;
reg [7:0] cmd_reg;
reg [7:0] shift_reg;
reg [2:0] phase_cnt;
reg [7:0] byte_cnt;
reg [7:0] data_len;

// SPI信号
reg sclk_int;
reg cs_n_int;

// assign输出
assign sclk = sclk_int;
assign cs_n = cs_n_int;
assign mosi = shift_reg[7];
assign rd_data = shift_reg;

// 状态转移逻辑（扁平化if-else结构）
always @(*) begin
    next_state = state;
    if (state == IDLE && start) begin
        next_state = CMD;
    end else if (state == CMD && phase_cnt == 7 && cmd_reg[7]) begin
        next_state = ADDR_PHASE;
    end else if (state == CMD && phase_cnt == 7 && !cmd_reg[7]) begin
        next_state = DATA_PHASE;
    end else if (state == ADDR_PHASE && phase_cnt == ADDR_WIDTH-1) begin
        next_state = DATA_PHASE;
    end else if (state == DATA_PHASE && byte_cnt == data_len) begin
        next_state = DONE;
    end else if (state == DONE) begin
        next_state = IDLE;
    end
end

// 控制寄存器更新
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cmd_reg <= 8'd0;
        addr_reg <= {ADDR_WIDTH{1'b0}};
        data_len <= 8'd0;
    end else if (state == IDLE && start) begin
        cmd_reg <= cmd;
        addr_reg <= addr;
        if (cmd == 8'h03) begin
            data_len <= 8;
        end else if (cmd == 8'h02) begin
            data_len <= 8;
        end else if (cmd == 8'h06) begin
            data_len <= 0;
        end else begin
            data_len <= 0;
        end
    end
end

// phase_cnt控制（扁平化if-else结构）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        phase_cnt <= 3'd0;
    end else if (state == IDLE) begin
        phase_cnt <= 3'd0;
    end else if (state == CMD && phase_cnt == 7) begin
        phase_cnt <= 3'd0;
    end else if (state == CMD && phase_cnt != 7) begin
        phase_cnt <= phase_cnt + 1'b1;
    end else if (state == ADDR_PHASE && phase_cnt == ADDR_WIDTH-1) begin
        phase_cnt <= 3'd0;
    end else if (state == ADDR_PHASE && phase_cnt != ADDR_WIDTH-1) begin
        phase_cnt <= phase_cnt + 1'b1;
    end else if (state == DATA_PHASE && phase_cnt == 7) begin
        phase_cnt <= 3'd0;
    end else if (state == DATA_PHASE && byte_cnt == data_len) begin
        phase_cnt <= 3'd0;
    end else if (state == DATA_PHASE && phase_cnt != 7 && byte_cnt != data_len) begin
        phase_cnt <= phase_cnt + 1'b1;
    end else if (state == DONE) begin
        phase_cnt <= 3'd0;
    end
end

// byte_cnt控制（扁平化if-else结构）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        byte_cnt <= 8'd0;
    end else if (state == IDLE) begin
        byte_cnt <= 8'd0;
    end else if (state == DATA_PHASE && phase_cnt == 7 && byte_cnt != data_len) begin
        byte_cnt <= byte_cnt + 1'b1;
    end else if (state == DATA_PHASE && byte_cnt == data_len) begin
        byte_cnt <= 8'd0;
    end
end

// SPI信号生成（扁平化if-else结构）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        sclk_int <= 1'b0;
        cs_n_int <= 1'b1;
    end else if (state == IDLE) begin
        sclk_int <= 1'b0;
        cs_n_int <= 1'b1;
    end else begin
        sclk_int <= ~sclk_int;
        cs_n_int <= 1'b0;
    end
end

// ready信号生成（扁平化if-else结构）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        ready <= 1'b1;
    end else if (state == IDLE) begin
        ready <= 1'b1;
    end else begin
        ready <= 1'b0;
    end
end

// shift_reg控制（扁平化if-else结构）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        shift_reg <= 8'd0;
    end else if (state != IDLE && !sclk_int) begin
        shift_reg <= {shift_reg[6:0], miso};
    end
end

// 状态寄存器同步
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

endmodule