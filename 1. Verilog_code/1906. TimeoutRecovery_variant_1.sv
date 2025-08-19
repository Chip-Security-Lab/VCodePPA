//SystemVerilog
//IEEE 1364-2005 Verilog
// Top-level module
module TimeoutRecovery #(
    parameter WIDTH = 8,
    parameter TIMEOUT = 32'hFFFF
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [WIDTH-1:0]  unstable_in,
    output wire [WIDTH-1:0]  stable_out,
    output wire              timeout
);
    // Internal signals
    wire [31:0] counter_value;
    wire        timeout_detected;
    wire [WIDTH-1:0] output_value;
    
    // Instantiate the counter module
    StabilityCounter #(
        .TIMEOUT(TIMEOUT)
    ) counter_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .current_value (stable_out),
        .new_value     (unstable_in),
        .counter       (counter_value),
        .timeout_flag  (timeout_detected)
    );
    
    // Instantiate the output generator module
    OutputGenerator #(
        .WIDTH(WIDTH)
    ) output_gen_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .unstable_in   (unstable_in),
        .timeout       (timeout_detected),
        .stable_out    (output_value)
    );
    
    // Output assignments
    assign stable_out = output_value;
    assign timeout = timeout_detected;
    
endmodule

// Counter module for stability timing with two's complement subtraction
module StabilityCounter #(
    parameter TIMEOUT = 32'hFFFF
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [7:0]        current_value,
    input  wire [7:0]        new_value,
    output reg  [31:0]       counter,
    output wire              timeout_flag
);
    // Internal signals for two's complement subtraction
    wire [7:0] inverted_current;
    wire [7:0] complement_current;
    wire [7:0] value_diff;
    wire       values_equal;
    
    // Implement two's complement subtraction to compare values
    assign inverted_current = ~current_value;
    assign complement_current = inverted_current + 8'h01;
    assign value_diff = new_value + complement_current; // new_value - current_value in two's complement
    assign values_equal = (value_diff == 8'h00);
    
    // Counter logic using comparison result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'h0;
        end else begin
            counter <= (!values_equal) ? 32'h0 : counter + 32'h1;
        end
    end
    
    // Timeout detection using two's complement subtraction
    wire [31:0] timeout_inverted;
    wire [31:0] timeout_complement;
    wire [31:0] timeout_diff;
    
    assign timeout_inverted = ~TIMEOUT;
    assign timeout_complement = timeout_inverted + 32'h1;
    assign timeout_diff = counter + timeout_complement; // counter - TIMEOUT in two's complement
    
    // Timeout flag is set when counter >= TIMEOUT (diff is not negative)
    assign timeout_flag = ~timeout_diff[31]; // MSB is 0 when result is non-negative
    
endmodule

// Output generation module
module OutputGenerator #(
    parameter WIDTH = 8
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [WIDTH-1:0]  unstable_in,
    input  wire              timeout,
    output reg  [WIDTH-1:0]  stable_out
);
    // Output register logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stable_out <= {WIDTH{1'b0}};
        end else begin
            stable_out <= timeout ? stable_out : unstable_in;
        end
    end
    
endmodule