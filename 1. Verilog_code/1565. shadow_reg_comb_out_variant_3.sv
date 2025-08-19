//SystemVerilog
module shadow_reg_comb_out #(parameter WIDTH=8) (
    input clk, en,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    reg [WIDTH-1:0] shadow_reg;
    wire [WIDTH-1:0] subtractor_out;
    wire [WIDTH:0] borrow;
    
    // Generate borrow signals for parallel borrow-lookahead subtractor
    assign borrow[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow
            assign borrow[i+1] = (~shadow_reg[i] & borrow[i]) | (~shadow_reg[i] & din[i]) | (din[i] & borrow[i]);
        end
    endgenerate
    
    // Calculate subtraction result with borrow-lookahead
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_diff
            assign subtractor_out[i] = shadow_reg[i] ^ din[i] ^ borrow[i];
        end
    endgenerate
    
    // Register update with enable
    always @(posedge clk) begin
        if(en) shadow_reg <= din;
    end
    
    // Output assignment
    assign dout = shadow_reg;
endmodule