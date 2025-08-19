//SystemVerilog
module duty_cycle_controller(
    input  wire         clock_in,
    input  wire         reset,
    input  wire [3:0]   duty_cycle, // 0-15 (0%-93.75%)
    output reg          clock_out
);

    // ================================
    // Pipeline Stage 1: Counter Update
    // ================================
    reg  [3:0] counter_stage1;
    reg        reset_stage1;
    always @(posedge clock_in) begin
        reset_stage1 <= reset;
        if (reset) begin
            counter_stage1 <= 4'd0;
        end else if (counter_stage1 < 4'd15) begin
            counter_stage1 <= counter_stage1 + 1'b1;
        end else begin
            counter_stage1 <= 4'd0;
        end
    end

    // ==========================================
    // Pipeline Stage 2: Duty Cycle Comparison
    // ==========================================
    reg [3:0] counter_stage2;
    reg [3:0] duty_cycle_stage2;
    reg       reset_stage2;
    always @(posedge clock_in) begin
        counter_stage2     <= counter_stage1;
        duty_cycle_stage2  <= duty_cycle;
        reset_stage2       <= reset_stage1;
    end

    // ==========================================
    // Pipeline Stage 3: Output Register Update
    // ==========================================
    always @(posedge clock_in) begin
        if (reset_stage2) begin
            clock_out <= 1'b0;
        end else begin
            clock_out <= (counter_stage2 < duty_cycle_stage2) ? 1'b1 : 1'b0;
        end
    end

endmodule