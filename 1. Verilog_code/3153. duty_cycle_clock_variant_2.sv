//SystemVerilog
module duty_cycle_clock #(
    parameter WIDTH = 8
)(
    input wire clkin,
    input wire reset,
    input wire [WIDTH-1:0] high_time,
    input wire [WIDTH-1:0] low_time,
    output reg clkout
);
    reg [WIDTH-1:0] counter = 0;
    
    always @(posedge clkin or posedge reset) begin
        if (reset) begin
            counter <= 0;
            clkout <= 0;
        end else begin
            case ({clkout, counter >= (clkout ? high_time : low_time)})
                2'b01: begin // 低电平且计数达到低电平时间
                    counter <= 0;
                    clkout <= 1;
                end
                2'b11: begin // 高电平且计数达到高电平时间
                    counter <= 0;
                    clkout <= 0;
                end
                default: begin // 计数未达到目标值
                    counter <= counter + 1;
                end
            endcase
        end
    end
endmodule