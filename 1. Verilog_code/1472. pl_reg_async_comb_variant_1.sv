//SystemVerilog
module pl_reg_async_comb #(parameter W=8) (
    input clk, arst, load,
    input [W-1:0] din,
    output [W-1:0] dout
);
    reg [W-1:0] reg_d;
    
    always @(posedge clk or posedge arst) begin
        if (arst) 
            reg_d <= {W{1'b0}};
        else if (load) 
            reg_d <= din;
    end
    
    assign dout = reg_d;
endmodule

module binary_complement_subtractor #(parameter W=8) (
    input [W-1:0] a,
    input [W-1:0] b,
    output [W-1:0] result
);
    wire [W-1:0] b_inverted;
    wire [W-1:0] result_temp;
    wire carry_in, unused_carry_out;
    
    // 将补码计算分解为两步：求反和加一
    assign b_inverted = ~b;
    assign carry_in = 1'b1; // 加一的部分
    
    // 使用加法器一次性完成加法
    assign {unused_carry_out, result_temp} = a + b_inverted + carry_in;
    
    // 最终结果
    assign result = result_temp;
endmodule