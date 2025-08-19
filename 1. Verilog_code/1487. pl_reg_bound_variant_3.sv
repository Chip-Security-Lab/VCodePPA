//SystemVerilog
module pl_reg_bound #(parameter W=8, MAX=8'h7F) (
    input wire clk, load,
    input wire [W-1:0] d_in,
    output reg [W-1:0] q
);

    wire [W-1:0] bounded_value;
    
    // 使用条件运算符代替if-else结构，提高硬件效率
    assign bounded_value = (d_in > MAX) ? MAX : d_in;
    
    always @(posedge clk) begin
        if (load) begin
            q <= bounded_value;
        end
    end

endmodule