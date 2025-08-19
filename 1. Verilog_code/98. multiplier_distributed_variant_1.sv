//SystemVerilog
module multiplier_distributed (
    input clk,
    input rst_n,
    input [3:0] a,
    input [3:0] b,
    input req,
    output reg ack,
    output reg [7:0] product
);

    reg [7:0] partial_product [3:0];
    reg [7:0] next_product;
    reg next_ack;
    reg [1:0] state;
    
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    // Combinational logic for partial products
    always @(*) begin
        case (a)
            4'b0000: begin
                partial_product[0] = 0;
                partial_product[1] = 0;
                partial_product[2] = 0;
                partial_product[3] = 0;
            end
            4'b0001: begin
                partial_product[0] = b;
                partial_product[1] = 0;
                partial_product[2] = 0;
                partial_product[3] = 0;
            end
            4'b0010: begin
                partial_product[0] = 0;
                partial_product[1] = b << 1;
                partial_product[2] = 0;
                partial_product[3] = 0;
            end
            4'b0100: begin
                partial_product[0] = 0;
                partial_product[1] = 0;
                partial_product[2] = b << 2;
                partial_product[3] = 0;
            end
            4'b1000: begin
                partial_product[0] = 0;
                partial_product[1] = 0;
                partial_product[2] = 0;
                partial_product[3] = b << 3;
            end
            default: begin
                partial_product[0] = a[0] ? b : 0;
                partial_product[1] = a[1] ? (b << 1) : 0;
                partial_product[2] = a[2] ? (b << 2) : 0;
                partial_product[3] = a[3] ? (b << 3) : 0;
            end
        endcase
        next_product = partial_product[0] + partial_product[1] + partial_product[2] + partial_product[3];
    end

    // Sequential logic for req-ack handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            product <= 8'b0;
            ack <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (req) begin
                        state <= CALC;
                        product <= next_product;
                        ack <= 1'b1;
                    end
                end
                CALC: begin
                    state <= DONE;
                end
                DONE: begin
                    if (!req) begin
                        state <= IDLE;
                        ack <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule