module pipelined_barrel_shifter(
    input [15:0] inData,
    input [3:0] shiftAmt,
    input clk,
    input rst,
    output [15:0] outData
);
    // Pipeline registers
    reg [15:0] stage1_data, stage2_data;
    reg [3:0] stage1_shift, stage2_shift;
    
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
    
    // Second pipeline stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_data <= 16'b0;
            stage2_shift <= 4'b0;
        end else begin
            stage2_data <= stage1_data << (stage1_shift[1:0]);
            stage2_shift <= stage1_shift;
        end
    end
    
    // Final stage (combinational)
    assign outData = stage2_data << (stage2_shift[3:2] * 4);
endmodule