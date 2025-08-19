//SystemVerilog
module lfsr_sequence_gen #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] TAPS = 8'b10111000 // Default polynomial: x^8 + x^6 + x^5 + x^4 + 1
) (
    input  wire clk_i,
    input  wire rst_n,
    input  wire enable,
    input  wire [WIDTH-1:0] seed_i,
    input  wire load_seed,
    output wire [WIDTH-1:0] random_o,
    output wire bit_o
);
    // Main LFSR register
    reg [WIDTH-1:0] lfsr_reg;
    
    // Buffered copies of LFSR register for different loads
    reg [WIDTH-1:0] lfsr_buf1;
    reg [WIDTH-1:0] lfsr_buf2;
    
    wire feedback;
    
    // LFSR feedback calculation based on taps using buffered registers
    assign feedback = ^(lfsr_buf1 & TAPS);
    
    // Output assignments using different buffers to balance load
    assign random_o = lfsr_buf2;
    assign bit_o = lfsr_buf2[0];
    
    // Main LFSR register update
    always @(posedge clk_i or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= {WIDTH{1'b0}};
        end
        else if (load_seed) begin
            if (seed_i != 0) begin
                lfsr_reg <= seed_i;
            end
            else begin
                lfsr_reg <= {{(WIDTH-1){1'b0}}, 1'b1};
            end
        end
        else if (enable) begin
            lfsr_reg <= {feedback, lfsr_reg[WIDTH-1:1]};
        end
    end
    
    // Buffer 1 for feedback calculation
    always @(posedge clk_i or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_buf1 <= {WIDTH{1'b0}};
        end
        else begin
            lfsr_buf1 <= lfsr_reg;
        end
    end
    
    // Buffer 2 for output assignments
    always @(posedge clk_i or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_buf2 <= {WIDTH{1'b0}};
        end
        else begin
            lfsr_buf2 <= lfsr_buf1;
        end
    end
endmodule