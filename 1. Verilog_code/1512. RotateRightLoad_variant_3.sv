//SystemVerilog
// IEEE 1364-2005 Verilog标准
module RotateRightLoad #(parameter DATA_WIDTH=8) (
    input wire clk,
    input wire load_en,
    input wire [DATA_WIDTH-1:0] parallel_in,
    input wire [DATA_WIDTH-1:0] subtrahend,
    input wire sub_en,
    output reg [DATA_WIDTH-1:0] data
);

    wire [DATA_WIDTH-1:0] sub_result;
    wire [DATA_WIDTH:0] borrow;
    
    // 先行借位减法器实现
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin: gen_sub
            assign sub_result[i] = data[i] ^ subtrahend[i] ^ borrow[i];
            assign borrow[i+1] = (~data[i] & subtrahend[i]) | 
                                (~data[i] & borrow[i]) | 
                                (subtrahend[i] & borrow[i]);
        end
    endgenerate

    // 使用if-else替代条件运算符，提高可读性
    always @(posedge clk) begin
        if (load_en) begin
            // 加载并行输入数据
            data <= parallel_in;
        end else if (sub_en) begin
            // 执行减法操作
            data <= sub_result;
        end else begin
            // 执行右旋转操作
            data <= {data[0], data[DATA_WIDTH-1:1]};
        end
    end

endmodule