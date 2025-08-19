//SystemVerilog
module gated_clk_sleep(
    input  logic clk_src,
    input  logic sleep,
    input  logic enable,
    output logic gated_clk
);
    logic enable_latch;
    logic sleep_ff1, sleep_ff2;
    logic clk_en;
    
    // Enable latch with optimized structure
    always_latch begin
        if (!clk_src)
            enable_latch = enable & ~sleep;
    end
    
    // Optimize sleep signal synchronization with single always block
    always_ff @(posedge clk_src or posedge sleep) begin
        if (sleep) begin
            sleep_ff1 <= 1'b1;
            sleep_ff2 <= 1'b1;
        end else begin
            sleep_ff1 <= sleep;
            sleep_ff2 <= sleep_ff1;
        end
    end
    
    // Simplified and optimized clock gating logic
    assign clk_en = enable_latch & ~sleep_ff2;
    
    // Integrated clock gating cell (ICGC) style implementation
    // Direct implementation for improved timing and power characteristics
    assign gated_clk = clk_src & clk_en;
endmodule