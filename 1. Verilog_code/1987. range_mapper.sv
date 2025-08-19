module range_mapper #(parameter IN_MIN=0, IN_MAX=1023, OUT_MIN=0, OUT_MAX=255)(
    input wire [$clog2(IN_MAX-IN_MIN+1)-1:0] in_val,
    output reg [$clog2(OUT_MAX-OUT_MIN+1)-1:0] out_val
);
    localparam IN_RANGE = IN_MAX - IN_MIN;
    localparam OUT_RANGE = OUT_MAX - OUT_MIN;
    
    always @* begin
        out_val = ((in_val - IN_MIN) * OUT_RANGE) / IN_RANGE + OUT_MIN;
    end
endmodule