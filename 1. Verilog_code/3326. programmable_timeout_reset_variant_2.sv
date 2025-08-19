//SystemVerilog
module programmable_timeout_reset_pipeline #(
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

    // Stage 1: Pipeline input signals
    reg  [31:0] timeout_ms_s1;
    reg         enable_s1, trigger_s1, clear_s1;
    reg         valid_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_ms_s1   <= 32'd0;
            enable_s1       <= 1'b0;
            trigger_s1      <= 1'b0;
            clear_s1        <= 1'b0;
            valid_s1        <= 1'b0;
        end else begin
            timeout_ms_s1   <= timeout_ms;
            enable_s1       <= enable;
            trigger_s1      <= timeout_trigger;
            clear_s1        <= timeout_clear;
            valid_s1        <= 1'b1;
        end
    end

    // Stage 2: Compute timeout_cycles, pipeline control
    reg [31:0] timeout_cycles_s2;
    reg        enable_s2, trigger_s2, clear_s2;
    reg        valid_s2;

    wire [31:0] cycles_per_ms = CLK_FREQ / 1000;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_cycles_s2 <= 32'd0;
            enable_s2         <= 1'b0;
            trigger_s2        <= 1'b0;
            clear_s2          <= 1'b0;
            valid_s2          <= 1'b0;
        end else begin
            timeout_cycles_s2 <= timeout_ms_s1 * cycles_per_ms;
            enable_s2         <= enable_s1;
            trigger_s2        <= trigger_s1;
            clear_s2          <= clear_s1;
            valid_s2          <= valid_s1;
        end
    end

    // Stage 3: Optimized FSM logic
    reg [31:0] counter_s3;
    reg        timeout_active_s3;
    reg        reset_out_s3;
    reg        valid_s3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_s3         <= 32'd0;
            timeout_active_s3  <= 1'b0;
            reset_out_s3       <= 1'b0;
            valid_s3           <= 1'b0;
        end else begin
            valid_s3 <= valid_s2;

            // Highest priority: disable or clear
            if (!enable_s2 || clear_s2) begin
                counter_s3         <= 32'd0;
                timeout_active_s3  <= 1'b0;
                reset_out_s3       <= 1'b0;
            end
            // Start timing on trigger
            else if (trigger_s2 && !timeout_active_s3) begin
                counter_s3         <= 32'd1;
                timeout_active_s3  <= 1'b1;
                reset_out_s3       <= 1'b0;
            end
            // Timing in progress
            else if (timeout_active_s3) begin
                // Use efficient range check
                if (counter_s3 < timeout_cycles_s2) begin
                    counter_s3         <= counter_s3 + 32'd1;
                    timeout_active_s3  <= 1'b1;
                    reset_out_s3       <= 1'b0;
                end else begin
                    // Timeout reached: assert reset
                    counter_s3         <= counter_s3;
                    timeout_active_s3  <= 1'b1;
                    reset_out_s3       <= 1'b1;
                end
            end
            // Default: hold state
            else begin
                counter_s3         <= counter_s3;
                timeout_active_s3  <= timeout_active_s3;
                reset_out_s3       <= reset_out_s3;
            end
        end
    end

    // Stage 4: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_out      <= 1'b0;
            timeout_active <= 1'b0;
        end else if (valid_s3) begin
            reset_out      <= reset_out_s3;
            timeout_active <= timeout_active_s3;
        end
    end

endmodule