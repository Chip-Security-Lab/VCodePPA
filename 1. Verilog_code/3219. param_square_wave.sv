module param_square_wave #(
    parameter WIDTH = 16
)(
    input clock_i,
    input reset_i,
    input [WIDTH-1:0] period_i,
    input [WIDTH-1:0] duty_i,
    output wave_o
);
    reg [WIDTH-1:0] counter_r;
    
    always @(posedge clock_i) begin
        if (reset_i)
            counter_r <= {WIDTH{1'b0}};
        else if (counter_r >= period_i - 1'b1)
            counter_r <= {WIDTH{1'b0}};
        else
            counter_r <= counter_r + 1'b1;
    end
    
    assign wave_o = (counter_r < duty_i) ? 1'b1 : 1'b0;
endmodule