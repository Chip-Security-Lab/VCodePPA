//SystemVerilog
//IEEE 1364-2005 Verilog
module rle_codec (
    input clk, 
    input [7:0] data_in,
    output reg [7:0] data_out
);

    // First level of buffered copies to reduce initial fan-out load
    reg [7:0] data_in_stage1;
    
    // Second level of buffered copies for specific functional paths
    reg [7:0] data_in_buf1;  // For count logic
    reg [7:0] data_in_buf2;  // For data output path
    reg data_in_msb_buf;     // Dedicated buffer for control bit
    
    reg [7:0] count;
    
    // First pipeline stage - distribute input load
    always @(posedge clk) begin
        data_in_stage1 <= data_in;
    end
    
    // Second pipeline stage - functional path specific buffers
    always @(posedge clk) begin
        data_in_buf1 <= data_in_stage1;
        data_in_buf2 <= data_in_stage1;
        data_in_msb_buf <= data_in_stage1[7];
    end
    
    // Third pipeline stage - main logic with balanced fan-out
    always @(posedge clk) begin
        if (data_in_msb_buf) begin
            count <= data_in_buf1[6:0];
            data_out <= 8'h00;
        end else begin
            count <= count - 1;
            data_out <= data_in_buf2;
        end
    end
    
endmodule