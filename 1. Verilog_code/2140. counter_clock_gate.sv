module counter_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire [3:0] div_ratio,
    output wire clk_out
);
    reg [3:0] cnt;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            cnt <= 4'b0;
        else
            cnt <= (cnt == div_ratio) ? 4'b0 : cnt + 1'b1;
    end
    
    assign clk_out = clk_in & (cnt == 4'b0);
endmodule