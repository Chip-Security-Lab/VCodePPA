module glitch_free_clock_gate (
    input  wire clk_in,
    input  wire enable,
    input  wire rst_n,
    output wire clk_out
);
    reg enable_ff1, enable_ff2;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_ff1 <= 1'b0;
            enable_ff2 <= 1'b0;
        end else begin
            enable_ff1 <= enable;
            enable_ff2 <= enable_ff1;
        end
    end
    
    assign clk_out = clk_in & enable_ff2;
endmodule