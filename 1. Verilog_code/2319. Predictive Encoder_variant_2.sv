//SystemVerilog
module predictive_encoder #(
    parameter DATA_WIDTH = 12
)(
    input                       clk,
    input                       reset,
    input  [DATA_WIDTH-1:0]     sample_in,
    input                       in_valid,
    output reg [DATA_WIDTH-1:0] residual_out,
    output reg                  out_valid
);
    // Sample history registers
    reg [DATA_WIDTH-1:0] prev_samples [0:3];
    
    // Prediction calculation signals
    wire [DATA_WIDTH-1:0] prediction;
    wire [DATA_WIDTH+1:0] sum_temp; // Extra width for addition
    
    // Residual calculation signals
    wire [DATA_WIDTH:0] difference;
    wire sample_greater_equal;
    
    // Optimize sum calculation using direct assignments and addition
    assign sum_temp = prev_samples[0] + prev_samples[1] + prev_samples[2] + prev_samples[3];
    assign prediction = sum_temp >> 2;
    
    // Signed difference calculation optimized
    assign sample_greater_equal = (sample_in >= prediction);
    assign difference = sample_greater_equal ? 
                      {1'b0, sample_in - prediction} : 
                      {1'b1, (~(prediction - sample_in) + 1'b1)};

    // Reset control logic
    always @(posedge clk) begin
        if (reset) begin
            prev_samples[0] <= 0;
            prev_samples[1] <= 0;
            prev_samples[2] <= 0;
            prev_samples[3] <= 0;
        end
    end
    
    // Sample history update logic
    always @(posedge clk) begin
        if (!reset && in_valid) begin
            // Shift register implementation for sample history
            prev_samples[3] <= prev_samples[2];
            prev_samples[2] <= prev_samples[1];
            prev_samples[1] <= prev_samples[0];
            prev_samples[0] <= sample_in;
        end
    end
    
    // Residual output calculation logic
    always @(posedge clk) begin
        if (reset) begin
            residual_out <= 0;
        end else if (in_valid) begin
            // Simplified residual calculation using the pre-computed difference
            residual_out <= difference[DATA_WIDTH-1:0];
        end
    end
    
    // Output valid signal control
    always @(posedge clk) begin
        if (reset) begin
            out_valid <= 0;
        end else begin
            out_valid <= in_valid;
        end
    end
    
endmodule