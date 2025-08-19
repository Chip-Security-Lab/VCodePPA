module pulse_width_measure #(
    parameter COUNTER_WIDTH = 32
)(
    input clk,
    input pulse_in,
    output reg [COUNTER_WIDTH-1:0] width_count
);
reg last_state;
reg measuring;

always @(posedge clk) begin
    last_state <= pulse_in;
    
    if (pulse_in && !last_state) begin // 上升沿
        measuring <= 1;
        width_count <= 0;
    end else if (!pulse_in && last_state) begin // 下降沿
        measuring <= 0;
    end else if (measuring) begin
        width_count <= width_count + 1;
    end
end
endmodule
