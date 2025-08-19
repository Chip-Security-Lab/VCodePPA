//SystemVerilog
module multicycle_sync #(parameter WIDTH = 24, CYCLES = 2) (
    input wire fast_clk,
    input wire slow_clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_fast,
    input wire update_fast,
    output reg [WIDTH-1:0] data_slow
);

    reg update_toggle;
    reg [2:0] update_sync;
    reg update_slow;
    reg [$clog2(CYCLES):0] cycle_counter;
    reg [WIDTH-1:0] data_fast_latched;
    reg [WIDTH-1:0] data_sync_reg;

    // Fast clock domain: latch update and data
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            update_toggle <= 1'b0;
            data_fast_latched <= {WIDTH{1'b0}};
        end else if (update_fast) begin
            update_toggle <= ~update_toggle;
            data_fast_latched <= data_fast;
        end
    end

    // Slow clock domain: synchronize and multicycle delay
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            update_sync    <= 3'b000;
            update_slow    <= 1'b0;
            cycle_counter  <= {($clog2(CYCLES)+1){1'b0}};
            data_sync_reg  <= {WIDTH{1'b0}};
            data_slow      <= {WIDTH{1'b0}};
        end else begin
            update_sync <= {update_sync[1:0], update_toggle};

            // Detect toggle edge
            if (update_sync[2] ^ update_sync[1]) begin
                update_slow   <= 1'b1;
                data_sync_reg <= data_fast_latched;
                cycle_counter <= {($clog2(CYCLES)+1){1'b0}};
            end else if (update_slow) begin
                if (cycle_counter >= (CYCLES-1)) begin
                    update_slow   <= 1'b0;
                    data_slow     <= data_sync_reg;
                    cycle_counter <= {($clog2(CYCLES)+1){1'b0}};
                end else begin
                    cycle_counter <= cycle_counter + 1'b1;
                end
            end
        end
    end

endmodule