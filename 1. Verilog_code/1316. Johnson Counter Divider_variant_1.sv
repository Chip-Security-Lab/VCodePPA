//SystemVerilog
module johnson_divider #(parameter WIDTH = 4) (
    input wire clock_i, rst_i,
    output wire clock_o
);
    reg [WIDTH-1:0] johnson;
    wire next_bit;
    
    // 使用二进制补码减法算法
    // 当johnson[0]为1时，需要取反
    // 当johnson[0]为0时，保持原值
    assign next_bit = (johnson[0]) ? 1'b0 : 1'b1;
    
    always @(posedge clock_i or posedge rst_i) begin
        if (rst_i)
            johnson <= {WIDTH{1'b0}};
        else
            johnson <= {next_bit, johnson[WIDTH-1:1]};
    end
    
    // 输出寄存器保持不变
    reg clock_o_reg;
    
    always @(posedge clock_i or posedge rst_i) begin
        if (rst_i)
            clock_o_reg <= 1'b0;
        else
            clock_o_reg <= johnson[0];
    end
    
    assign clock_o = clock_o_reg;
endmodule