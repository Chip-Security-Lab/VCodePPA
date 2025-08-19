//SystemVerilog
module multiplier_8bit (
    input clk,
    input rst_n,
    input req,
    output reg ack,
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product,
    output reg product_ack
);

    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    reg [7:0] a_reg;
    reg [7:0] b_reg;
    reg [15:0] partial_product;
    reg [3:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ack <= 1'b0;
            product_ack <= 1'b0;
            product <= 16'b0;
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            partial_product <= 16'b0;
            counter <= 4'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (req && !ack) begin
                        state <= CALC;
                        ack <= 1'b1;
                        a_reg <= a;
                        b_reg <= b;
                        partial_product <= 16'b0;
                        counter <= 4'b0;
                    end
                end
                CALC: begin
                    if (counter < 8) begin
                        if (b_reg[0]) begin
                            partial_product <= partial_product + (a_reg << counter);
                        end
                        b_reg <= b_reg >> 1;
                        counter <= counter + 1;
                    end else begin
                        product <= partial_product;
                        state <= DONE;
                    end
                end
                DONE: begin
                    product_ack <= 1'b1;
                    state <= IDLE;
                    ack <= 1'b0;
                end
            endcase
        end
    end

endmodule