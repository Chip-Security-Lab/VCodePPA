//SystemVerilog
module IIR_LPF #(parameter W=8, ALPHA=4) (
    input clk, rst_n,
    input [W-1:0] din,
    output reg [W-1:0] dout
);
    // Internal signals
    reg [W+7:0] mult_result;
    wire [W+7:0] barrel_shift_out;
    
    // Borrow subtractor implementation
    wire [7:0] borrow;
    wire [7:0] complement_alpha;
    wire [W+7:0] alpha_din, complement_alpha_dout;
    
    // Generate complement of ALPHA for borrow subtraction
    assign complement_alpha = 8'd255 - ALPHA;
    
    // Calculate alpha*din
    assign alpha_din = ALPHA * din;
    
    // Calculate (255-ALPHA)*dout using borrow subtraction
    assign complement_alpha_dout[0] = complement_alpha[0] & dout[0];
    assign borrow[0] = ~complement_alpha[0] & dout[0];
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : borrow_subtraction
            assign complement_alpha_dout[i] = (complement_alpha[i] & dout[i % W]) ^ borrow[i-1];
            assign borrow[i] = (~complement_alpha[i] & dout[i % W]) | (borrow[i-1] & ~(complement_alpha[i] ^ dout[i % W]));
        end
    endgenerate
    
    // For higher bits
    generate
        for (i = 8; i < W+8; i = i + 1) begin : higher_bits
            assign complement_alpha_dout[i] = (i < W) ? (complement_alpha[7] & dout[i]) ^ borrow[7] : 1'b0;
        end
    endgenerate
    
    // Calculate multiplication result
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            mult_result <= 0;
        else
            mult_result <= alpha_din + complement_alpha_dout;
    end
    
    // Barrel shifter implementation for right shift by 8
    assign barrel_shift_out = mult_result >> 8;
    
    // Output register
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            dout <= 0;
        else
            dout <= barrel_shift_out[W-1:0];
    end
endmodule