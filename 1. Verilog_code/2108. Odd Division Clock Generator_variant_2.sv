//SystemVerilog
module odd_div_clk_gen #(
    parameter DIV = 3 // Must be odd number
)(
    input clk_in,
    input rst,
    output reg clk_out
);
    localparam WIDTH = 8;
    localparam GOLD_SCH_ITER = 4;

    reg [$clog2(DIV)-1:0] count;
    reg clk_out_next;
    wire [WIDTH-1:0] div_result;
    wire div_done;
    reg div_start;
    reg div_start_d;

    // Divider Start Logic
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            div_start <= 1'b1;
            div_start_d <= 1'b0;
        end else begin
            if (div_done)
                div_start <= 1'b1;
            else if (div_start)
                div_start <= 1'b0;
            div_start_d <= div_start;
        end
    end

    goldschmidt_divider #(
        .WIDTH(WIDTH),
        .ITER(GOLD_SCH_ITER)
    ) u_goldschmidt_divider (
        .clk(clk_in),
        .rst(rst),
        .start(div_start),
        .numerator(8'd1),              // Numerator = 1 (for divider)
        .denominator(DIV[7:0]),        // Denominator = DIV
        .quotient(div_result),
        .done(div_done)
    );

    // Counter Using Goldschmidt Division Result
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            count <= 0;
            clk_out <= 0;
            clk_out_next <= 0;
        end else if (div_done) begin
            if (count == div_result-1) begin
                count <= 0;
                clk_out_next <= ~clk_out_next;
            end else begin
                count <= count + 1;
            end
            clk_out <= clk_out_next;
        end
    end

endmodule

// Parameterized Goldschmidt Divider Module
module goldschmidt_divider #(
    parameter WIDTH = 8,
    parameter ITER = 4
)(
    input clk,
    input rst,
    input start,
    input [WIDTH-1:0] numerator,
    input [WIDTH-1:0] denominator,
    output reg [WIDTH-1:0] quotient,
    output reg done
);
    localparam S_IDLE = 2'd0, S_RUN = 2'd1, S_DONE = 2'd2;
    reg [1:0] state, next_state;

    reg [WIDTH-1:0] reciprocal;
    reg [$clog2(ITER+1)-1:0] iter_cnt;
    reg [2*WIDTH-1:0] xn;
    reg [2*WIDTH-1:0] yn;
    reg [2*WIDTH-1:0] fn;

    wire [WIDTH-1:0] fixed_one = 8'b0111_1111; // 0.996 in Q1.7

    // FSM Next State Logic
    always @(*) begin
        case (state)
            S_IDLE: next_state = start ? S_RUN : S_IDLE;
            S_RUN: next_state = (iter_cnt == ITER) ? S_DONE : S_RUN;
            S_DONE: next_state = S_IDLE;
            default: next_state = S_IDLE;
        endcase
    end

    // FSM State Register
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // Goldschmidt Divider Data Path
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reciprocal <= 0;
            quotient <= 0;
            done <= 0;
            iter_cnt <= 0;
            xn <= 0;
            yn <= 0;
            fn <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    reciprocal <= fixed_one;               // Initial reciprocal estimate (Q1.7)
                    quotient <= 0;
                    done <= 0;
                    iter_cnt <= 0;
                    xn <= {numerator, {WIDTH{1'b0}}};     // xn = numerator in Q8.8
                    yn <= {denominator, {WIDTH{1'b0}}};   // yn = denominator in Q8.8
                    fn <= {fixed_one, {WIDTH{1'b0}}};     // fn = initial reciprocal
                end
                S_RUN: begin
                    xn <= (xn * fn) >> 7; // Q1.7 multiply, shift back to Q8.8
                    yn <= (yn * fn) >> 7;
                    fn <= ({1'b1, {(2*WIDTH-1){1'b0}}} - yn) >> 7; // 2.0 in Q8.8 is 16'h0200
                    iter_cnt <= iter_cnt + 1;
                end
                S_DONE: begin
                    quotient <= xn[2*WIDTH-1:WIDTH]; // Take integer part of result
                    done <= 1'b1;
                end
            endcase
        end
    end

endmodule