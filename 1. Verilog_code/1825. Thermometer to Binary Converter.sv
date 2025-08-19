module therm2bin_converter #(parameter THERM_WIDTH = 7) (
    input  wire [THERM_WIDTH-1:0] therm_code,
    output wire [$clog2(THERM_WIDTH+1)-1:0] bin_code
);
    // Converts thermometer code to binary by counting 1's
    reg [$clog2(THERM_WIDTH+1)-1:0] ones_count;
    integer i;
    
    always @(*) begin
        ones_count = 0;
        for (i = 0; i < THERM_WIDTH; i = i + 1)
            if (therm_code[i]) ones_count = ones_count + 1'b1;
    end
    
    assign bin_code = ones_count;
endmodule