//SystemVerilog
module UART_AutoBaud #(
    parameter MIN_BAUD = 9600,
    parameter CLK_FREQ = 100_000_000
)(
    input  wire clk,
    input  wire rst_n,
    input  wire rxd,
    input  wire auto_br_en,
    output reg [15:0] detected_br,
    output reg  baud_tick
);

// 状态机参数
localparam BAUD_IDLE    = 2'b00;
localparam BAUD_MEASURE = 2'b01;
localparam BAUD_CALC    = 2'b10;

// 信号定义
reg  [31:0] edge_counter;
reg  [1:0]  baud_state, baud_state_next;
reg  [15:0] manual_br;
reg  [15:0] actual_br_reg, actual_br_next;
reg  [15:0] baud_counter, baud_counter_next;
reg         baud_tick_next;
reg  [15:0] detected_br_next;
reg         rxd_prev_reg, rxd_curr_reg;
wire        rxd_fall_edge, rxd_rise_edge;
wire        start_measure, finish_measure;
wire [31:0] edge_counter_next;
wire        edge_counter_clr;
wire        baud_counter_rst;
wire        baud_counter_inc;
wire [15:0] baud_calc_result;

// 边沿检测同步器
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rxd_prev_reg <= 1'b1;
        rxd_curr_reg <= 1'b1;
    end else begin
        rxd_prev_reg <= rxd;
        rxd_curr_reg <= rxd_prev_reg;
    end
end

assign rxd_fall_edge = rxd_prev_reg & ~rxd;
assign rxd_rise_edge = ~rxd_prev_reg & rxd;

// 状态跳转条件提前计算，均衡路径
assign start_measure  = (baud_state == BAUD_IDLE)    && rxd_fall_edge && auto_br_en;
assign finish_measure = (baud_state == BAUD_MEASURE) && rxd_rise_edge;

// edge_counter控制信号
assign edge_counter_clr = start_measure;
assign edge_counter_next = (baud_state == BAUD_MEASURE) ? (edge_counter + 1) : 32'd0;

// 波特率计算提前分支，均衡组合路径
assign baud_calc_result = (edge_counter > 0) ? ((CLK_FREQ / (edge_counter << 1)) - 1) : 16'd0;

// 状态机组合逻辑，减小case深度
always @(*) begin
    baud_state_next    = baud_state;
    detected_br_next   = detected_br;
    case (baud_state)
        BAUD_IDLE: begin
            if (start_measure)
                baud_state_next = BAUD_MEASURE;
        end
        BAUD_MEASURE: begin
            if (finish_measure)
                baud_state_next = BAUD_CALC;
        end
        BAUD_CALC: begin
            baud_state_next  = BAUD_IDLE;
            detected_br_next = baud_calc_result;
        end
        default: begin
            baud_state_next  = BAUD_IDLE;
            detected_br_next = 16'd0;
        end
    endcase
end

// edge_counter寄存器化，减少case判断层级，均衡关键路径
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        edge_counter <= 32'd0;
    else if (edge_counter_clr)
        edge_counter <= 32'd0;
    else if (baud_state == BAUD_MEASURE)
        edge_counter <= edge_counter + 1;
    else
        edge_counter <= edge_counter;
end

// 状态机与检测结果寄存器化
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_state   <= BAUD_IDLE;
        detected_br  <= 16'd0;
        manual_br    <= 16'd0;
    end else begin
        baud_state  <= baud_state_next;
        detected_br <= detected_br_next;
    end
end

// actual_br寄存器化
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        actual_br_reg <= 16'd0;
    else if (auto_br_en)
        actual_br_reg <= detected_br;
    else
        actual_br_reg <= manual_br;
end

// baud_counter控制信号提前分支，均衡关键路径
assign baud_counter_rst = (baud_counter >= actual_br_reg);
assign baud_counter_inc = ~baud_counter_rst;

// baud_counter下一个值组合
assign baud_counter_next = baud_counter_rst ? 16'd0 : (baud_counter + 1'b1);

// baud_counter寄存器化
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        baud_counter <= 16'd0;
    else
        baud_counter <= baud_counter_next;
end

// baud_tick_next提前分配，缩短关键路径
assign baud_tick_next = (baud_counter == actual_br_reg);

// baud_tick寄存器化
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        baud_tick <= 1'b0;
    else
        baud_tick <= baud_tick_next;
end

endmodule