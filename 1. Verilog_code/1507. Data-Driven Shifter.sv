module data_driven_shifter #(parameter WIDTH = 8) (
    input wire clk, rst,
    input wire data_valid,
    input wire serial_in,
    output wire [WIDTH-1:0] parallel_out
);
    reg [WIDTH-1:0] shift_data;
    
    always @(posedge clk) begin
        if (rst)
            shift_data <= 0;
        else if (data_valid)
            shift_data <= {shift_data[WIDTH-2:0], serial_in};
    end
    
    assign parallel_out = shift_data;
endmodule
