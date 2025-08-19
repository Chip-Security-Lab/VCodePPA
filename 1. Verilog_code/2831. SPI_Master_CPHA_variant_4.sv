//SystemVerilog
module SPI_Master_CPHA #(
    parameter DATA_WIDTH = 8,
    parameter CLK_DIV = 4
)(
    input clk, rst_n,
    input start,
    input [DATA_WIDTH-1:0] tx_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg busy, done,
    output sclk, mosi,
    input miso,
    output reg cs
);

reg [1:0] cpol_cpha; // [CPOL, CPHA]

// 寄存器定义
reg [3:0] clk_cnt_stage1, clk_cnt_stage2;
reg [DATA_WIDTH-1:0] shift_reg_stage1, shift_reg_stage2;
reg sclk_stage1, sclk_stage2;
reg [$clog2(DATA_WIDTH):0] bit_cnt_stage1, bit_cnt_stage2;
reg [2:0] state_stage1, state_stage2;

reg [DATA_WIDTH-1:0] rx_data_stage2, rx_data_stage3;
reg busy_stage2, busy_stage3;
reg done_stage2, done_stage3;
reg cs_stage2, cs_stage3;

reg b0_stage1, b0_stage2, b0_stage3;
reg b1_stage1, b1_stage2, b1_stage3;

// pipeline for sclk assignment
reg sclk_stage3;

localparam IDLE = 0, PRE_SCLK = 1, SHIFT = 2, POST_SCLK = 3;

// Stage 1: 前半段组合逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage1 <= IDLE;
        clk_cnt_stage1 <= 4'b0;
        shift_reg_stage1 <= 0;
        sclk_stage1 <= 1'b0;
        bit_cnt_stage1 <= 0;
        rx_data_stage2 <= 0;
        busy_stage2 <= 1'b0;
        done_stage2 <= 1'b0;
        cs_stage2 <= 1'b1;
        b0_stage1 <= 1'b0;
        b1_stage1 <= 1'b0;
        cpol_cpha <= 2'b00;
    end else begin
        case(state_stage1)
        IDLE: begin
            if(start) begin
                state_stage1 <= PRE_SCLK;
                shift_reg_stage1 <= tx_data;
                busy_stage2 <= 1'b1;
                cs_stage2 <= 1'b0;
                clk_cnt_stage1 <= 0;
                bit_cnt_stage1 <= 0;
                b0_stage1 <= 1'b0;
                b1_stage1 <= 1'b0;
            end
            done_stage2 <= 1'b0;
        end
        PRE_SCLK: begin
            if(clk_cnt_stage1 == CLK_DIV/2) begin
                state_stage1 <= SHIFT;
                clk_cnt_stage1 <= 0;
                sclk_stage1 <= ~sclk_stage1;
            end else begin
                clk_cnt_stage1 <= clk_cnt_stage1 + 1;
            end
        end
        SHIFT: begin
            if(clk_cnt_stage1 == CLK_DIV/2) begin
                clk_cnt_stage1 <= 0;
                sclk_stage1 <= ~sclk_stage1;

                if(!sclk_stage1) begin // 上升沿采样
                    shift_reg_stage1 <= {shift_reg_stage1[DATA_WIDTH-2:0], miso};
                end

                if(bit_cnt_stage1 == DATA_WIDTH && !sclk_stage1) begin
                    state_stage1 <= POST_SCLK;
                    rx_data_stage2 <= {shift_reg_stage1[DATA_WIDTH-2:0], miso};
                end else if(!sclk_stage1) begin
                    bit_cnt_stage1 <= bit_cnt_stage1 + 1;
                end

                b0_stage1 <= shift_reg_stage1[DATA_WIDTH-1];
                b1_stage1 <= shift_reg_stage1[0];
            end else begin
                clk_cnt_stage1 <= clk_cnt_stage1 + 1;
            end
        end
        POST_SCLK: begin
            cs_stage2 <= 1'b1;
            busy_stage2 <= 1'b0;
            done_stage2 <= 1'b1;
            state_stage1 <= IDLE;
            b0_stage1 <= 1'b0;
            b1_stage1 <= 1'b0;
        end
        endcase
    end
end

// Stage 2: pipeline registers (关键路径切割1)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage2 <= IDLE;
        clk_cnt_stage2 <= 4'b0;
        shift_reg_stage2 <= {DATA_WIDTH{1'b0}};
        sclk_stage2 <= 1'b0;
        bit_cnt_stage2 <= 0;
        rx_data_stage3 <= 0;
        busy_stage3 <= 1'b0;
        done_stage3 <= 1'b0;
        cs_stage3 <= 1'b1;
        b0_stage2 <= 1'b0;
        b1_stage2 <= 1'b0;
    end else begin
        state_stage2 <= state_stage1;
        clk_cnt_stage2 <= clk_cnt_stage1;
        shift_reg_stage2 <= shift_reg_stage1;
        sclk_stage2 <= sclk_stage1;
        bit_cnt_stage2 <= bit_cnt_stage1;
        rx_data_stage3 <= rx_data_stage2;
        busy_stage3 <= busy_stage2;
        done_stage3 <= done_stage2;
        cs_stage3 <= cs_stage2;
        b0_stage2 <= b0_stage1;
        b1_stage2 <= b1_stage1;
    end
end

// Stage 3: pipeline registers (关键路径切割2)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data <= 0;
        busy <= 1'b0;
        done <= 1'b0;
        cs <= 1'b1;
        b0_stage3 <= 1'b0;
        b1_stage3 <= 1'b0;
        sclk_stage3 <= 1'b0;
    end else begin
        rx_data <= rx_data_stage3;
        busy <= busy_stage3;
        done <= done_stage3;
        cs <= cs_stage3;
        b0_stage3 <= b0_stage2;
        b1_stage3 <= b1_stage2;
        sclk_stage3 <= sclk_stage2;
    end
end

assign mosi = shift_reg_stage2[DATA_WIDTH-1];
assign sclk = (cpol_cpha[0] & (state_stage2 == SHIFT)) ? sclk_stage3 : cpol_cpha[1];

// 可选：将b0_stage3, b1_stage3暴露端口，若需用作其他模块输入
// assign b0_out = b0_stage3;
// assign b1_out = b1_stage3;

endmodule