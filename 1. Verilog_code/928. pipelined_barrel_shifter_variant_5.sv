//SystemVerilog
module pipelined_barrel_shifter(
    input [15:0] inData,
    input [3:0] shiftAmt,
    input clk,
    input rst,
    output reg [15:0] outData
);
    // Pipeline registers
    reg [15:0] stage1_data;
    reg [3:0] stage1_shift;
    reg [15:0] stage2_data_shifted;
    reg [1:0] stage2_shift_upper;
    
    // First pipeline stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage1_data <= 16'b0;
            stage1_shift <= 4'b0;
        end else begin
            stage1_data <= inData;
            stage1_shift <= shiftAmt;
        end
    end
    
    // Second pipeline stage (pre-computed LSB shift)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_data_shifted <= 16'b0;
            stage2_shift_upper <= 2'b0;
        end else begin
            stage2_data_shifted <= stage1_data << stage1_shift[1:0];
            stage2_shift_upper <= stage1_shift[3:2];
        end
    end
    
    // Output stage (registered output)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            outData <= 16'b0;
        end else begin
            outData <= stage2_data_shifted << (stage2_shift_upper * 4);
        end
    end
endmodule