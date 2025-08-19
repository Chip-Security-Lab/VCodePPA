module thermometer_to_binary #(parameter THERMO_WIDTH=7)(
    input wire [THERMO_WIDTH-1:0] thermo_in,
    output reg [$clog2(THERMO_WIDTH+1)-1:0] binary_out
);
    integer i;
    reg [THERMO_WIDTH-1:0] count;
    
    always @* begin
        count = 0;
        for (i = 0; i < THERMO_WIDTH; i = i + 1) begin
            count = count + thermo_in[i];
        end
        binary_out = count[$clog2(THERMO_WIDTH+1)-1:0];
    end
endmodule