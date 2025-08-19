//SystemVerilog
module therm2priority_encoder #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] thermometer_in,
    output reg  [$clog2(WIDTH)-1:0] priority_out,
    output wire valid_out
);
    // Valid output is simply the OR of all input bits
    assign valid_out = |thermometer_in;
    
    // Optimized priority encoder using case statement
    // This approach reduces logic depth and improves timing
    always @(*) begin
        priority_out = {$clog2(WIDTH){1'b0}};
        
        case (1'b1)
            thermometer_in[0]: priority_out = 0;
            thermometer_in[1]: priority_out = 1;
            thermometer_in[2]: priority_out = 2;
            thermometer_in[3]: priority_out = 3;
            thermometer_in[4]: priority_out = 4;
            thermometer_in[5]: priority_out = 5;
            thermometer_in[6]: priority_out = 6;
            thermometer_in[7]: priority_out = 7;
            default: priority_out = {$clog2(WIDTH){1'b0}};
        endcase
    end
endmodule