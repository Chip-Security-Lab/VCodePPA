module modulo_counter #(parameter MOD_VALUE = 10, WIDTH = 4) (
    input wire clk, reset,
    output reg [WIDTH-1:0] count,
    output wire tc
);
    assign tc = (count == MOD_VALUE - 1);
    
    always @(posedge clk) begin
        if (reset)
            count <= 0;
        else
            count <= tc ? 0 : count + 1'b1;
    end
endmodule