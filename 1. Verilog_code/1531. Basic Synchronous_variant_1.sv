//SystemVerilog
// IEEE 1364-2005 Verilog
module sync_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire capture,
    output reg [WIDTH-1:0] shadow_data
);
    // Primary register
    reg [WIDTH-1:0] primary_reg;
    // Borrow signals for lookahead borrow subtractor implementation
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] subtraction_result;
    
    // Generate borrow signals
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow
            assign borrow[i+1] = (~primary_reg[i] & borrow[i]) | (~primary_reg[i] & shadow_data[i]) | (shadow_data[i] & borrow[i]);
            assign subtraction_result[i] = primary_reg[i] ^ shadow_data[i] ^ borrow[i];
        end
    endgenerate
    
    // Primary register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            primary_reg <= {WIDTH{1'b0}};
        else
            primary_reg <= data_in;
    end
    
    // Shadow register update with lookahead borrow implementation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= {WIDTH{1'b0}};
        else if (capture)
            shadow_data <= subtraction_result; // Use result from lookahead borrow subtractor
        else
            shadow_data <= shadow_data; // No change
    end
endmodule