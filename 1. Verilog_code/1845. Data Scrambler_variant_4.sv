//SystemVerilog
module data_scrambler #(parameter POLY_WIDTH = 7) (
    input  wire clk,
    input  wire reset,
    input  wire data_in,
    input  wire [POLY_WIDTH-1:0] polynomial,  // Configurable polynomial
    input  wire [POLY_WIDTH-1:0] initial_state,
    input  wire load_init,
    output wire data_out
);
    reg [POLY_WIDTH-1:0] lfsr_reg;
    wire feedback;
    
    // Buffered registers for high fanout lfsr_reg signals
    reg [POLY_WIDTH-1:0] lfsr_buf1, lfsr_buf2;
    
    // Calculate feedback based on polynomial taps using buffered version
    assign feedback = ^(lfsr_buf1 & polynomial);
    
    // Scramble the data by XORing with LFSR output using buffered version
    assign data_out = data_in ^ lfsr_buf2[0];
    
    // Main LFSR register update logic
    always @(posedge clk) begin
        if (reset)
            lfsr_reg <= {POLY_WIDTH{1'b1}};  // Non-zero default
        else if (load_init)
            lfsr_reg <= initial_state;
        else
            lfsr_reg <= {feedback, lfsr_reg[POLY_WIDTH-1:1]};
    end
    
    // Buffer registers to distribute fanout load
    always @(posedge clk) begin
        if (reset) begin
            lfsr_buf1 <= {POLY_WIDTH{1'b1}};
            lfsr_buf2 <= {POLY_WIDTH{1'b1}};
        end
        else begin
            lfsr_buf1 <= lfsr_reg;  // Buffer for feedback calculation
            lfsr_buf2 <= lfsr_reg;  // Buffer for data_out generation
        end
    end
endmodule