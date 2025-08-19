//SystemVerilog
module SPI_Master_CPHA #(
    parameter DATA_WIDTH = 8,
    parameter CLK_DIV = 4
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [DATA_WIDTH-1:0] tx_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg busy,
    output reg done,
    output wire sclk,
    output wire mosi,
    input wire miso,
    output reg cs
);

reg [1:0] cpol_cpha;
reg [3:0] clk_cnt;
reg [DATA_WIDTH-1:0] shift_reg;
reg [2:0] fsm_state;
reg sclk_int;
reg [$clog2(DATA_WIDTH):0] bit_cnt;

localparam IDLE = 3'd0;
localparam PRE_SCLK = 3'd1;
localparam SHIFT = 3'd2;
localparam POST_SCLK = 3'd3;

// 中间条件变量
wire start_condition;
wire pre_sclk_condition;
wire shift_to_post_condition;
wire shift_bit_count_reached;
wire clk_cnt_half;
wire fsm_idle;
wire fsm_post_sclk;
wire fsm_pre_sclk;
wire fsm_shift;

assign start_condition = (fsm_state == IDLE) && start;
assign pre_sclk_condition = (fsm_state == PRE_SCLK);
assign shift_to_post_condition = (fsm_state == SHIFT);
assign shift_bit_count_reached = (bit_cnt == DATA_WIDTH);
assign clk_cnt_half = (clk_cnt == CLK_DIV/2);
assign fsm_idle = (fsm_state == IDLE);
assign fsm_post_sclk = (fsm_state == POST_SCLK);
assign fsm_pre_sclk = (fsm_state == PRE_SCLK);
assign fsm_shift = (fsm_state == SHIFT);

// FSM state register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fsm_state <= IDLE;
    end else begin
        if (fsm_state == IDLE) begin
            if (start)
                fsm_state <= PRE_SCLK;
        end else if (fsm_state == PRE_SCLK) begin
            if (clk_cnt_half)
                fsm_state <= SHIFT;
        end else if (fsm_state == SHIFT) begin
            if (shift_bit_count_reached && clk_cnt_half && !sclk_int)
                fsm_state <= POST_SCLK;
        end else if (fsm_state == POST_SCLK) begin
            fsm_state <= IDLE;
        end
    end
end

// Busy signal control
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        busy <= 1'b0;
    end else begin
        if (start_condition)
            busy <= 1'b1;
        else if (fsm_post_sclk)
            busy <= 1'b0;
    end
end

// Done signal control
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        done <= 1'b0;
    end else begin
        if (fsm_post_sclk)
            done <= 1'b1;
        else if (fsm_idle)
            done <= 1'b0;
    end
end

// CS signal control
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cs <= 1'b1;
    end else begin
        if (start_condition)
            cs <= 1'b0;
        else if (fsm_post_sclk)
            cs <= 1'b1;
    end
end

// SCLK internal control
wire sclk_toggle_enable;
assign sclk_toggle_enable = (fsm_pre_sclk || fsm_shift) && clk_cnt_half;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sclk_int <= 1'b0;
    end else begin
        if (sclk_toggle_enable)
            sclk_int <= ~sclk_int;
        else if (fsm_idle)
            sclk_int <= 1'b0;
    end
end

// Clock counter
wire clk_cnt_enable;
assign clk_cnt_enable = fsm_pre_sclk || fsm_shift;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_cnt <= 4'b0;
    end else begin
        if (start_condition)
            clk_cnt <= 4'b0;
        else if (clk_cnt_enable) begin
            if (clk_cnt_half)
                clk_cnt <= 4'b0;
            else
                clk_cnt <= clk_cnt + 1'b1;
        end else
            clk_cnt <= 4'b0;
    end
end

// Bit counter
wire bit_cnt_increment;
assign bit_cnt_increment = fsm_shift && clk_cnt_half && !sclk_int && (bit_cnt < DATA_WIDTH);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt <= {($clog2(DATA_WIDTH)+1){1'b0}};
    end else begin
        if (start_condition)
            bit_cnt <= {($clog2(DATA_WIDTH)+1){1'b0}};
        else if (bit_cnt_increment)
            bit_cnt <= bit_cnt + 1'b1;
    end
end

// Shift register for TX and RX
wire shift_reg_load;
wire shift_reg_shift;
assign shift_reg_load = start_condition;
assign shift_reg_shift = fsm_shift && clk_cnt_half && !sclk_int;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= {DATA_WIDTH{1'b0}};
    end else begin
        if (shift_reg_load)
            shift_reg <= tx_data;
        else if (shift_reg_shift)
            shift_reg <= {shift_reg[DATA_WIDTH-2:0], miso};
    end
end

// RX data latch
wire rx_data_latch;
assign rx_data_latch = fsm_shift && shift_bit_count_reached && clk_cnt_half && !sclk_int;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data <= {DATA_WIDTH{1'b0}};
    end else begin
        if (rx_data_latch)
            rx_data <= {shift_reg[DATA_WIDTH-2:0], miso};
    end
end

// CPOL/CPHA configuration (retained as in original code)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cpol_cpha <= 2'b00;
    end
end

assign mosi = shift_reg[DATA_WIDTH-1];
assign sclk = (cpol_cpha[0] & fsm_shift) ? sclk_int : cpol_cpha[1];

endmodule