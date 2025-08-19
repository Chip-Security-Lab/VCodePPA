module AsyncIVMU (
    input [7:0] int_lines,
    input [7:0] int_mask,
    output [31:0] vector_out,
    output int_active
);
    reg [31:0] vector_map [0:7];
    wire [7:0] masked_ints;
    reg [2:0] active_int;
    integer i;
    
    initial for (i = 0; i < 8; i = i + 1)
        vector_map[i] = 32'h2000_0000 + (i * 4);
    
    assign masked_ints = int_lines & ~int_mask;
    assign int_active = |masked_ints;
    
    always @(*) begin
        active_int = 0;
        for (i = 7; i >= 0; i = i - 1)
            if (masked_ints[i]) active_int = i[2:0];
    end
    
    assign vector_out = vector_map[active_int];
endmodule