module UART_AutoBaud #(
    parameter MIN_BAUD = 9600,
    parameter CLK_FREQ = 100_000_000
)(
    input  wire clk,
    input  wire rst_n,          // 添加复位信号
    input  wire rxd,            // 添加接收数据信号
    input  wire auto_br_en,     // 自检测使能
    output reg [15:0] detected_br,
    output reg  baud_tick       // 添加波特率脉冲输出
);
// 波特率检测状态机
localparam BAUD_IDLE = 2'b00;
localparam BAUD_MEASURE = 2'b01;
localparam BAUD_CALC = 2'b10;

// 高精度计数器
reg [31:0] edge_counter;
reg [7:0] sample_window;
reg [1:0] baud_state;
reg [15:0] manual_br;
reg [15:0] actual_br;
reg [15:0] baud_counter;

// 边沿检测
reg rxd_prev, rxd_curr;
wire rxd_fall, rxd_rise;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_prev <= 1'b1;
        rxd_curr <= 1'b1;
    end else begin
        rxd_prev <= rxd_curr;
        rxd_curr <= rxd;
    end
end

assign rxd_fall = rxd_prev & ~rxd_curr;
assign rxd_rise = ~rxd_prev & rxd_curr;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_state <= BAUD_IDLE;
        edge_counter <= 0;
        sample_window <= 0;
        detected_br <= 16'd0;
        manual_br <= 16'd0;
    end else begin
        case(baud_state)
            BAUD_IDLE: 
                if (rxd_fall && auto_br_en) begin
                    baud_state <= BAUD_MEASURE;
                    edge_counter <= 0;
                end
            
            BAUD_MEASURE: begin
                edge_counter <= edge_counter + 1;
                if (rxd_rise)
                    baud_state <= BAUD_CALC;
            end
            
            BAUD_CALC: begin
                // 防止除零错误
                if (edge_counter > 0)
                    detected_br <= (CLK_FREQ / (edge_counter * 2)) - 1;
                else
                    detected_br <= 0;
                baud_state <= BAUD_IDLE;
            end
            
            default: baud_state <= BAUD_IDLE;
        endcase
    end
end

// 动态波特率生成器
always @(*) begin
    actual_br = auto_br_en ? detected_br : manual_br;
    baud_tick = (baud_counter == actual_br);
end

// 波特率计数器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_counter <= 0;
    end else begin
        if (baud_counter >= actual_br)
            baud_counter <= 0;
        else
            baud_counter <= baud_counter + 1;
    end
end
endmodule