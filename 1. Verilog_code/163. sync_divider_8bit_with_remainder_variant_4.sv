//SystemVerilog
module sync_divider_8bit_with_remainder (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    reg [7:0] x, y;
    reg [7:0] x_next, y_next;
    reg [7:0] q_next;
    reg [7:0] r_next;
    reg [2:0] iter_count;
    reg [2:0] iter_count_next;
    reg div_start;
    reg div_done;

    reg [7:0] approx_table [0:255];
    initial begin
        for (integer i = 0; i < 256; i = i + 1) begin
            approx_table[i] = 8'hFF / (i + 1);
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x <= 0;
            y <= 0;
            quotient <= 0;
            remainder <= 0;
            iter_count <= 0;
            div_start <= 0;
            div_done <= 0;
        end else begin
            case ({div_start, div_done})
                2'b00: begin
                    x <= a;
                    y <= b;
                    iter_count <= 0;
                    div_start <= 1;
                    div_done <= 0;
                end
                2'b10: begin
                    x <= x_next;
                    y <= y_next;
                    iter_count <= iter_count_next;
                    if (iter_count == 3'd3) begin
                        div_done <= 1;
                        quotient <= q_next;
                        remainder <= r_next;
                    end
                end
                2'b11: begin
                    div_start <= 0;
                end
                default: begin
                    x <= x;
                    y <= y;
                    quotient <= quotient;
                    remainder <= remainder;
                    iter_count <= iter_count;
                    div_start <= div_start;
                    div_done <= div_done;
                end
            endcase
        end
    end

    always @(*) begin
        case ({div_start, div_done})
            2'b00: begin
                x_next = x;
                y_next = y;
                q_next = 0;
                r_next = 0;
                iter_count_next = 0;
            end
            2'b10: begin
                if (iter_count == 0) begin
                    y_next = approx_table[y-1];
                    x_next = x;
                end else begin
                    y_next = y * (2 - y * b);
                    x_next = x * (2 - y * b);
                end
                q_next = x_next;
                r_next = a - (q_next * b);
                iter_count_next = iter_count + 1;
            end
            2'b11: begin
                x_next = x;
                y_next = y;
                q_next = quotient;
                r_next = remainder;
                iter_count_next = iter_count;
            end
            default: begin
                x_next = x;
                y_next = y;
                q_next = q_next;
                r_next = r_next;
                iter_count_next = iter_count;
            end
        endcase
    end

endmodule