//SystemVerilog
module lfsr_counter (
    input wire clk, rst,
    output reg [7:0] lfsr
);
    // 优化feedback路径，使用位选择并行计算
    wire feedback;
    assign feedback = ^{lfsr[7], lfsr[5:3]};
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            lfsr <= 8'h01;  // 非零种子值
        else
            lfsr <= {lfsr[6:0], feedback};
    end
endmodule