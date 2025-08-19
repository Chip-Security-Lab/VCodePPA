//SystemVerilog
module gcm_auth #(parameter WIDTH = 32) (
    input wire clk, reset_l,
    input wire data_valid, last_block,
    input wire [WIDTH-1:0] data_in, h_key,
    output reg [WIDTH-1:0] auth_tag,
    output reg tag_valid
);
    reg [WIDTH-1:0] accumulated;
    wire [WIDTH-1:0] xor_result;
    wire [WIDTH-1:0] mult_result;
    
    // Pre-compute XOR to reduce path delay
    assign xor_result = accumulated ^ data_in;
    
    // GF(2^128) multiplication optimized implementation
    function [WIDTH-1:0] gf_mult;
        input [WIDTH-1:0] a, b;
        reg [WIDTH-1:0] res;
        reg [WIDTH*2-1:0] temp;
        reg [WIDTH-1:0] reduction_poly;
        integer i;
        begin
            res = {WIDTH{1'b0}};
            reduction_poly = 32'h87000000; // Reduction polynomial
            
            // Parallel multiplier implementation - converted to while loop
            i = 0;
            while (i < WIDTH) begin
                if (a[i]) 
                    res = res ^ (b << i);
                i = i + 1;
            end
            
            // Optimized reduction with prioritized MSB handling - converted to while loop
            temp = {WIDTH{1'b0}};
            temp[WIDTH-1:0] = res;
            
            i = WIDTH*2-1;
            while (i >= WIDTH) begin
                if (temp[i]) begin
                    temp[i] = 1'b0;
                    temp[i-WIDTH +: WIDTH] = temp[i-WIDTH +: WIDTH] ^ reduction_poly;
                end
                i = i - 1;
            end
            
            gf_mult = temp[WIDTH-1:0];
        end
    endfunction
    
    // Pre-compute multiplication result to optimize logic usage
    assign mult_result = gf_mult(xor_result, h_key);
    
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            accumulated <= {WIDTH{1'b0}};
            tag_valid <= 1'b0;
            auth_tag <= {WIDTH{1'b0}};
        end 
        else if (data_valid) begin
            accumulated <= mult_result;
            
            if (last_block) begin
                auth_tag <= xor_result;
                tag_valid <= 1'b1;
            end
            else begin
                tag_valid <= 1'b0;
            end
        end
        else begin
            tag_valid <= 1'b0;
        end
    end
endmodule