module piso_shifter (
    input wire clk, clear, load,
    input wire [7:0] parallel_data,
    output wire serial_out
);
    reg [7:0] shift_data;
    
    always @(posedge clk) begin
        if (clear)
            shift_data <= 8'h00;
        else if (load)
            shift_data <= parallel_data;
        else
            shift_data <= {shift_data[6:0], 1'b0};
    end
    
    assign serial_out = shift_data[7];
endmodule