module ring_divider (
    input clk_in, rst_n,
    output clk_out
);
    reg [4:0] ring;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            ring <= 5'b00001;
        else
            ring <= {ring[0], ring[4:1]};
    end
    
    assign clk_out = ring[0];
endmodule