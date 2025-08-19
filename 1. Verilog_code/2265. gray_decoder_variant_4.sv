//SystemVerilog
/////////////////////////////////////////////////////////////////////////////
// Module: gray_decoder
// Description: Pipelined Gray code to binary converter with optimized 
//              data path and improved timing characteristics
// Standard: IEEE 1364-2005
/////////////////////////////////////////////////////////////////////////////
module gray_decoder (
    input            clk,      // Clock input
    input            rst_n,    // Active-low reset
    input            valid_in, // Input valid signal
    input      [3:0] gray_in,  // Gray code input
    output reg       valid_out, // Output valid signal
    output reg [3:0] binary_out // Binary output
);

    // Internal signals for gray-to-binary conversion (combinational)
    wire [3:0] binary_conv;
    
    // Combinational gray-to-binary conversion 
    assign binary_conv[3] = gray_in[3];
    assign binary_conv[2] = gray_in[3] ^ gray_in[2];
    assign binary_conv[1] = gray_in[3] ^ gray_in[2] ^ gray_in[1];
    assign binary_conv[0] = gray_in[3] ^ gray_in[2] ^ gray_in[1] ^ gray_in[0];
    
    // Pipeline register moved after the combinational logic
    // This reduces the delay from inputs to first register
    reg [3:0] binary_r1;
    reg valid_r1;
    
    // Stage 1: Register after combinational conversion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_r1 <= 4'b0;
            valid_r1 <= 1'b0;
        end
        else begin
            binary_r1 <= binary_conv;
            valid_r1 <= valid_in;
        end
    end
    
    // Stage 2: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_out <= 4'b0;
            valid_out <= 1'b0;
        end
        else begin
            binary_out <= binary_r1;
            valid_out <= valid_r1;
        end
    end
    
endmodule