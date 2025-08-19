//SystemVerilog
module pl_reg_accum #(parameter W=8) (
    input clk, rst, add_en,
    input [W-1:0] add_val,
    output reg [W-1:0] sum
);
    // 组合逻辑部分
    wire [1:0] ctrl;
    wire [W-1:0] next_sum;
    
    // 控制信号组合
    assign ctrl = {rst, add_en};
    
    // 组合逻辑决定下一状态
    assign next_sum = (ctrl[1]) ? {W{1'b0}} :           // rst=1, 复位为0
                      (ctrl[0]) ? sum + add_val :       // rst=0, add_en=1
                                 sum;                   // rst=0, add_en=0
    
    // 时序逻辑部分
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum <= {W{1'b0}};
        end else begin
            sum <= next_sum;
        end
    end
endmodule