module FSMDiv(
    input clk, start,
    input [15:0] dividend, divisor,
    output reg [15:0] quotient,
    output done
);
    reg [1:0] state;
    reg [15:0] rem;
    reg [4:0] cnt;
    always @(posedge clk) begin
        case(state)
            0: if(start) begin
                rem <= dividend;
                cnt <= 15;
                state <= 1;
            end
            1: begin
                rem = rem << 1;
                if(rem >= divisor) begin
                    rem <= rem - divisor;
                    quotient[cnt] <= 1'b1;
                end
                cnt <= cnt - 1;
                if(cnt == 0) state <= 2;
            end
            2: state <= 0;
        endcase
    end
    assign done = (state == 2);
endmodule