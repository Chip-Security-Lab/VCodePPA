module async_square_wave #(
    parameter CNT_WIDTH = 10
)(
    input wire clock,
    input wire reset,
    input wire [CNT_WIDTH-1:0] max_count,
    input wire [CNT_WIDTH-1:0] duty_cycle,
    output wire wave_out
);
    reg [CNT_WIDTH-1:0] counter_q;
    
    always @(posedge clock or posedge reset) begin
        if (reset)
            counter_q <= {CNT_WIDTH{1'b0}};
        else if (counter_q >= max_count)
            counter_q <= {CNT_WIDTH{1'b0}};
        else
            counter_q <= counter_q + 1'b1;
    end
    
    assign wave_out = (counter_q < duty_cycle) ? 1'b1 : 1'b0;
endmodule