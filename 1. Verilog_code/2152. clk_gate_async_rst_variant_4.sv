//SystemVerilog
/* 
 * Clock gating module with asynchronous reset
 * IEEE 1364-2005 Verilog standard
 */
module clk_gate_async_rst #(parameter INIT=0) (
    input  logic clk,    // Clock input
    input  logic rst_n,  // Active-low asynchronous reset
    input  logic en,     // Enable signal
    output logic q       // Output
);
    // Registered enable signal 
    logic en_latch;
    
    // Use level-sensitive latch for glitch-free enable
    always_latch begin
        if (!clk)
            en_latch <= en;
    end
    
    // Main sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            q <= INIT;
        else if (en_latch)
            q <= ~q;
    end
endmodule