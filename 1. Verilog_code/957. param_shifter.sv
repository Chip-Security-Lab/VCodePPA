module param_shifter #(
    parameter WIDTH = 12,
    parameter RESET_VALUE = 0
)(
    input wire i_Clk,
    input wire i_Rst,
    input wire i_DataIn,
    output wire [WIDTH-1:0] o_DataOut
);
    reg [WIDTH-1:0] r_Shift;
    
    always @(posedge i_Clk) begin
        if (i_Rst)
            r_Shift <= RESET_VALUE;
        else
            r_Shift <= {r_Shift[WIDTH-2:0], i_DataIn};
    end
    
    assign o_DataOut = r_Shift;
endmodule