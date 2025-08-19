//SystemVerilog
module wave16_dual_slope #(
    parameter WIDTH = 8,
    parameter UP_MAX = 200,
    parameter DOWN_MAX = 100
)(
    input  wire clk,
    input  wire rst,
    output reg [WIDTH-1:0] wave_out
);
    reg [1:0] phase; // 0: up, 1: down

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            wave_out <= 0;
            phase    <= 0;
        end else if(phase == 0 && wave_out == UP_MAX) begin
            wave_out <= wave_out + 1;
            phase <= 1;
        end else if(phase == 0) begin
            wave_out <= wave_out + 1;
        end else if(phase == 1 && wave_out == DOWN_MAX) begin
            wave_out <= wave_out - 1;
            phase <= 0;
        end else if(phase == 1) begin
            wave_out <= wave_out - 1;
        end
    end
endmodule