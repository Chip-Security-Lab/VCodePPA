//SystemVerilog
module RangeDetector_Hysteresis #(
    parameter WIDTH = 8,
    parameter HYST = 3
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] center,
    output reg out_high
);

// Calculate threshold boundaries using conditional sum subtraction
wire [WIDTH-1:0] upper = center + HYST;
wire [WIDTH-1:0] lower;

// Conditional sum subtraction for lower threshold calculation
reg [WIDTH-1:0] sum_lower;
reg [WIDTH-1:0] carry_lower;
reg [WIDTH-1:0] result_lower;

// First stage: Generate sum and carry
always @(*) begin
    for (int i = 0; i < WIDTH; i++) begin
        if (i < $clog2(HYST+1)) begin
            // For bits that need to subtract HYST
            sum_lower[i] = center[i] ^ HYST[i];
            carry_lower[i] = center[i] & HYST[i];
        end else begin
            // For bits that don't need to subtract HYST
            sum_lower[i] = center[i];
            carry_lower[i] = 1'b0;
        end
    end
end

// Second stage: Propagate carry and generate result
always @(*) begin
    result_lower = sum_lower;
    for (int i = 0; i < WIDTH-1; i++) begin
        if (carry_lower[i]) begin
            result_lower[i+1] = result_lower[i+1] ^ 1'b1;
            if (i+1 < WIDTH-1) begin
                carry_lower[i+1] = carry_lower[i+1] | (result_lower[i+1] & 1'b1);
            end
        end
    end
end

// Assign the final result to lower threshold
assign lower = result_lower;

// Reset logic
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_high <= 1'b0;
    end
end

// Upper threshold detection
always @(posedge clk) begin
    if(rst_n && data_in >= upper) begin
        out_high <= 1'b1;
    end
end

// Lower threshold detection
always @(posedge clk) begin
    if(rst_n && data_in <= lower) begin
        out_high <= 1'b0;
    end
end

endmodule