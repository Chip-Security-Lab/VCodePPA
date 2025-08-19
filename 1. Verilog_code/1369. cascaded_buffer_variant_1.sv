//SystemVerilog
// 顶层模块：级联缓冲器
module cascaded_buffer (
    input  wire       clk,
    input  wire [7:0] data_in,
    input  wire       cascade_en,
    output wire [7:0] data_out
);
    wire [7:0] stage1_to_stage2;
    wire [7:0] stage2_to_output;

    // 级联的第一级缓冲
    buffer_stage stage1 (
        .clk       (clk),
        .data_in   (data_in),
        .enable    (cascade_en),
        .data_out  (stage1_to_stage2)
    );

    // 级联的第二级缓冲
    buffer_stage stage2 (
        .clk       (clk),
        .data_in   (stage1_to_stage2),
        .enable    (cascade_en),
        .data_out  (stage2_to_output)
    );

    // 输出级缓冲
    buffer_stage output_stage (
        .clk       (clk),
        .data_in   (stage2_to_output),
        .enable    (cascade_en),
        .data_out  (data_out)
    );

endmodule

// 单级缓冲子模块
module buffer_stage (
    input  wire       clk,
    input  wire [7:0] data_in,
    input  wire       enable,
    output reg  [7:0] data_out
);
    always @(posedge clk) begin
        if (enable) begin
            data_out <= data_in;
        end
    end
endmodule