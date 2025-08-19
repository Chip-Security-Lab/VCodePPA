//SystemVerilog
// SystemVerilog
module pl_reg_latch #(parameter W=8) (
    input wire gate, load,
    input wire [W-1:0] d,
    output reg [W-1:0] q
);
    // 使用条件赋值标准 Verilog 语法
    // 明确表示 latch 行为，增强可读性
    // 组合 gate 和 load 为单一使能条件，减少逻辑级数
    wire enable = gate & load;
    
    always @* begin
        if (enable) q <= d;
    end
endmodule