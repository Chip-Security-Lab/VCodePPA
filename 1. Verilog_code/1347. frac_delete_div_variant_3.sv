//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: frac_delete_div
// Description: Fractional clock divider with optimized pipelined architecture
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module frac_delete_div #(
    parameter ACC_WIDTH = 8,      // Accumulator width
    parameter INCREMENT = 3        // Increment value (configurable fraction)
) (
    input  wire                clk,        // Input clock
    input  wire                rst,        // Synchronous reset
    input  wire                enable,     // Pipeline enable signal
    output reg                 clk_out,    // Output divided clock
    output reg                 valid_out   // Valid output indicator
);

    // Accumulator and comparison logic
    reg [ACC_WIDTH-1:0] acc;               // Accumulator 
    wire [ACC_WIDTH-1:0] next_acc;         // Next accumulator value
    wire                 compare_result;   // Comparison result
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    
    // Threshold constant for duty cycle control
    localparam [ACC_WIDTH-1:0] THRESHOLD = {1'b1, {(ACC_WIDTH-1){1'b0}}}; // 0x80 for 8-bit
    
    // Move combinational logic before registers (forward retiming)
    assign next_acc = acc + INCREMENT;     // Fractional accumulation
    assign compare_result = (next_acc < THRESHOLD);
    
    // Accumulator register - moved after combinational logic
    always @(posedge clk) begin
        if (rst) begin
            acc <= {ACC_WIDTH{1'b0}};      // Clear accumulator on reset
            valid_stage1 <= 1'b0;
        end else if (enable) begin
            acc <= next_acc;               // Store next accumulator value
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Store comparison result
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
            clk_out <= 1'b0;
        end else if (enable) begin
            valid_stage2 <= valid_stage1;
            clk_out <= compare_result;     // Register comparison result
        end
    end
    
    // Output stage 
    always @(posedge clk) begin
        if (rst) begin
            valid_out <= 1'b0;
        end else if (enable) begin
            valid_out <= valid_stage2;
        end
    end

endmodule