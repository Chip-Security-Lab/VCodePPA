//SystemVerilog
module frac_delete_div #(parameter ACC_WIDTH=8) (
    input clk, rst,
    output reg clk_out
);
    reg [ACC_WIDTH-1:0] acc;
    
    // 直接在always块中实现组合逻辑和寄存器更新
    // 将复位逻辑保留在寄存器逻辑中
    always @(posedge clk) begin
        if (rst) begin
            acc <= {ACC_WIDTH{1'b0}};
            clk_out <= 1'b0;
        end else begin
            acc <= acc + 3;
            clk_out <= (acc + 3) < 8'h80 ? 1'b1 : 1'b0;
        end
    end
endmodule