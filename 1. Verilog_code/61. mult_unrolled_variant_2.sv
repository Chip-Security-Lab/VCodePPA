//SystemVerilog
module mult_unrolled (
    input clk,
    input rst_n,
    input req,
    output reg ack,
    input [3:0] x,
    input [3:0] y,
    output reg [7:0] result,
    output reg result_valid
);

    reg [7:0] p0, p1, p2, p3;
    reg [7:0] sum_stage1, sum_stage2;
    reg [2:0] state;
    localparam IDLE = 3'b000;
    localparam CALC1 = 3'b001;
    localparam CALC2 = 3'b010;
    localparam CALC3 = 3'b011;
    localparam DONE = 3'b100;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ack <= 1'b0;
            result_valid <= 1'b0;
            result <= 8'b0;
            sum_stage1 <= 8'b0;
            sum_stage2 <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (req && !ack) begin
                        p0 <= y[0] ? {4'b0, x} : 8'b0;
                        p1 <= y[1] ? {3'b0, x, 1'b0} : 8'b0;
                        p2 <= y[2] ? {2'b0, x, 2'b0} : 8'b0;
                        p3 <= y[3] ? {1'b0, x, 3'b0} : 8'b0;
                        ack <= 1'b1;
                        state <= CALC1;
                    end else if (!req && ack) begin
                        ack <= 1'b0;
                    end
                end
                CALC1: begin
                    sum_stage1 <= p0 + p1;
                    state <= CALC2;
                end
                CALC2: begin
                    sum_stage2 <= sum_stage1 + p2;
                    state <= CALC3;
                end
                CALC3: begin
                    sum_stage1 <= sum_stage2 + p3;
                    state <= DONE;
                end
                DONE: begin
                    result <= sum_stage1;
                    result_valid <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule