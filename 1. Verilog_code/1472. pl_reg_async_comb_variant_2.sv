//SystemVerilog
module pl_reg_async_comb #(parameter W=8) (
    input clk, arst, load,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
    // 内部信号声明
    reg [W-1:0] inverted_din;
    reg subtract_mode;
    reg [W-1:0] adder_result;
    reg [W-1:0] next_dout;
    reg carry;
    integer i;
    
    // 条件反相减法器实现
    always @(*) begin
        // 根据操作类型决定是否需要反相
        subtract_mode = 1'b1; // 假设总是在做减法操作
        
        // 条件反相输入数据
        for (i = 0; i < W; i = i + 1) begin
            inverted_din[i] = subtract_mode ? ~din[i] : din[i];
        end
        
        // 执行加法操作(带上反相后的进位)
        carry = subtract_mode;
        adder_result[0] = dout[0] ^ inverted_din[0] ^ carry;
        carry = (dout[0] & inverted_din[0]) | (dout[0] & carry) | (inverted_din[0] & carry);
        
        for (i = 1; i < W; i = i + 1) begin
            adder_result[i] = dout[i] ^ inverted_din[i] ^ carry;
            carry = (dout[i] & inverted_din[i]) | (dout[i] & carry) | (inverted_din[i] & carry);
        end
        
        // 最终结果
        next_dout = load ? adder_result : dout;
    end
    
    // 输出寄存器更新
    always @(posedge clk or posedge arst) begin
        if (arst)
            dout <= {W{1'b0}};
        else
            dout <= next_dout;
    end
endmodule