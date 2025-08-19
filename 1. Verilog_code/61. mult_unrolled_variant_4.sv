//SystemVerilog
module mult_unrolled (
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [3:0] x,
    input [3:0] y,
    output reg [7:0] result,
    output reg result_valid
);

    reg [7:0] p0, p1, p2, p3;
    reg [7:0] sum;
    reg state;
    localparam IDLE = 1'b0;
    localparam CALC = 1'b1;

    // Pre-compute shifted versions of x
    wire [7:0] x_shift0 = {4'b0, x};
    wire [7:0] x_shift1 = {3'b0, x, 1'b0};
    wire [7:0] x_shift2 = {2'b0, x, 2'b0};
    wire [7:0] x_shift3 = {1'b0, x, 3'b0};

    // Optimize partial product generation
    wire [7:0] p0_next = y[0] ? x_shift0 : 8'b0;
    wire [7:0] p1_next = y[1] ? x_shift1 : 8'b0;
    wire [7:0] p2_next = y[2] ? x_shift2 : 8'b0;
    wire [7:0] p3_next = y[3] ? x_shift3 : 8'b0;

    // Optimize sum calculation using carry-save adder structure
    wire [7:0] sum01 = p0 + p1;
    wire [7:0] sum23 = p2 + p3;
    wire [7:0] sum_next = sum01 + sum23;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ready <= 1'b1;
            result_valid <= 1'b0;
            result <= 8'b0;
            p0 <= 8'b0;
            p1 <= 8'b0;
            p2 <= 8'b0;
            p3 <= 8'b0;
            sum <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid && ready) begin
                        p0 <= p0_next;
                        p1 <= p1_next;
                        p2 <= p2_next;
                        p3 <= p3_next;
                        ready <= 1'b0;
                        state <= CALC;
                    end
                end
                CALC: begin
                    sum <= sum_next;
                    result <= sum_next;
                    result_valid <= 1'b1;
                    ready <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule