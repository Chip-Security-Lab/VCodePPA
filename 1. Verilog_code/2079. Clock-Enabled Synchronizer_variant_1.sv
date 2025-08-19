//SystemVerilog
module clock_enable_sync (
    input wire fast_clk,
    input wire slow_clk,
    input wire rst_n,
    input wire enable_src,
    output reg enable_dst
);
    reg [1:0] enable_sync_chain;

    wire enable_src_slow2fast;

    // Move register after combination logic (forward retiming)
    assign enable_src_slow2fast = enable_src;

    // Synchronize to destination domain (optimized comparison chain using shift register)
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_sync_chain <= 2'b00;
            enable_dst <= 1'b0;
        end else begin
            enable_sync_chain <= {enable_sync_chain[0], enable_src_slow2fast};
            enable_dst <= enable_sync_chain[1];
        end
    end
endmodule