module adaptive_clock_gate (
    input  wire clk_in,
    input  wire [7:0] activity_level,
    input  wire rst_n,
    output wire clk_out
);
    reg gate_enable;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            gate_enable <= 1'b0;
        else
            gate_enable <= (activity_level > 8'd10);
    end
    
    assign clk_out = clk_in & gate_enable;
endmodule