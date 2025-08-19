//SystemVerilog
module exp_waveform(
    input clk,
    input rst,
    input enable,
    output reg [9:0] exp_out
);

    reg [3:0] count;
    wire [9:0] exp_values [0:15];
    
    // Pre-computed values using combinational logic
    assign exp_values[0] = 10'd1;
    assign exp_values[1] = 10'd2;
    assign exp_values[2] = 10'd4;
    assign exp_values[3] = 10'd8;
    assign exp_values[4] = 10'd16;
    assign exp_values[5] = 10'd32;
    assign exp_values[6] = 10'd64;
    assign exp_values[7] = 10'd128;
    assign exp_values[8] = 10'd256;
    assign exp_values[9] = 10'd512;
    assign exp_values[10] = 10'd1023;
    assign exp_values[11] = 10'd512;
    assign exp_values[12] = 10'd256;
    assign exp_values[13] = 10'd128;
    assign exp_values[14] = 10'd64;
    assign exp_values[15] = 10'd32;

    // Optimized counter and output logic
    always @(posedge clk) begin
        if (rst) begin
            count <= 4'd0;
            exp_out <= 10'd0;
        end else if (enable) begin
            count <= (count == 4'd15) ? 4'd0 : count + 4'd1;
            exp_out <= exp_values[count];
        end
    end

endmodule