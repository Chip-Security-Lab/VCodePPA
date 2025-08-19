module glitch_filter_rst_sync (
    input  wire clk,
    input  wire async_rst_n,
    output wire filtered_rst_n
);
    reg [3:0] shift_reg;
    reg       filtered;
    
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n)
            shift_reg <= 4'b0000;
        else
            shift_reg <= {shift_reg[2:0], 1'b1};
    end
    
    always @(posedge clk) begin
        if (shift_reg == 4'b1111)
            filtered <= 1'b1;
        else if (shift_reg == 4'b0000)
            filtered <= 1'b0;
    end
    
    assign filtered_rst_n = filtered;
endmodule