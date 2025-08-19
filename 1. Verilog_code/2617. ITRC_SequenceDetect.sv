module ITRC_SequenceDetect #(
    parameter SEQ_PATTERN = 3'b101
)(
    input clk,
    input rst_n,
    input int_in,
    output reg seq_detected
);
    reg [2:0] shift_reg;
    
    always @(posedge clk) begin
        if (!rst_n) shift_reg <= 0;
        else shift_reg <= {shift_reg[1:0], int_in};
    end
    
    always @* begin
        seq_detected = (shift_reg == SEQ_PATTERN);
    end
endmodule