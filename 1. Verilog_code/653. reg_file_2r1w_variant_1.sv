//SystemVerilog
module reg_file_2r1w #(
    parameter WIDTH = 32,
    parameter DEPTH = 32
)(
    input clk,
    input [4:0]  ra1,
    output [WIDTH-1:0] rd1,
    input [4:0]  ra2,
    output [WIDTH-1:0] rd2,
    input [4:0]  wa,
    input we,
    input [WIDTH-1:0] wd
);

    // Register file memory
    reg [WIDTH-1:0] rf [0:DEPTH-1];
    
    // Fanout buffers with lookahead carry logic
    reg [WIDTH-1:0] rf_buf1 [0:DEPTH-1];
    reg [WIDTH-1:0] rf_buf2 [0:DEPTH-1];
    
    // Pipeline registers
    reg [4:0] ra1_pipe;
    reg [4:0] ra2_pipe;
    
    // Lookahead carry signals
    wire [WIDTH:0] carry1;
    wire [WIDTH:0] carry2;
    
    // Write path with lookahead carry
    always @(posedge clk) begin
        if (we) begin
            rf[wa] <= wd;
            // Lookahead carry write
            rf_buf1[wa] <= wd ^ carry1[WIDTH-1:0];
            rf_buf2[wa] <= wd ^ carry2[WIDTH-1:0];
        end
        ra1_pipe <= ra1;
        ra2_pipe <= ra2;
    end
    
    // Lookahead carry generation
    assign carry1[0] = 1'b0;
    assign carry2[0] = 1'b0;
    
    genvar i;
    generate
        for(i=0; i<WIDTH; i=i+1) begin: carry_gen
            assign carry1[i+1] = (rf[ra1_pipe][i] & ~rf_buf1[ra1_pipe][i]) | 
                                (carry1[i] & (rf[ra1_pipe][i] | ~rf_buf1[ra1_pipe][i]));
            assign carry2[i+1] = (rf[ra2_pipe][i] & ~rf_buf2[ra2_pipe][i]) |
                                (carry2[i] & (rf[ra2_pipe][i] | ~rf_buf2[ra2_pipe][i]));
        end
    endgenerate
    
    // Read paths with lookahead carry
    assign rd1 = rf_buf1[ra1_pipe] ^ carry1[WIDTH-1:0];
    assign rd2 = rf_buf2[ra2_pipe] ^ carry2[WIDTH-1:0];

endmodule