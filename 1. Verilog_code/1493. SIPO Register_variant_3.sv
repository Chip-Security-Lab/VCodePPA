//SystemVerilog
module sipo_register #(parameter N = 16) (
    input wire clock, reset, enable, serial_in,
    output wire [N-1:0] parallel_out
);
    // This is an optimized implementation that maintains the same functionality
    // Forward register retiming has been applied to improve timing characteristics
    
    reg serial_reg;
    reg [N-2:0] data_reg;
    
    // Register the input first to reduce input-to-register delay
    always @(posedge clock) begin
        if (reset)
            serial_reg <= 1'b0;
        else if (enable)
            serial_reg <= serial_in;
    end
    
    // Then shift the registered input into the main shift register
    always @(posedge clock) begin
        if (reset)
            data_reg <= {(N-1){1'b0}};
        else if (enable)
            data_reg <= {data_reg[N-3:0], serial_reg};
    end
    
    // Combine registered input and shift register for output
    assign parallel_out = {data_reg, serial_reg};
    
endmodule