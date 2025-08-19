//SystemVerilog
// SystemVerilog
module lfsr_sequence_gen #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] TAPS = 8'b10111000 // Polynomial: x^8 + x^6 + x^5 + x^4 + 1
) (
    input  wire clk_i,
    input  wire rst_n,
    input  wire enable,
    input  wire [WIDTH-1:0] seed_i,
    input  wire load_seed,
    output wire [WIDTH-1:0] random_o,
    output wire bit_o
);
    // Control and data path signals
    reg [WIDTH-1:0] lfsr_reg;
    reg [WIDTH-1:0] lfsr_next;
    reg [WIDTH-1:0] seed_reg;
    
    // Feedback path signals
    wire feedback_bit;
    reg  feedback_reg;
    
    // Output registers for better timing
    reg [WIDTH-1:0] random_reg;
    reg bit_reg;
    
    // Stage 1: Calculate feedback bit
    assign feedback_bit = ^(lfsr_reg & TAPS);
    
    // Stage 2: Compute next LFSR state based on control signals
    always @(*) begin
        if (load_seed)
            lfsr_next = (seed_reg != 0) ? seed_reg : {{(WIDTH-1){1'b0}}, 1'b1};
        else if (enable)
            lfsr_next = {feedback_reg, lfsr_reg[WIDTH-1:1]};
        else
            lfsr_next = lfsr_reg;
    end
    
    // Stage 3: Update seed register
    always @(posedge clk_i or negedge rst_n) begin
        if (!rst_n)
            seed_reg <= {WIDTH{1'b0}};
        else if (load_seed)
            seed_reg <= seed_i;
    end
    
    // Stage 4: Update feedback register
    always @(posedge clk_i or negedge rst_n) begin
        if (!rst_n)
            feedback_reg <= 1'b0;
        else
            feedback_reg <= feedback_bit;
    end
    
    // Stage 5: Update LFSR state
    always @(posedge clk_i or negedge rst_n) begin
        if (!rst_n)
            lfsr_reg <= {WIDTH{1'b0}};
        else
            lfsr_reg <= lfsr_next;
    end
    
    // Stage 6: Update output registers
    always @(posedge clk_i or negedge rst_n) begin
        if (!rst_n) begin
            random_reg <= {WIDTH{1'b0}};
            bit_reg <= 1'b0;
        end
        else begin
            random_reg <= lfsr_reg;
            bit_reg <= lfsr_reg[0];
        end
    end
    
    // Stage 7: Drive outputs
    assign random_o = random_reg;
    assign bit_o = bit_reg;
    
endmodule