module lin_codec (
    input clk, break_detect,
    input [7:0] pid,
    output reg tx
);
    reg [13:0] shift_reg;
    always @(posedge clk) begin
        if(break_detect) begin
            shift_reg <= {2'b00, pid, 4'h0};
            tx <= 0; // Send break
        end
        else begin
            tx <= shift_reg[13];
            shift_reg <= {shift_reg[12:0], 1'b1};
        end
    end
endmodule