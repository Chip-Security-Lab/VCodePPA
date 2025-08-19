//SystemVerilog
module UART_AutoBaud #(
    parameter MIN_BAUD = 9600,
    parameter CLK_FREQ = 100_000_000
)(
    input  wire clk,
    input  wire rst_n,
    input  wire rxd,
    input  wire auto_br_en,
    output reg  [15:0] detected_br,
    output reg         baud_tick
);

// 状态机定义
localparam BAUD_IDLE    = 2'b00;
localparam BAUD_MEASURE = 2'b01;
localparam BAUD_CALC    = 2'b10;

// 边沿检测寄存器
reg rxd_sync_1, rxd_sync_2;
wire rxd_falling_edge, rxd_rising_edge;

// 计数器和状态
reg [31:0] cycle_counter;
reg [15:0] baud_counter;
reg [1:0]  fsm_state;
reg [15:0] manual_baud_rate;
reg [15:0] selected_baud_rate;

// 边沿检测，1拍同步
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_sync_1 <= 1'b1;
        rxd_sync_2 <= 1'b1;
    end else begin
        rxd_sync_1 <= rxd;
        rxd_sync_2 <= rxd_sync_1;
    end
end

assign rxd_falling_edge = (rxd_sync_2 & ~rxd_sync_1);
assign rxd_rising_edge  = (~rxd_sync_2 & rxd_sync_1);

// 状态机及波特率检测
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fsm_state        <= BAUD_IDLE;
        cycle_counter    <= 32'd0;
        detected_br      <= 16'd0;
        manual_baud_rate <= 16'd0;
    end else begin
        case (fsm_state)
            BAUD_IDLE: begin
                if (auto_br_en && rxd_falling_edge) begin
                    fsm_state     <= BAUD_MEASURE;
                    cycle_counter <= 32'd0;
                end
            end
            BAUD_MEASURE: begin
                cycle_counter <= cycle_counter + 32'd1;
                if (rxd_rising_edge) begin
                    fsm_state <= BAUD_CALC;
                end
            end
            BAUD_CALC: begin
                detected_br <= (cycle_counter == 32'd0) ? 16'd0 : (((CLK_FREQ >> 1) / cycle_counter) - 16'd1);
                fsm_state   <= BAUD_IDLE;
            end
            default: begin
                fsm_state <= BAUD_IDLE;
            end
        endcase
    end
end

// 动态波特率选择
always @(*) begin
    selected_baud_rate = auto_br_en ? detected_br : manual_baud_rate;
end

// 波特率脉冲生成
wire baud_counter_hit;
assign baud_counter_hit = (baud_counter == selected_baud_rate);

// 波特率计数器与脉冲同步输出
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_counter <= 16'd0;
        baud_tick    <= 1'b0;
    end else begin
        baud_tick <= baud_counter_hit;
        baud_counter <= baud_counter_hit ? 16'd0 : baud_counter + 16'd1;
    end
end

endmodule