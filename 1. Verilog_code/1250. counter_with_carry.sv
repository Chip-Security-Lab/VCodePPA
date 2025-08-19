module counter_with_carry (
    input wire clk, rst_n,
    output reg [3:0] count,
    output wire cout
);
    assign cout = (count == 4'b1111);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 4'b0000;
        else
            count <= count + 1'b1;
    end
endmodule