module SPI_Flash_Controller #(
    parameter ADDR_WIDTH = 24
)(
    input clk, rst,
    input start,             // 添加启动信号
    input [7:0] cmd,
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] wr_data,
    output [7:0] rd_data,
    output reg ready,
    // SPI信号
    output sclk, cs_n,
    output mosi,
    input miso
);

reg [3:0] state;
reg [ADDR_WIDTH-1:0] addr_reg;
reg [7:0] cmd_reg;
reg [7:0] shift_reg;
reg [2:0] phase_cnt;
reg [7:0] byte_cnt;         // 添加字节计数器
reg [7:0] data_len;         // 添加数据长度寄存器

localparam IDLE=0, CMD=1, ADDR_PHASE=2, DATA_PHASE=3, DONE=4;

always @(posedge clk) begin
    case(state)
    IDLE: 
        if (start) begin
            cmd_reg <= cmd;
            addr_reg <= addr;
            state <= CMD;
            phase_cnt <= 0;
            byte_cnt <= 0;
            
            // 命令解码逻辑
            case(cmd)
            8'h03: data_len <= 8; // READ
            8'h02: data_len <= 8; // PAGE PROGRAM
            8'h06: data_len <= 0; // WREN
            default: data_len <= 0;
            endcase
        end
    CMD:
        if (phase_cnt == 7) begin
            state <= (cmd_reg[7] ? ADDR_PHASE : DATA_PHASE);
            phase_cnt <= 0;
        end else
            phase_cnt <= phase_cnt + 1;
    ADDR_PHASE: 
        if (phase_cnt == ADDR_WIDTH-1) begin
            state <= DATA_PHASE;
            phase_cnt <= 0;
        end else
            phase_cnt <= phase_cnt + 1;
    DATA_PHASE: 
        if (byte_cnt == data_len) begin
            state <= DONE;
        end else if (phase_cnt == 7) begin
            byte_cnt <= byte_cnt + 1;
            phase_cnt <= 0;
        end else
            phase_cnt <= phase_cnt + 1;
    DONE: 
        state <= IDLE;
    endcase
end

// SPI信号生成
reg sclk_int, cs_n_int;
assign sclk = sclk_int;
assign cs_n = cs_n_int;
assign mosi = shift_reg[7];
assign rd_data = shift_reg;

always @(posedge clk) begin
    if (state == IDLE) begin
        sclk_int <= 1'b0;
        cs_n_int <= 1'b1;
        ready <= 1'b1;
    end else begin
        sclk_int <= ~sclk_int;
        cs_n_int <= 1'b0;
        ready <= 1'b0;
        
        if (!sclk_int) // 在上升沿发送/接收数据
            shift_reg <= {shift_reg[6:0], miso};
    end
end

endmodule