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

// 状态机状态定义
localparam BAUD_IDLE    = 2'b00;
localparam BAUD_MEASURE = 2'b01;
localparam BAUD_CALC    = 2'b10;

// 边沿检测寄存器
reg rxd_prev;
reg rxd_curr;
wire rxd_fall;
wire rxd_rise;

// 状态机相关寄存器
reg [1:0] baud_state;
reg [31:0] edge_counter;
reg [7:0] sample_window; // 保留，便于后续扩展
reg [15:0] manual_br;
reg [15:0] detected_br_reg; // 用于组合与时序分离
reg [15:0] actual_br;

// 波特率计数器
reg [15:0] baud_counter;
reg baud_tick_reg;

// ------------------- rxd边沿检测 -------------------
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

// ------------------- 状态机控制 -------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_state <= BAUD_IDLE;
    end else begin
        case (baud_state)
            BAUD_IDLE: begin
                if (rxd_fall && auto_br_en)
                    baud_state <= BAUD_MEASURE;
            end
            BAUD_MEASURE: begin
                if (rxd_rise)
                    baud_state <= BAUD_CALC;
            end
            BAUD_CALC: begin
                baud_state <= BAUD_IDLE;
            end
            default: baud_state <= BAUD_IDLE;
        endcase
    end
end

// ------------------- edge_counter控制 -------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        edge_counter <= 32'd0;
    end else begin
        case (baud_state)
            BAUD_IDLE: begin
                if (rxd_fall && auto_br_en)
                    edge_counter <= 32'd0;
            end
            BAUD_MEASURE: begin
                edge_counter <= edge_counter + 1;
            end
            default: ;
        endcase
    end
end

// ------------------- detected_br计算 -------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        detected_br_reg <= 16'd0;
    end else if (baud_state == BAUD_CALC) begin
        if (edge_counter > 0)
            detected_br_reg <= (CLK_FREQ / (edge_counter * 2)) - 1;
        else
            detected_br_reg <= 16'd0;
    end
end

// ------------------- detected_br输出 -------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        detected_br <= 16'd0;
    end else begin
        detected_br <= detected_br_reg;
    end
end

// ------------------- manual_br保留 -------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        manual_br <= 16'd0;
    end
end

// ------------------- actual_br生成 -------------------
always @(*) begin
    if (auto_br_en)
        actual_br = detected_br_reg;
    else
        actual_br = manual_br;
end

// ------------------- 波特率计数器 -------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_counter <= 16'd0;
    end else begin
        if (baud_counter >= actual_br)
            baud_counter <= 16'd0;
        else
            baud_counter <= baud_counter + 1;
    end
end

// ------------------- baud_tick生成 -------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_tick_reg <= 1'b0;
    end else begin
        baud_tick_reg <= (baud_counter == actual_br);
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        baud_tick <= 1'b0;
    else
        baud_tick <= baud_tick_reg;
end

endmodule