//SystemVerilog
// SystemVerilog
module programmable_timeout_reset #(
    parameter CLK_FREQ = 100000
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [31:0] timeout_ms,
    input  wire        timeout_trigger,
    input  wire        timeout_clear,
    output reg         reset_out,
    output reg         timeout_active
);

    reg  [31:0] counter;
    wire [31:0] timeout_cycles;
    assign timeout_cycles = timeout_ms * (CLK_FREQ / 1000);

    //-----------------------------------------------------------------------------
    // Timeout Active Control Block
    // Controls the state of timeout_active signal
    //-----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_active <= 1'b0;
        end else if (!enable || timeout_clear) begin
            timeout_active <= 1'b0;
        end else if (timeout_trigger && !timeout_active) begin
            timeout_active <= 1'b1;
        end
    end

    //-----------------------------------------------------------------------------
    // Counter Control Block
    // Handles counting cycles after timeout is triggered and active
    //-----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'd0;
        end else if (!enable || timeout_clear) begin
            counter <= 32'd0;
        end else if (timeout_trigger && !timeout_active) begin
            counter <= 32'd1;
        end else if (timeout_active) begin
            if (counter < timeout_cycles) begin
                counter <= counter + 32'd1;
            end
        end
    end

    //-----------------------------------------------------------------------------
    // Reset Output Control Block
    // Drives the reset_out signal based on counter and timeout_active
    //-----------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_out <= 1'b0;
        end else if (!enable || timeout_clear) begin
            reset_out <= 1'b0;
        end else if (timeout_trigger && !timeout_active) begin
            reset_out <= 1'b0;
        end else if (timeout_active) begin
            if (counter < timeout_cycles) begin
                reset_out <= 1'b0;
            end else begin
                reset_out <= 1'b1;
            end
        end
    end

endmodule