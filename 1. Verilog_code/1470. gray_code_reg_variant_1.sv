//SystemVerilog
module gray_code_reg(
    input clk, reset,
    input [7:0] bin_in,
    input load, convert,
    output reg [7:0] gray_out
);
    reg [7:0] binary;
    
    // 处理二进制寄存器更新逻辑
    always @(posedge clk) begin
        if (reset) begin
            binary <= 8'h00;
        end else if (load) begin
            binary <= bin_in;
        end
    end
    
    // 处理灰码转换和输出逻辑
    always @(posedge clk) begin
        if (reset) begin
            gray_out <= 8'h00;
        end else if (convert) begin
            gray_out <= binary ^ {1'b0, binary[7:1]};
        end
    end
endmodule