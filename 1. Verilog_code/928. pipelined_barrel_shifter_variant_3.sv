//SystemVerilog
module pipelined_barrel_shifter(
    input [15:0] inData,
    input [3:0] shiftAmt,
    input clk,
    input rst,
    output reg [15:0] outData
);
    // Intermediate signals for combinational logic
    wire [15:0] shift_stage1;
    
    // First stage shift operation moved before register
    assign shift_stage1 = inData << (shiftAmt[1:0]);
    
    // Pipeline registers
    reg [15:0] stage2_data;
    reg [3:0] stage2_shift;
    
    // Second pipeline stage - receives pre-shifted data
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_data <= 16'b0;
            stage2_shift <= 4'b0;
        end else begin
            stage2_data <= shift_stage1;
            stage2_shift <= shiftAmt;
        end
    end
    
    // Final stage (registered output)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            outData <= 16'b0;
        end else begin
            outData <= stage2_data << (stage2_shift[3:2] * 4);
        end
    end
endmodule