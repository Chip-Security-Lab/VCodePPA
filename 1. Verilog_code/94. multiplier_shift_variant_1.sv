//SystemVerilog
module multiplier_shift (
    input clk,
    input rst_n,
    input req,
    output reg ack,
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product
);

    reg [15:0] product_reg;
    reg req_prev;
    reg [7:0] b_reg;
    reg [7:0] a_reg;
    reg [2:0] count;
    reg calc_done;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product_reg <= 16'd0;
            ack <= 1'b0;
            req_prev <= 1'b0;
            b_reg <= 8'd0;
            a_reg <= 8'd0;
            count <= 3'd0;
            calc_done <= 1'b0;
        end else begin
            req_prev <= req;
            
            if (req && !req_prev) begin
                product_reg <= 16'd0;
                b_reg <= b;
                a_reg <= a;
                count <= 3'd0;
                calc_done <= 1'b0;
                ack <= 1'b0;
            end else if (!calc_done) begin
                if (count < 3'd7) begin
                    if (b_reg[count]) begin
                        product_reg <= product_reg + (a_reg << count);
                    end
                    count <= count + 1'b1;
                end else begin
                    if (b_reg[count]) begin
                        product_reg <= product_reg + (a_reg << count);
                    end
                    calc_done <= 1'b1;
                    ack <= 1'b1;
                end
            end else if (!req && req_prev) begin
                ack <= 1'b0;
                calc_done <= 1'b0;
            end
        end
    end
    
    assign product = product_reg;
endmodule