//SystemVerilog - IEEE 1364-2005
// Top-level module
module frac_div #(parameter M=3, N=7) (
    input  wire clk,
    input  wire rst,
    output wire out
);
    // Internal signals
    wire [7:0] acc_value;
    wire       acc_overflow;
    
    // Accumulator submodule
    accumulator_unit #(
        .M(M),
        .N(N)
    ) acc_inst (
        .clk(clk),
        .rst(rst),
        .acc_value(acc_value),
        .acc_overflow(acc_overflow)
    );
    
    // Output generation submodule
    output_gen out_inst (
        .clk(clk),
        .rst(rst),
        .acc_overflow(acc_overflow),
        .out(out)
    );
    
endmodule

// Accumulator module - handles the accumulation logic
module accumulator_unit #(
    parameter M=3,  // Increment value
    parameter N=7   // Threshold value
)(
    input  wire       clk,
    input  wire       rst,
    output reg  [7:0] acc_value,
    output wire       acc_overflow
);
    // Pre-calculate potential next values to reduce critical path
    wire [7:0] next_value_no_overflow = acc_value + M;
    wire [7:0] next_value_with_overflow = acc_value + M - N;
    
    // Determine if accumulator exceeds threshold
    // Move comparison before calculation to break long path
    assign acc_overflow = (acc_value >= N - M) && (acc_value < N);
    
    // Accumulator logic with parallel path computation
    always @(posedge clk) begin
        if (rst) begin
            acc_value <= 8'b0;
        end
        else if (acc_value >= N) begin
            // Direct assignment when overflow is definite
            acc_value <= acc_value + M - N;
        end
        else if (acc_value >= (N - M)) begin
            // Potential overflow case
            acc_value <= acc_value + M - N;
        end
        else begin
            // No overflow case
            acc_value <= acc_value + M;
        end
    end
endmodule

// Output generation module - produces the divided clock
module output_gen (
    input  wire clk,
    input  wire rst,
    input  wire acc_overflow,
    output reg  out
);
    // Register for improved timing
    reg acc_overflow_reg;
    
    // Pipeline the overflow signal to improve timing
    always @(posedge clk) begin
        if (rst) begin
            acc_overflow_reg <= 1'b0;
            out <= 1'b0;
        end
        else begin
            acc_overflow_reg <= acc_overflow;
            out <= acc_overflow_reg;
        end
    end
endmodule