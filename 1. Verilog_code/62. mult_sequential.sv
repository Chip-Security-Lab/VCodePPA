module mult_sequential (
    input clk, start,
    input [7:0] multiplicand, multiplier,
    output reg [15:0] product,
    output reg done
);
    reg [3:0] count;
    always @(posedge clk) begin
        if(start) begin
            product <= {8'b0, multiplier};
            count <= 4'd0;
            done <= 0;
        end else if(!done) begin
            if(product[0]) product[15:8] <= product[15:8] + multiplicand;
            product <= {1'b0, product[15:1]};
            count <= count + 1;
            done <= (count == 4'd7);
        end
    end
endmodule
