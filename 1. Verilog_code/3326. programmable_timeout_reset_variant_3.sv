//SystemVerilog
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

    reg  [31:0] counter = 32'h00000000;
    wire [31:0] timeout_cycles;
    reg         timeout_triggered_sync;

    assign timeout_cycles = timeout_ms * (CLK_FREQ / 1000);

    // Timeout Trigger Latch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_triggered_sync <= 1'b0;
        end else if (!enable || timeout_clear) begin
            timeout_triggered_sync <= 1'b0;
        end else if (timeout_trigger && !timeout_active) begin
            timeout_triggered_sync <= 1'b1;
        end else if (timeout_active) begin
            timeout_triggered_sync <= 1'b0;
        end
    end

    // Timeout Active Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_active <= 1'b0;
        end else if (!enable || timeout_clear) begin
            timeout_active <= 1'b0;
        end else if (timeout_trigger && !timeout_active) begin
            timeout_active <= 1'b1;
        end else if (timeout_active && (counter >= timeout_cycles)) begin
            timeout_active <= 1'b0;
        end
    end

    // Counter Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'h00000000;
        end else if (!enable || timeout_clear) begin
            counter <= 32'h00000000;
        end else if (timeout_trigger && !timeout_active) begin
            counter <= 32'h00000001;
        end else if (timeout_active) begin
            if (counter < timeout_cycles) begin
                counter <= counter + 32'h00000001;
            end
        end else begin
            counter <= 32'h00000000;
        end
    end

    // Reset Output Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_out <= 1'b0;
        end else if (!enable || timeout_clear) begin
            reset_out <= 1'b0;
        end else if (timeout_trigger && !timeout_active) begin
            reset_out <= 1'b0;
        end else if (timeout_active && (counter >= timeout_cycles)) begin
            reset_out <= 1'b1;
        end else begin
            reset_out <= 1'b0;
        end
    end

endmodule