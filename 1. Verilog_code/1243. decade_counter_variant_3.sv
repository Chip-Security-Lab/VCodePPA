//SystemVerilog
module decade_counter (
    input wire clk, reset,
    output reg [3:0] counter,
    output reg decade_pulse
);
    // 合并所有逻辑到单一always块
    always @(posedge clk) begin
        if (reset) begin
            counter <= 4'd0;
            decade_pulse <= 1'b0;
        end else begin
            if (counter == 4'd9) begin
                counter <= 4'd0;
                decade_pulse <= 1'b1;
            end else begin
                counter <= counter + 4'd1;
                decade_pulse <= 1'b0;
            end
        end
    end
endmodule