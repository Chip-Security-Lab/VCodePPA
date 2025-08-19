//SystemVerilog
module multiplier_pipeline (
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    input req,
    output reg ack,
    output reg [15:0] product
);

    reg [15:0] p1, p2, p3;
    reg [1:0] state;
    reg [1:0] next_state;
    
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;

    // Carry-skip adder implementation
    wire [15:0] sum_p2;
    wire [15:0] sum_p3;
    wire [16:0] carry_p2;
    wire [16:0] carry_p3;
    
    // Carry-skip adder for p2 = p1 + 1
    assign carry_p2[0] = 1'b1; // Adding 1
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_carry_skip_p2
            assign sum_p2[i] = p1[i] ^ carry_p2[i];
            assign carry_p2[i+1] = (p1[i] & carry_p2[i]) | (p1[i] & 1'b0) | (carry_p2[i] & 1'b0);
        end
    endgenerate
    
    // Carry-skip adder for p3 = p2 + 1
    assign carry_p3[0] = 1'b1; // Adding 1
    genvar j;
    generate
        for (j = 0; j < 16; j = j + 1) begin : gen_carry_skip_p3
            assign sum_p3[j] = p2[j] ^ carry_p3[j];
            assign carry_p3[j+1] = (p2[j] & carry_p3[j]) | (p2[j] & 1'b0) | (carry_p3[j] & 1'b0);
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ack <= 1'b0;
            product <= 16'b0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    if (req) begin
                        ack <= 1'b1;
                        p1 <= a * b;
                        next_state <= CALC;
                    end else begin
                        ack <= 1'b0;
                        next_state <= IDLE;
                    end
                end
                CALC: begin
                    p2 <= sum_p2;
                    p3 <= sum_p3;
                    next_state <= DONE;
                end
                DONE: begin
                    product <= p3;
                    ack <= 1'b0;
                    next_state <= IDLE;
                end
            endcase
        end
    end

endmodule