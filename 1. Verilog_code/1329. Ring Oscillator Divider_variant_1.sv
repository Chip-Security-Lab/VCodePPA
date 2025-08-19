//SystemVerilog
module ring_divider (
    input clk_in, rst_n,
    output reg clk_out
);
    reg [3:0] ring;
    
    always @(posedge clk_in or negedge rst_n) begin
        ring <= !rst_n ? 4'b0001 : {ring[0], ring[3:1]};
        clk_out <= !rst_n ? 1'b0 : ring[0];
    end
endmodule