module gray_clock_divider(
    input clock,
    input reset,
    output [3:0] gray_out
);
    reg [3:0] count;
    
    always @(posedge clock) begin
        if (reset)
            count <= 4'b0000;
        else
            count <= count + 1'b1;
    end
    
    assign gray_out = {count[3], count[3]^count[2], count[2]^count[1], count[1]^count[0]};
endmodule