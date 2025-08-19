//SystemVerilog
module gray_clock_divider(
    input clock,
    input reset,
    output [3:0] gray_out
);
    reg [3:0] count;
    reg [3:0] gray_reg;
    
    // Binary counter logic
    always @(posedge clock) begin
        if (reset)
            count <= 4'b0000;
        else
            count <= count + 1'b1;
    end
    
    // Pipeline register for gray code conversion
    // Cuts the critical path by separating the computation from the counter
    always @(posedge clock) begin
        if (reset)
            gray_reg <= 4'b0000;
        else
            gray_reg <= {count[3], count[3]^count[2], count[2]^count[1], count[1]^count[0]};
    end
    
    // Output assignment
    assign gray_out = gray_reg;
endmodule