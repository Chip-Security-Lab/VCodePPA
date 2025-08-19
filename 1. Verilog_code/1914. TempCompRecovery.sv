module TempCompRecovery #(parameter WIDTH=12) (
    input clk,
    input [WIDTH-1:0] temp_sensor,
    input [WIDTH-1:0] raw_data,
    output reg [WIDTH-1:0] comp_data
);
    reg signed [WIDTH+2:0] offset;
    always @(posedge clk) begin
        offset <= (temp_sensor - 12'd2048) * 3; // 3ppm/℃
        comp_data <= raw_data + offset[WIDTH+2:3];
    end
endmodule
