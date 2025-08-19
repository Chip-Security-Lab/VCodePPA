module piso_reg (
    input clk, clear_b, load,
    input [7:0] parallel_in,
    output serial_out
);
    reg [7:0] data = 8'h00;
    
    always @(posedge clk or negedge clear_b) begin
        if (!clear_b) 
            data <= 8'h00;
        else if (load)
            data <= parallel_in;
        else
            data <= {data[6:0], 1'b0};  // Shift left
    end
    
    assign serial_out = data[7];
endmodule