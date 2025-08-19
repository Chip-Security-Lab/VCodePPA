module therm2priority_encoder #(parameter WIDTH = 8) (
    input  wire [WIDTH-1:0] thermometer_in,
    output reg  [$clog2(WIDTH)-1:0] priority_out,
    output wire valid_out
);
    integer i;
    reg found;
    
    // Check if input has any active bits
    assign valid_out = |thermometer_in;
    
    // Priority encoder logic - find first '1'
    always @(*) begin
        priority_out = {$clog2(WIDTH){1'b0}};
        found = 1'b0;
        
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (thermometer_in[i] && !found) begin
                priority_out = i[$clog2(WIDTH)-1:0];
                found = 1'b1;
            end
        end
    end
endmodule