//SystemVerilog
module exp_waveform(
    input clk,
    input rst,
    input enable,
    output reg [9:0] exp_out
);
    // Pipeline registers for count
    reg [3:0] count;
    reg [3:0] count_stage1;
    reg [3:0] count_stage2;
    
    // Pipeline enable signals
    reg enable_stage1;
    reg enable_stage2;
    
    // Pipeline registers for output data
    reg [9:0] exp_data_stage1;
    reg [9:0] exp_data_stage2;
    
    // ROM for exponential values
    reg [9:0] exp_values [0:15];
    
    initial begin
        exp_values[0] = 10'd1;    exp_values[1] = 10'd2;    exp_values[2] = 10'd4;    exp_values[3] = 10'd8;
        exp_values[4] = 10'd16;   exp_values[5] = 10'd32;   exp_values[6] = 10'd64;   exp_values[7] = 10'd128;
        exp_values[8] = 10'd256;  exp_values[9] = 10'd512;  exp_values[10] = 10'd1023;
        exp_values[11] = 10'd512; exp_values[12] = 10'd256; exp_values[13] = 10'd128;
        exp_values[14] = 10'd64;  exp_values[15] = 10'd32;
    end
    
    // Stage 0: Counter update
    always @(posedge clk) begin
        if (rst) begin
            count <= 4'd0;
            enable_stage1 <= 1'b0;
        end else begin
            if (enable) begin
                count <= count + 4'd1;
            end
            enable_stage1 <= enable;
        end
    end
    
    // Stage 1: Address capture and ROM read
    always @(posedge clk) begin
        if (rst) begin
            count_stage1 <= 4'd0;
            exp_data_stage1 <= 10'd0;
            enable_stage2 <= 1'b0;
        end else begin
            count_stage1 <= count;
            exp_data_stage1 <= exp_values[count];
            enable_stage2 <= enable_stage1;
        end
    end
    
    // Stage 2: Final output
    always @(posedge clk) begin
        if (rst) begin
            count_stage2 <= 4'd0;
            exp_data_stage2 <= 10'd0;
            exp_out <= 10'd0;
        end else begin
            count_stage2 <= count_stage1;
            exp_data_stage2 <= exp_data_stage1;
            if (enable_stage2) begin
                exp_out <= exp_data_stage2;
            end
        end
    end
endmodule