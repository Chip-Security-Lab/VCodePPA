//SystemVerilog
module multicycle_sync #(
    parameter WIDTH = 24,
    parameter CYCLES = 2
)(
    input  wire                  fast_clk,
    input  wire                  slow_clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      data_fast,
    input  wire                  update_fast,
    output reg  [WIDTH-1:0]      data_slow
);

    // =========================
    // Fast Clock Domain Stage
    // =========================

    // Stage 1: Capture update event and data in fast clock domain
    reg update_toggle_ff;
    reg [WIDTH-1:0] data_fast_ff;

    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            update_toggle_ff <= 1'b0;
            data_fast_ff     <= {WIDTH{1'b0}};
        end else if (update_fast) begin
            update_toggle_ff <= ~update_toggle_ff;
            data_fast_ff     <= data_fast;
        end
    end

    // =========================
    // CDC: Toggle Synchronization to Slow Clock Domain
    // =========================

    // Stage 2: Synchronize toggle to slow domain (three-stage synchronizer)
    reg update_toggle_sync_1;
    reg update_toggle_sync_2;
    reg update_toggle_sync_3;

    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            update_toggle_sync_1 <= 1'b0;
            update_toggle_sync_2 <= 1'b0;
            update_toggle_sync_3 <= 1'b0;
        end else begin
            update_toggle_sync_1 <= update_toggle_ff;
            update_toggle_sync_2 <= update_toggle_sync_1;
            update_toggle_sync_3 <= update_toggle_sync_2;
        end
    end

    // Stage 3: Edge detection in slow domain
    wire update_edge_slow;
    assign update_edge_slow = (update_toggle_sync_3 != update_toggle_sync_2);

    // =========================
    // Slow Clock Domain Pipeline
    // =========================

    // Stage 4: Latch multicycle update event
    reg update_pending_slow;
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n)
            update_pending_slow <= 1'b0;
        else if (update_edge_slow)
            update_pending_slow <= 1'b1;
        else if (update_pending_slow && cycle_count_reg == (CYCLES-1))
            update_pending_slow <= 1'b0;
    end

    // Stage 5: Multicycle counter in slow domain
    reg [$clog2(CYCLES):0] cycle_count_reg;
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n)
            cycle_count_reg <= {($clog2(CYCLES)+1){1'b0}};
        else if (update_pending_slow) begin
            if (cycle_count_reg == (CYCLES-1))
                cycle_count_reg <= {($clog2(CYCLES)+1){1'b0}};
            else
                cycle_count_reg <= cycle_count_reg + 1'b1;
        end else
            cycle_count_reg <= {($clog2(CYCLES)+1){1'b0}};
    end

    // Stage 6: Pipeline register for data in slow domain
    reg [WIDTH-1:0] data_fast_sync_ff;
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n)
            data_fast_sync_ff <= {WIDTH{1'b0}};
        else if (update_edge_slow)
            data_fast_sync_ff <= data_fast_ff;
    end

    // Stage 7: Output register update
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n)
            data_slow <= {WIDTH{1'b0}};
        else if (update_pending_slow && cycle_count_reg == (CYCLES-1))
            data_slow <= data_fast_sync_ff;
    end

endmodule