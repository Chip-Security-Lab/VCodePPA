//SystemVerilog
// IEEE 1364-2005 Verilog
module barrel_shifter (
    input wire [7:0] data_in,
    input wire [2:0] shift_amount,
    input wire direction, // 0: right, 1: left
    output wire [7:0] data_out
);
    // 中间信号声明
    wire [7:0] stage0_out, stage1_out, stage2_out;
    wire [7:0] reversed_input, reversed_output;
    
    // 输入数据翻转逻辑(用于左移)
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : reverse_input_gen
            assign reversed_input[i] = direction ? data_in[7-i] : data_in[i];
        end
    endgenerate
    
    // 第一级移位 (1位)
    assign stage0_out = shift_amount[0] ? {1'b0, reversed_input[7:1]} : reversed_input;
    
    // 第二级移位 (2位)
    assign stage1_out = shift_amount[1] ? {2'b00, stage0_out[7:2]} : stage0_out;
    
    // 第三级移位 (4位)
    assign stage2_out = shift_amount[2] ? {4'b0000, stage2_out[7:4]} : stage1_out;
    
    // 输出数据翻转逻辑(用于左移)
    generate
        for (i = 0; i < 8; i = i + 1) begin : reverse_output_gen
            assign reversed_output[i] = stage2_out[7-i];
        end
    endgenerate
    
    // 最终输出
    assign data_out = direction ? reversed_output : stage2_out;
    
endmodule