//SystemVerilog
module error_injection_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_valid,
    input wire inject_error,
    input wire [2:0] error_bit,
    output reg [7:0] crc_out
);
    parameter [7:0] POLY = 8'h07;
    
    // Error injection logic
    wire [7:0] modified_data;
    assign modified_data = inject_error ? (data ^ (1'b1 << error_bit)) : data;
    
    // CRC calculation using Wallace tree inspired structure
    wire feedback_bit = crc_out[7] ^ modified_data[0];
    
    // Partial products generation (similar to Wallace tree first stage)
    wire [7:0] partial_product;
    assign partial_product = feedback_bit ? POLY : 8'h00;
    
    // First stage adders (CSA structure like in Wallace)
    wire [7:0] stage1_sum;
    assign stage1_sum = {crc_out[6:0], 1'b0} ^ partial_product;
    
    // Registration stage
    always @(posedge clk) begin
        if (rst) 
            crc_out <= 8'h00;
        else if (data_valid) 
            crc_out <= stage1_sum;
    end
endmodule