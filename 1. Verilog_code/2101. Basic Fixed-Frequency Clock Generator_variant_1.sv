//SystemVerilog
// Top-level clock generator module with hierarchical structure
module basic_clock_gen(
    output wire clk_out,
    input wire rst_n
);
    parameter HALF_PERIOD = 5;

    wire clk_gen_out;
    wire clk_rst_out;

    // Clock toggling submodule
    clk_toggler #(
        .HALF_PERIOD(HALF_PERIOD)
    ) u_clk_toggler (
        .clk_raw(clk_gen_out)
    );

    // Asynchronous reset synchronizer submodule
    clk_reset_sync u_clk_reset_sync (
        .clk_raw(clk_gen_out),
        .rst_n(rst_n),
        .clk_out(clk_rst_out)
    );

    assign clk_out = clk_rst_out;

endmodule

// -----------------------------------------------------------------------------
// clk_toggler: Generates a free-running clock by toggling every HALF_PERIOD
// Optimized for simulation efficiency and hardware clarity
// -----------------------------------------------------------------------------
module clk_toggler #(
    parameter HALF_PERIOD = 5
)(
    output reg clk_raw
);
    initial clk_raw = 1'b0;

    always begin
        #(HALF_PERIOD) clk_raw = ~clk_raw;
    end
endmodule

// -----------------------------------------------------------------------------
// clk_reset_sync: Handles asynchronous reset for the generated clock
// Optimized comparison and assignment logic
// -----------------------------------------------------------------------------
module clk_reset_sync(
    input wire clk_raw,
    input wire rst_n,
    output reg clk_out
);
    always @(posedge clk_raw or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            clk_out <= 1'b0;
        end else begin
            clk_out <= 1'b1;
        end
    end
endmodule