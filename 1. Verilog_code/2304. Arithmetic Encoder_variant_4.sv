//SystemVerilog
module arithmetic_encoder #(
    parameter PRECISION = 16
)(
    input                     clk,
    input                     rst,
    input                     symbol_req,
    input              [7:0]  symbol,
    output                    symbol_ack,
    output                    code_req,
    input                     code_ack,
    output     [PRECISION-1:0] lower_bound,
    output     [PRECISION-1:0] upper_bound
);
    // 内部连线
    wire [PRECISION-1:0] range;
    wire [PRECISION-1:0] prob_low, prob_high;
    wire [1:0] symbol_msb;
    
    // 从符号提取MSB
    symbol_extractor symbol_ext_inst (
        .symbol(symbol),
        .symbol_msb(symbol_msb)
    );
    
    // 概率模型子模块
    probability_model #(
        .PRECISION(PRECISION)
    ) prob_model_inst (
        .symbol_msb(symbol_msb),
        .prob_low(prob_low),
        .prob_high(prob_high)
    );
    
    // 范围计算子模块
    range_calculator #(
        .PRECISION(PRECISION)
    ) range_calc_inst (
        .lower_bound(lower_bound),
        .upper_bound(upper_bound),
        .range(range)
    );
    
    // 区间更新子模块
    bound_updater #(
        .PRECISION(PRECISION)
    ) bound_update_inst (
        .clk(clk),
        .rst(rst),
        .symbol_req(symbol_req),
        .symbol_ack(symbol_ack),
        .code_req(code_req),
        .code_ack(code_ack),
        .range(range),
        .prob_low(prob_low),
        .prob_high(prob_high),
        .lower_bound(lower_bound),
        .upper_bound(upper_bound)
    );
    
endmodule

// 符号提取子模块
module symbol_extractor (
    input      [7:0] symbol,
    output reg [1:0] symbol_msb
);
    // 提取符号的两个最高有效位
    always @(*) begin
        symbol_msb = symbol[7:6];
    end
endmodule

// 概率模型子模块
module probability_model #(
    parameter PRECISION = 16
)(
    input      [1:0] symbol_msb,
    output reg [PRECISION-1:0] prob_low,
    output reg [PRECISION-1:0] prob_high
);
    // 概率查找表
    reg [PRECISION-1:0] prob_table [0:3];
    
    initial begin
        prob_table[0] = 0;                   // Start
        prob_table[1] = PRECISION/4;         // 25%
        prob_table[2] = PRECISION/2;         // 50%
        prob_table[3] = (3*PRECISION)/4;     // 75%
    end
    
    always @(*) begin
        prob_low = prob_table[symbol_msb];
        prob_high = prob_table[symbol_msb+1];
    end
endmodule

// 范围计算子模块
module range_calculator #(
    parameter PRECISION = 16
)(
    input  [PRECISION-1:0] lower_bound,
    input  [PRECISION-1:0] upper_bound,
    output [PRECISION-1:0] range
);
    assign range = upper_bound - lower_bound + 1;
endmodule

// 区间更新子模块
module bound_updater #(
    parameter PRECISION = 16
)(
    input                     clk,
    input                     rst,
    input                     symbol_req,
    output reg                symbol_ack,
    output reg                code_req,
    input                     code_ack,
    input      [PRECISION-1:0] range,
    input      [PRECISION-1:0] prob_low,
    input      [PRECISION-1:0] prob_high,
    output reg [PRECISION-1:0] lower_bound,
    output reg [PRECISION-1:0] upper_bound
);
    // 临时变量
    reg [PRECISION-1:0] new_lower, new_upper;
    reg processing;
    reg data_processed;
    
    always @(*) begin
        new_lower = lower_bound + (range * prob_low)/PRECISION;
        new_upper = lower_bound + (range * prob_high)/PRECISION - 1;
    end
    
    // 状态控制
    always @(posedge clk) begin
        if (rst) begin
            lower_bound <= 0;
            upper_bound <= {PRECISION{1'b1}}; // All 1's
            symbol_ack <= 0;
            code_req <= 0;
            processing <= 0;
            data_processed <= 0;
        end else begin
            if (symbol_req && !processing && !data_processed) begin
                // 接收新符号请求
                symbol_ack <= 1;
                processing <= 1;
                lower_bound <= new_lower;
                upper_bound <= new_upper;
                data_processed <= 1;
            end else if (processing && data_processed && !code_req) begin
                // 开始发送编码请求
                symbol_ack <= 0;
                code_req <= 1;
            end else if (code_req && code_ack) begin
                // 接收方确认接收编码
                code_req <= 0;
                processing <= 0;
            end else if (!code_req && !processing && data_processed && !symbol_req) begin
                // 准备接收下一个符号
                data_processed <= 0;
            end else begin
                symbol_ack <= 0;
            end
        end
    end
endmodule