//SystemVerilog
module data_descrambler #(parameter POLY_WIDTH = 7) (
    input  wire clk_in,
    input  wire rst_n,
    input  wire scrambled_in,
    input  wire [POLY_WIDTH-1:0] poly_taps,
    input  wire [POLY_WIDTH-1:0] seed_val,
    input  wire seed_load,
    output reg  descrambled_out
);

    reg [POLY_WIDTH-1:0] shift_reg;
    reg [POLY_WIDTH-1:0] shift_reg_buf1;
    reg [POLY_WIDTH-1:0] shift_reg_buf2;
    reg tap_xor_reg;
    wire tap_xor;
    reg scrambled_in_reg;
    
    // Pipeline stage 1: Register input and calculate tap XOR
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            scrambled_in_reg <= 1'b0;
            tap_xor_reg <= 1'b0;
        end else begin
            scrambled_in_reg <= scrambled_in;
            tap_xor_reg <= ^(shift_reg & poly_taps);
        end
    end

    // Main shift register logic with pipelined tap XOR
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= {POLY_WIDTH{1'b1}};
        else if (seed_load)
            shift_reg <= seed_val;
        else
            shift_reg <= {tap_xor_reg, shift_reg[POLY_WIDTH-1:1]};
    end
    
    // First level buffer
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            shift_reg_buf1 <= {POLY_WIDTH{1'b1}};
        else
            shift_reg_buf1 <= shift_reg;
    end
    
    // Second level buffer
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            shift_reg_buf2 <= {POLY_WIDTH{1'b1}};
        else
            shift_reg_buf2 <= shift_reg_buf1;
    end

    // Pipeline stage 2: Register descrambled output
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            descrambled_out <= 1'b0;
        else
            descrambled_out <= scrambled_in_reg ^ shift_reg_buf2[0];
    end

endmodule