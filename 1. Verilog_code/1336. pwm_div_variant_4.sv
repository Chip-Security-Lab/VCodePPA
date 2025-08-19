//SystemVerilog
module pwm_div #(
    parameter HIGH = 3,
    parameter LOW = 5
)(
    input  wire clk,
    input  wire rst_n,
    output wire out
);
    // Internal signals
    wire [7:0] cnt_value;
    wire       compare_result;

    // Counter module instance
    pwm_counter #(
        .HIGH(HIGH),
        .LOW(LOW)
    ) counter_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .cnt_out        (cnt_value)
    );

    // Comparator module instance
    pwm_comparator #(
        .HIGH(HIGH)
    ) comparator_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .cnt_in         (cnt_value),
        .compare_out    (compare_result)
    );

    // Output register module instance
    pwm_output_register output_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .compare_in     (compare_result),
        .pwm_out        (out)
    );
endmodule

// Counter module - handles cycle counting with Manchester carry chain adder
module pwm_counter #(
    parameter HIGH = 3,
    parameter LOW = 5
)(
    input  wire       clk,
    input  wire       rst_n,
    output reg  [7:0] cnt_out
);
    // Local parameter for total period
    localparam PERIOD = HIGH + LOW;
    
    // Manchester carry chain adder signals
    wire [7:0] sum;
    wire [7:0] p; // Propagate signals
    wire [7:0] g; // Generate signals
    wire [8:0] c; // Carry signals (including carry-in)
    
    // Generate and propagate signals for Manchester carry chain
    assign p = cnt_out; // Propagate when input bit is 1
    assign g = 8'b0;    // No generate signals for increment
    assign c[0] = 1'b1; // Carry-in for increment operation
    
    // Manchester carry chain implementation
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign c[8] = g[7] | (p[7] & c[7]);
    
    // Sum calculation
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];
    
    // Counter update logic
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt_out <= 8'd0;
        end else begin
            cnt_out <= (cnt_out == PERIOD-1) ? 8'd0 : sum;
        end
    end
endmodule

// Comparator module - compares counter value with HIGH parameter
module pwm_comparator #(
    parameter HIGH = 3
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] cnt_in,
    output reg        compare_out
);
    // Buffered counter values to reduce fan-out
    reg [7:0] cnt_buf;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            cnt_buf <= 8'd0;
            compare_out <= 1'b0;
        end else begin
            // Buffer the counter value
            cnt_buf <= cnt_in;
            
            // Pre-compute comparison result using buffered value
            compare_out <= (cnt_buf < HIGH);
        end
    end
endmodule

// Output register module - registers the final PWM output
module pwm_output_register (
    input  wire clk,
    input  wire rst_n,
    input  wire compare_in,
    output reg  pwm_out
);
    always @(posedge clk) begin
        if (!rst_n) begin
            pwm_out <= 1'b0;
        end else begin
            pwm_out <= compare_in;
        end
    end
endmodule