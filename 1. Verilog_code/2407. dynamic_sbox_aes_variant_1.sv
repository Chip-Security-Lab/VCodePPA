//SystemVerilog
// Top-level module
module dynamic_sbox_aes (
    input clk,
    input gen_sbox,
    input [7:0] sbox_in,
    output [7:0] sbox_out
);
    // Internal signals
    wire [7:0] sbox_value [0:255];
    
    // Instantiate sbox generator module
    sbox_generator sbox_gen_inst (
        .clk(clk),
        .gen_sbox(gen_sbox),
        .sbox_values(sbox_value)
    );
    
    // Instantiate sbox lookup module
    sbox_lookup sbox_lookup_inst (
        .clk(clk),
        .sbox_in(sbox_in),
        .sbox_values(sbox_value),
        .sbox_out(sbox_out)
    );
endmodule

// Submodule for generating the sbox values
module sbox_generator (
    input clk,
    input gen_sbox,
    output reg [7:0] sbox_values [0:255]
);
    integer i;
    
    always @(posedge clk) begin
        if (gen_sbox) begin
            for(i=0; i<256; i=i+1)
                sbox_values[i] <= (i * 8'h1B) ^ 8'h63;
        end
    end
endmodule

// Submodule for looking up values in the sbox
module sbox_lookup (
    input clk,
    input [7:0] sbox_in,
    input [7:0] sbox_values [0:255],
    output reg [7:0] sbox_out
);
    always @(posedge clk) begin
        sbox_out <= sbox_values[sbox_in];
    end
endmodule