//SystemVerilog
module mult_sequential (
    input clk,
    input req,
    output reg ack,
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output reg [15:0] product,
    output reg done
);
    reg [3:0] count;
    reg [15:0] product_buf;
    reg [7:0] multiplicand_buf;
    reg [7:0] multiplier_buf;
    reg [7:0] partial_sum;
    reg req_latched;
    
    always @(posedge clk) begin
        if(req && !req_latched) begin
            multiplicand_buf <= multiplicand;
            multiplier_buf <= multiplier;
            product_buf <= {8'b0, multiplier};
            count <= 4'd0;
            done <= 0;
            req_latched <= 1;
            ack <= 1;
        end else if(!done) begin
            partial_sum <= product_buf[0] ? product_buf[15:8] + multiplicand_buf : product_buf[15:8];
            product_buf <= {1'b0, partial_sum, product_buf[7:1]};
            count <= count + 1;
            done <= (count == 4'd7);
            if(done) begin
                req_latched <= 0;
                ack <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        product <= product_buf;
    end
endmodule