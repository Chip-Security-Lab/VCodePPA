module Div3(input clk, start, [15:0] num, den, output reg [15:0] q, done);
    reg [4:0] cnt;
    reg [31:0] acc;
    always @(posedge clk) begin
        if(start) begin
            acc <= {16'd0, num} << 16;
            cnt <= 31;
        end else if(cnt > 0) begin
            acc <= acc[30:0] << 1;
            if(acc[31:16] >= den) begin
                acc[31:16] <= acc[31:16] - den;
                q[cnt-16] <= 1'b1;
            end
            cnt <= cnt - 1;
        end
        done <= (cnt == 0);
    end
endmodule