//SystemVerilog
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
        calculate_ecc = ^(data & 64'hFF00FF00FF00FF00);
    endfunction
    
    // 流水线寄存器
    reg [DATA_WIDTH-1:0] stored_data;
    reg [DATA_WIDTH-1:0] stored_data_pipe;
    reg [ECC_WIDTH-1:0] stored_ecc;
    reg [ECC_WIDTH-1:0] calculated_ecc_pipe;
    
    // 补码加法实现减法
    wire [ECC_WIDTH-1:0] calculated_ecc;
    wire [ECC_WIDTH-1:0] inverted_stored_ecc;
    wire [ECC_WIDTH-1:0] ecc_diff;
    
    // 第一级流水线
    assign calculated_ecc = calculate_ecc(stored_data);
    
    // 第二级流水线
    assign inverted_stored_ecc = ~stored_ecc + 1'b1;
    assign ecc_syndrome = calculated_ecc_pipe + inverted_stored_ecc;
    
    always @(posedge clk) begin
        // 第一级流水线
        stored_data <= data_in;
        stored_ecc <= calculate_ecc(data_in);
        
        // 第二级流水线
        stored_data_pipe <= stored_data;
        calculated_ecc_pipe <= calculated_ecc;
    end
    
    assign data_out = stored_data_pipe;
endmodule