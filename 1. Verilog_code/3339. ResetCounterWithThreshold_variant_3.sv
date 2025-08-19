//SystemVerilog
module ResetCounterWithThreshold #(
    parameter THRESHOLD = 10
) (
    input wire clk,
    input wire rst_n,
    output wire reset_detected
);

    reg [3:0] counter_reg;
    reg [3:0] counter_buf1;
    reg [3:0] counter_buf2;
    reg reset_detected_reg;
    reg reset_detected_buf;

    // Counter register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter_reg <= 4'b0;
        else if (counter_reg < THRESHOLD)
            counter_reg <= counter_reg + 1'b1;
    end

    // Buffer stage 1 for counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter_buf1 <= 4'b0;
        else
            counter_buf1 <= counter_reg;
    end

    // Buffer stage 2 for counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter_buf2 <= 4'b0;
        else
            counter_buf2 <= counter_buf1;
    end

    // Detect threshold crossing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_detected_reg <= 1'b0;
        else
            reset_detected_reg <= (counter_buf2 >= THRESHOLD);
    end

    // Output buffer for reset_detected
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_detected_buf <= 1'b0;
        else
            reset_detected_buf <= reset_detected_reg;
    end

    assign reset_detected = reset_detected_buf;

endmodule