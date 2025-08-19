//SystemVerilog
module sync_kalman_filter #(
    parameter DATA_W = 16,
    parameter FRAC_BITS = 8
)(
    input clk, reset,
    input [DATA_W-1:0] measurement,
    input [DATA_W-1:0] process_noise,
    input [DATA_W-1:0] measurement_noise,
    output reg [DATA_W-1:0] estimate
);
    reg [DATA_W-1:0] prediction, error, gain;
    wire [DATA_W-1:0] innovation;
    wire borrow_out;
    
    // Innovation calculation using conditional inversion subtractor
    conditional_inv_subtractor #(
        .WIDTH(DATA_W)
    ) innovation_subtractor (
        .minuend(measurement),
        .subtrahend(prediction),
        .difference(innovation),
        .borrow_out(borrow_out)
    );
    
    always @(posedge clk) begin
        if (reset) begin
            prediction <= 0;
            estimate <= 0;
            error <= measurement_noise;
            gain <= 0;
        end else begin
            prediction <= estimate;
            error <= error + process_noise;
            gain <= (error << FRAC_BITS) / (error + measurement_noise);
            estimate <= prediction + ((gain * innovation) >> FRAC_BITS);
            error <= ((1 << FRAC_BITS) - gain) * error >> FRAC_BITS;
        end
    end
endmodule

module conditional_inv_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference,
    output borrow_out
);
    wire [WIDTH-1:0] inv_subtrahend;
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] sum;
    
    // Conditional inversion of subtrahend
    assign inv_subtrahend = ~subtrahend;
    
    // Carry chain for addition
    assign carry[0] = 1'b1; // Add 1 for two's complement
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: add_bit
            assign sum[i] = minuend[i] ^ inv_subtrahend[i] ^ carry[i];
            assign carry[i+1] = (minuend[i] & inv_subtrahend[i]) |
                               (minuend[i] & carry[i]) |
                               (inv_subtrahend[i] & carry[i]);
        end
    endgenerate
    
    assign difference = sum;
    assign borrow_out = ~carry[WIDTH];
endmodule