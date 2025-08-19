//SystemVerilog
module async_peak_detector #(
    parameter W = 12
)(
    input clk,
    input [W-1:0] signal_in,
    input [W-1:0] current_peak,
    input reset_peak,
    output reg [W-1:0] peak_out
);

    // Pipeline stage 1: Input registration
    reg [W-1:0] signal_in_reg;
    reg [W-1:0] current_peak_reg;
    reg reset_peak_reg;
    
    // Pipeline stage 2: Comparison
    wire [W-1:0] subtraction_result;
    wire borrow_out;
    reg [W-1:0] subtraction_result_reg;
    reg borrow_out_reg;
    
    // Pipeline stage 3: Peak selection
    reg [W-1:0] new_peak_candidate;
    
    // Stage 1: Input registration
    always @(posedge clk) begin
        signal_in_reg <= signal_in;
        current_peak_reg <= current_peak;
        reset_peak_reg <= reset_peak;
    end
    
    // Stage 2: Comparison
    parallel_borrow_subtractor #(
        .WIDTH(W)
    ) subtractor (
        .minuend(signal_in_reg),
        .subtrahend(current_peak_reg),
        .difference(subtraction_result),
        .borrow_out(borrow_out)
    );
    
    always @(posedge clk) begin
        subtraction_result_reg <= subtraction_result;
        borrow_out_reg <= borrow_out;
    end
    
    // Stage 3: Peak selection
    always @(posedge clk) begin
        new_peak_candidate <= (~borrow_out_reg) ? signal_in_reg : current_peak_reg;
        peak_out <= reset_peak_reg ? signal_in_reg : new_peak_candidate;
    end

endmodule

module parallel_borrow_subtractor #(
    parameter WIDTH = 12
)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference,
    output borrow_out
);

    wire [WIDTH:0] borrow;
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: sub_bits
            assign difference[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
            assign borrow[i+1] = (~minuend[i] & (subtrahend[i] | borrow[i])) | (subtrahend[i] & borrow[i]);
        end
    endgenerate
    
    assign borrow_out = borrow[WIDTH];
endmodule