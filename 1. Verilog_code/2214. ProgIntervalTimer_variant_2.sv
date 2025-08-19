//SystemVerilog
module ProgIntervalTimer (
    input clk, rst_n, load,
    input [15:0] threshold,
    output reg intr
);
    reg [15:0] cnt_reg;
    wire [15:0] cnt_next;
    wire cnt_is_one;
    
    // 组合逻辑部分：减法器和条件检测
    SubtractorModule sub_inst (
        .value(cnt_reg),
        .result(cnt_next),
        .is_one(cnt_is_one)
    );
    
    // 时序逻辑部分
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt_reg <= 16'b0;
            intr <= 1'b0;
        end
        else if (load) begin
            cnt_reg <= threshold;
            intr <= 1'b0;
        end
        else begin
            cnt_reg <= (cnt_reg == 16'd0) ? 16'd0 : cnt_next;
            intr <= cnt_is_one;
        end
    end
endmodule

// 组合逻辑子模块：负责减法和值检测
module SubtractorModule (
    input [15:0] value,
    output [15:0] result,
    output is_one
);
    wire [15:0] sub_result;
    wire [16:0] borrow;
    
    // 先行借位减法器实现（组合逻辑）
    assign borrow[0] = 1'b0;  // 初始无借位
    
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_sub
            assign sub_result[i] = value[i] ^ 1'b1 ^ borrow[i];
            assign borrow[i+1] = (~value[i] & borrow[i]) | (~value[i] & 1'b1) | (1'b1 & borrow[i]);
        end
    endgenerate
    
    // 计算结果和标志位检测（组合逻辑）
    assign result = sub_result;
    assign is_one = (value == 16'd1);
endmodule