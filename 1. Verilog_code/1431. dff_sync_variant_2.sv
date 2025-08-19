//SystemVerilog
//IEEE 1364-2005
module binary_subtractor_8bit (
    input clk,
    input rstn,
    input [7:0] minuend,     // 被减数
    input [7:0] subtrahend,  // 减数
    output [7:0] difference  // 差
);
    wire [7:0] sub_result;
    
    // 直接使用减法运算符，合成工具会自动优化为最高效的实现
    assign sub_result = minuend - subtrahend;
    
    // 使用D触发器进行同步
    dff_sync #(.WIDTH(8)) result_reg (
        .clk(clk),
        .rstn(rstn),
        .d(sub_result),
        .q(difference)
    );
endmodule

module dff_sync #(parameter WIDTH=1) (
    input clk, rstn, 
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or negedge rstn) begin
        if (!rstn) q <= {WIDTH{1'b0}};
        else       q <= d;
    end
endmodule