//SystemVerilog
module ring_divider (
    input clk_in, rst_n,
    output reg clk_out
);
    reg [3:0] ring;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            ring <= 4'b0001;
            clk_out <= 1'b0;
        end
        else begin
            ring <= {ring[0], ring[3:1]};
            clk_out <= ring[0];
        end
    end
endmodule