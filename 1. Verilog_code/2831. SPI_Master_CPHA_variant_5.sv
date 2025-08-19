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
reg [3:0] clk_cnt;
reg [2:0] state;
reg sclk_int;
reg [$clog2(DATA_WIDTH):0] bit_cnt;

reg [DATA_WIDTH-1:0] tx_data_d;
reg start_d;

reg [DATA_WIDTH-1:0] shift_reg;

localparam IDLE = 0, PRE_SCLK = 1, SHIFT = 2, POST_SCLK = 3;

// 前向寄存器重定时：将输入tx_data和start的寄存器延后到组合逻辑之后

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_d <= 1'b0;
        tx_data_d <= {DATA_WIDTH{1'b0}};
    end else begin
        start_d <= start;
        tx_data_d <= tx_data;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        busy <= 1'b0;
        done <= 1'b0;
        cs <= 1'b1;
        sclk_int <= 1'b0;
        clk_cnt <= 4'b0;
        bit_cnt <= 0;
        shift_reg <= 0;
        rx_data <= 0;
        cpol_cpha <= 2'b00;
    end else begin
        case(state)
        IDLE: begin
            done <= 1'b0;
            if(start_d) begin
                state <= PRE_SCLK;
                shift_reg <= tx_data_d;
                busy <= 1'b1;
                cs <= 1'b0;
                clk_cnt <= 0;
                bit_cnt <= 0;
            end
        end
        PRE_SCLK: begin
            if(clk_cnt == CLK_DIV/2) begin
                state <= SHIFT;
                clk_cnt <= 0;
                sclk_int <= ~sclk_int;
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end
        SHIFT: begin
            if(clk_cnt == CLK_DIV/2) begin
                clk_cnt <= 0;
                sclk_int <= ~sclk_int;
                
                if(!sclk_int) begin // 在上升沿采样
                    shift_reg <= {shift_reg[DATA_WIDTH-2:0], miso};
                end
                
                if(bit_cnt == DATA_WIDTH && !sclk_int) begin
                    state <= POST_SCLK;
                    rx_data <= {shift_reg[DATA_WIDTH-2:0], miso};
                end else if(!sclk_int) begin
                    bit_cnt <= bit_cnt + 1;
                end
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end
        POST_SCLK: begin
            cs <= 1'b1;
            busy <= 1'b0;
            done <= 1'b1;
            state <= IDLE;
        end
        endcase
    end
end

assign mosi = shift_reg[DATA_WIDTH-1];
assign sclk = (cpol_cpha[0] & (state == SHIFT)) ? sclk_int : cpol_cpha[1];

endmodule