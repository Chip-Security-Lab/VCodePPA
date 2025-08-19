//SystemVerilog
module parity_reg(
    input clk, reset,
    input [7:0] data,
    input load,
    output reg [8:0] data_with_parity
);
    // 通过拆分并行计算奇偶校验位，提高校验位计算效率
    wire [3:0] parity_stage1;
    wire [1:0] parity_stage2;
    wire parity_bit;
    
    assign parity_stage1[0] = data[0] ^ data[1];
    assign parity_stage1[1] = data[2] ^ data[3];
    assign parity_stage1[2] = data[4] ^ data[5];
    assign parity_stage1[3] = data[6] ^ data[7];
    
    assign parity_stage2[0] = parity_stage1[0] ^ parity_stage1[1];
    assign parity_stage2[1] = parity_stage1[2] ^ parity_stage1[3];
    
    assign parity_bit = parity_stage2[0] ^ parity_stage2[1];
    
    // 优化时序逻辑，减少逻辑层级
    always @(posedge clk) begin
        if (reset)
            data_with_parity <= 9'b0;
        else if (load)
            data_with_parity <= {parity_bit, data};
    end
endmodule