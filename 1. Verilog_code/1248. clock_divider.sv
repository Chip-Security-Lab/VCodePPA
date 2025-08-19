module clock_divider #(parameter DIVIDE_BY = 2) (
    input wire clk_in, reset,
    output reg clk_out
);
    reg [$clog2(DIVIDE_BY)-1:0] count;
    
    always @(posedge clk_in) begin
        if (reset) begin
            count <= 0;
            clk_out <= 0;
        end else begin
            if (count == (DIVIDE_BY/2 - 1)) begin
                clk_out <= ~clk_out;
                count <= 0;
            end else
                count <= count + 1'b1;
        end
    end
endmodule