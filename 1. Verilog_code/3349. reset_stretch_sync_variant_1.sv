//SystemVerilog
// Top-level module: Reset Stretch and Synchronization
module reset_stretch_sync #(
    parameter STRETCH_COUNT = 4
)(
    input  wire clk,
    input  wire async_rst_n,
    output wire sync_rst_n
);

    // Internal signals
    wire meta_sync;
    wire [2:0] stretch_count_value;
    wire reset_active;
    wire reset_detected_nxt;
    wire stretch_counter_enable;
    wire stretch_counter_done;
    wire stretch_counter_clr;
    wire manchester_carry_en;
    wire [2:0] manchester_sum_out;
    wire stretch_rst_n;
    wire sync_rst_n_reg;

    // Synchronizer submodule: Synchronizes the async reset to clk domain
    reset_sync u_reset_sync (
        .clk        (clk),
        .async_rst_n(async_rst_n),
        .meta_sync  (meta_sync)
    );

    // Reset stretch controller: Generates and manages the stretch logic
    reset_stretch_ctrl #(
        .STRETCH_COUNT(STRETCH_COUNT)
    ) u_reset_stretch_ctrl (
        .clk                  (clk),
        .async_rst_n          (async_rst_n),
        .meta_sync            (meta_sync),
        .stretch_counter      (stretch_count_value),
        .stretch_counter_done (stretch_counter_done),
        .manchester_sum       (manchester_sum_out),
        .stretch_counter_clr  (stretch_counter_clr),
        .stretch_counter_en   (stretch_counter_enable),
        .reset_detected_nxt   (reset_detected_nxt),
        .reset_detected       (reset_active),
        .stretch_rst_n        (stretch_rst_n)
    );

    // 3-bit Manchester Carry Chain Adder submodule
    manchester_adder_3b u_manchester_adder_3b (
        .a      (stretch_count_value),
        .b      (3'b001),
        .cin    (1'b0),
        .sum    (manchester_sum_out)
    );

    // Stretch Counter: Holds the current stretch count
    stretch_counter_reg u_stretch_counter (
        .clk         (clk),
        .async_rst_n (async_rst_n),
        .clr         (stretch_counter_clr),
        .en          (stretch_counter_enable),
        .sum_in      (manchester_sum_out),
        .count_out   (stretch_count_value)
    );

    // Output register: Ensures glitch-free output
    sync_rst_output u_sync_rst_output (
        .clk         (clk),
        .async_rst_n (async_rst_n),
        .stretch_rst_n(stretch_rst_n),
        .meta_sync   (meta_sync),
        .reset_active(reset_active),
        .sync_rst_n  (sync_rst_n_reg)
    );

    assign sync_rst_n = sync_rst_n_reg;

endmodule

//------------------------------------------------------------------------------
// Submodule: reset_sync
// Function: Synchronizes async_rst_n to clk domain (single flop for meta-capture)
//------------------------------------------------------------------------------
module reset_sync (
    input  wire clk,
    input  wire async_rst_n,
    output reg  meta_sync
);
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            meta_sync <= 1'b0;
        else
            meta_sync <= 1'b1;
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: reset_stretch_ctrl
// Function: Controls reset stretching logic, manages stretching state
//------------------------------------------------------------------------------
module reset_stretch_ctrl #(
    parameter STRETCH_COUNT = 4
)(
    input  wire clk,
    input  wire async_rst_n,
    input  wire meta_sync,
    input  wire [2:0] stretch_counter,
    input  wire [2:0] manchester_sum,
    output reg  stretch_counter_clr,
    output reg  stretch_counter_en,
    output reg  reset_detected_nxt,
    output reg  reset_detected,
    output reg  stretch_rst_n,
    output wire stretch_counter_done
);
    assign stretch_counter_done = (stretch_counter >= (STRETCH_COUNT - 1));

    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            reset_detected      <= 1'b1;
            stretch_counter_clr <= 1'b1;
            stretch_counter_en  <= 1'b0;
            stretch_rst_n       <= 1'b0;
        end else begin
            stretch_counter_clr <= 1'b0;
            if (reset_detected) begin
                if (!stretch_counter_done) begin
                    stretch_counter_en  <= 1'b1;
                    stretch_rst_n       <= 1'b0;
                end else begin
                    stretch_counter_en  <= 1'b0;
                    reset_detected      <= 1'b0;
                    stretch_rst_n       <= 1'b1;
                end
            end else begin
                stretch_rst_n       <= meta_sync;
                stretch_counter_en  <= 1'b0;
            end
        end
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: manchester_adder_3b
// Function: 3-bit Manchester Carry Chain Adder
//------------------------------------------------------------------------------
module manchester_adder_3b (
    input  wire [2:0] a,
    input  wire [2:0] b,
    input  wire       cin,
    output wire [2:0] sum
);
    wire [2:0] p, g;
    wire [3:0] c;

    assign p = a ^ b;
    assign g = a & b;
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign sum = p ^ c[2:0];
endmodule

//------------------------------------------------------------------------------
// Submodule: stretch_counter_reg
// Function: Register for stretch counter, with synchronous clear and enable
//------------------------------------------------------------------------------
module stretch_counter_reg (
    input  wire       clk,
    input  wire       async_rst_n,
    input  wire       clr,
    input  wire       en,
    input  wire [2:0] sum_in,
    output reg  [2:0] count_out
);
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            count_out <= 3'b000;
        else if (clr)
            count_out <= 3'b000;
        else if (en)
            count_out <= sum_in;
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: sync_rst_output
// Function: Output register for sync_rst_n, ensures correct output sequencing
//------------------------------------------------------------------------------
module sync_rst_output (
    input  wire clk,
    input  wire async_rst_n,
    input  wire stretch_rst_n,
    input  wire meta_sync,
    input  wire reset_active,
    output reg  sync_rst_n
);
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            sync_rst_n <= 1'b0;
        else if (reset_active)
            sync_rst_n <= 1'b0;
        else
            sync_rst_n <= stretch_rst_n;
    end
endmodule