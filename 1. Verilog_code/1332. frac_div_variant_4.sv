//SystemVerilog
module frac_div #(parameter M=3, N=7) (
    input clk, rst,
    output reg out
);
    reg [7:0] acc;
    reg [7:0] next_acc;
    
    // Pre-compute the next accumulator value using if-else instead of conditional operator
    always @(*) begin
        if (acc >= N-M) begin
            next_acc = acc + M - N;
        end else begin
            next_acc = acc + M;
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            acc <= 8'b0;
            out <= 1'b0;
        end else begin
            acc <= next_acc;
            // Replaced conditional operator with if-else structure in a separate always block
            if (next_acc >= N) begin
                out <= 1'b1;
            end else begin
                out <= 1'b0;
            end
        end
    end
endmodule