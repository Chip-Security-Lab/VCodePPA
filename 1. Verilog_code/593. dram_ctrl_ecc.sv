module dram_ctrl_ecc #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH = 8
)(
    input clk,
    input [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out,
    output [ECC_WIDTH-1:0] ecc_syndrome
);
    // ECC生成逻辑
    function [ECC_WIDTH-1:0] calculate_ecc;
        input [DATA_WIDTH-1:0] data;
        // 简化汉明码计算
        calculate_ecc = ^(data & 64'hFF00FF00FF00FF00);
    endfunction
    
    // 数据寄存
    reg [DATA_WIDTH-1:0] stored_data;
    reg [ECC_WIDTH-1:0] stored_ecc;
    
    always @(posedge clk) begin
        stored_data <= data_in;
        stored_ecc <= calculate_ecc(data_in);
    end
    
    // 错误检测
    assign ecc_syndrome = stored_ecc ^ calculate_ecc(stored_data);
    assign data_out = stored_data;
endmodule
