module sipo_register #(parameter N = 16) (
    input wire clock, reset, enable, serial_in,
    output wire [N-1:0] parallel_out
);
    reg [N-1:0] data_reg;
    
    always @(posedge clock) begin
        if (reset)
            data_reg <= 0;
        else if (enable)
            data_reg <= {data_reg[N-2:0], serial_in};
    end
    
    assign parallel_out = data_reg;
endmodule