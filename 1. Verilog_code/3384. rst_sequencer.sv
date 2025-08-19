module rst_sequencer(
    input wire clk,
    input wire rst_trigger,
    output reg [3:0] rst_stages
);
    reg [2:0] counter;
    always @(posedge clk) begin
        if (rst_trigger) begin
            counter <= 3'b0;
            rst_stages <= 4'b1111;
        end else if (counter < 3'b111) begin
            counter <= counter + 1'b1;
            rst_stages <= rst_stages >> 1;  // Release reset one stage at a time
        end
    end
endmodule