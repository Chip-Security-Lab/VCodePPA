//SystemVerilog
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: Binary Clock Divider
// Module Name: binary_clk_divider
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Clock divider generating 4 divided clock signals (divide by 2, 4, 8, 16)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Compliant with IEEE 1364-2005 Verilog standard
// 
//////////////////////////////////////////////////////////////////////////////////

module binary_clk_divider (
    input  wire       clk_i,     // Input clock
    input  wire       rst_i,     // Asynchronous reset, active high
    output wire [3:0] clk_div    // Divided clock outputs [div2, div4, div8, div16]
);

    // Counter register for clock division
    reg [3:0] div_counter;
    
    // Counter logic with registered outputs for improved timing
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            div_counter <= 4'b0000;
        end else begin
            div_counter <= div_counter + 4'b0001;
        end
    end
    
    // Direct counter bits as divided clock outputs
    // Each bit toggles at half the frequency of the previous bit
    assign clk_div = div_counter;

endmodule