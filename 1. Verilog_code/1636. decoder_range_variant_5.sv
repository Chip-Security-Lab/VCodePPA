//SystemVerilog
module decoder_range #(MIN=8'h20, MAX=8'h3F) (
    input [7:0] addr,
    output reg active
);

// Baugh-Wooley multiplication implementation
function [15:0] baugh_wooley_mult;
    input [7:0] a;
    input [7:0] b;
    reg [15:0] pp[7:0];
    reg [15:0] sum;
    integer i;
    begin
        // Generate partial products
        for(i = 0; i < 8; i = i + 1) begin
            pp[i] = (a & {8{b[i]}}) << i;
        end
        
        // Baugh-Wooley correction terms
        pp[7] = pp[7] ^ (1 << 15);  // Invert MSB
        pp[6] = pp[6] ^ (1 << 14);
        pp[5] = pp[5] ^ (1 << 13);
        pp[4] = pp[4] ^ (1 << 12);
        
        // Sum all partial products
        sum = 0;
        for(i = 0; i < 8; i = i + 1) begin
            sum = sum + pp[i];
        end
        
        baugh_wooley_mult = sum;
    end
endfunction

// Range check using Baugh-Wooley multiplication
reg [15:0] min_check, max_check;
always @* begin
    min_check = baugh_wooley_mult(addr, 8'h01);
    max_check = baugh_wooley_mult(addr, 8'h01);
    active = (min_check >= MIN) && (max_check <= MAX);
end

endmodule