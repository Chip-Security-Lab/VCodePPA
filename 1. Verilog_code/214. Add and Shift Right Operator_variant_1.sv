//SystemVerilog
module add_signed_divide (
    input wire clk,
    input wire rst_n,
    input wire req,
    input signed [7:0] a,
    input signed [7:0] b,
    input signed [7:0] c,
    output reg ack,
    output reg signed [15:0] sum,
    output reg signed [7:0] quotient
);

    reg req_d;
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            req_d <= 1'b0;
            ack <= 1'b0;
            sum <= 16'd0;
            quotient <= 8'd0;
        end else begin
            req_d <= req;
            case (state)
                IDLE: begin
                    if (req && !req_d) begin
                        state <= CALC;
                        ack <= 1'b0;
                    end
                end
                CALC: begin
                    sum <= a + c;
                    quotient <= a / b;
                    state <= DONE;
                end
                DONE: begin
                    ack <= 1'b1;
                    if (!req) begin
                        state <= IDLE;
                        ack <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule