//SystemVerilog
// Top-level module: SyncNor
module SyncNor(
    input  wire clk,         // Clock signal
    input  wire rst,         // Synchronous reset
    input  wire a,           // Input a
    input  wire b,           // Input b
    output reg  y            // Output y
);
    wire nor_result;

    // Combinational NOR logic submodule
    NorLogic u_nor_logic (
        .a        (a),
        .b        (b),
        .nor_out  (nor_result)
    );

    // Synchronous register submodule
    SyncRegister u_sync_register (
        .clk      (clk),
        .rst      (rst),
        .d        (nor_result),
        .q        (y)
    );
endmodule

// Submodule: NorLogic
// Description: Performs 2-input NOR operation (optimized).
module NorLogic(
    input  wire a,           // Input a
    input  wire b,           // Input b
    output wire nor_out      // NOR output
);
    // Simplified using DeMorgan's Law: ~(a | b) = ~a & ~b
    assign nor_out = (~a) & (~b);
endmodule

// Submodule: SyncRegister
// Description: Synchronous register with synchronous reset.
module SyncRegister(
    input  wire clk,         // Clock signal
    input  wire rst,         // Synchronous reset
    input  wire d,           // Data input
    output reg  q            // Registered output
);
    always @(posedge clk) begin
        if (rst)
            q <= 1'b0;
        else
            q <= d;
    end
endmodule