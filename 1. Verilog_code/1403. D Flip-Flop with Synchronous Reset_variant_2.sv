//SystemVerilog
module d_ff_sync_reset (
    input wire clk,
    input wire rst,
    input wire d,
    output reg q
);
    // 直接在输出处进行寄存操作，而不是在输入处
    always @(posedge clk) begin
        // 复位逻辑直接在这里处理，无需单独的rst_reg
        if (rst)
            q <= 1'b0;
        else
            q <= d;
    end
    
endmodule