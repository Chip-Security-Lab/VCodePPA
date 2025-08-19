module cascade_timer (
    input wire clk, reset, enable, cascade_in,
    output wire cascade_out,
    output wire [15:0] count_val
);
    reg [15:0] counter;
    reg cascade_in_d;
    wire tick;
    always @(posedge clk) cascade_in_d <= cascade_in;
    assign tick = cascade_in & ~cascade_in_d;
    always @(posedge clk) begin
        if (reset) counter <= 16'h0000;
        else if (enable && tick) counter <= counter + 16'h0001;
    end
    assign cascade_out = (counter == 16'hFFFF) && tick;
    assign count_val = counter;
endmodule