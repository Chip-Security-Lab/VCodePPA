module square_wave_gen #(
    parameter COUNTER_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [COUNTER_WIDTH-1:0] period,
    output reg out
);
    reg [COUNTER_WIDTH-1:0] counter;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
            out <= 0;
        end else begin
            if (counter >= period - 1) begin
                counter <= 0;
                out <= ~out;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule