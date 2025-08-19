module binary_freq_div #(parameter WIDTH = 4) (
    input wire clk_in,
    input wire rst_n,
    output wire clk_out
);
    reg [WIDTH-1:0] count;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            count <= {WIDTH{1'b0}};
        else
            count <= count + 1'b1;
    end
    
    assign clk_out = count[WIDTH-1];
endmodule