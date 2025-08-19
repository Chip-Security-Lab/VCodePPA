//SystemVerilog
module sbox_substitution #(parameter ADDR_WIDTH = 4, DATA_WIDTH = 8) (
    input wire clk, rst,
    input wire enable,
    input wire [ADDR_WIDTH-1:0] addr_in,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    // S-box lookup table
    reg [DATA_WIDTH-1:0] sbox [0:(1<<ADDR_WIDTH)-1];
    
    // Pre-compute the substitution value to reduce critical path
    wire [DATA_WIDTH-1:0] sbox_value;
    
    // Pipeline registers
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg [DATA_WIDTH-1:0] sbox_value_reg;
    reg enable_reg;
    
    // S-box lookup - combinational
    assign sbox_value = sbox[addr_in];
    
    // First pipeline stage - register inputs and s-box value
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_reg <= {DATA_WIDTH{1'b0}};
            sbox_value_reg <= {DATA_WIDTH{1'b0}};
            enable_reg <= 1'b0;
        end
        else begin
            data_in_reg <= data_in;
            sbox_value_reg <= sbox_value;
            enable_reg <= enable;
        end
    end
    
    // Second pipeline stage - perform XOR and register output
    always @(posedge clk or posedge rst) begin
        if (rst) 
            data_out <= {DATA_WIDTH{1'b0}};
        else if (enable_reg) 
            data_out <= sbox_value_reg ^ data_in_reg;
    end
endmodule