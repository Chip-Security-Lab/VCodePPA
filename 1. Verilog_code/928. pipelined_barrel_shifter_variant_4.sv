//SystemVerilog
module pipelined_barrel_shifter(
    input [15:0] inData,
    input [3:0] shiftAmt,
    input clk,
    input rst,
    output [15:0] outData
);
    // Internal connections
    wire [15:0] stage1_data;
    wire [3:0] stage1_shift;
    wire [15:0] stage2_data;
    wire [3:0] stage2_shift;
    
    // Input stage module
    input_stage input_stage_inst (
        .clk(clk),
        .rst(rst),
        .inData(inData),
        .shiftAmt(shiftAmt),
        .stage1_data(stage1_data),
        .stage1_shift(stage1_shift)
    );
    
    // Middle stage module
    shift_stage1 shift_stage1_inst (
        .clk(clk),
        .rst(rst),
        .stage1_data(stage1_data),
        .stage1_shift(stage1_shift),
        .stage2_data(stage2_data),
        .stage2_shift(stage2_shift)
    );
    
    // Output stage module
    output_stage output_stage_inst (
        .stage2_data(stage2_data),
        .stage2_shift(stage2_shift),
        .outData(outData)
    );
endmodule

module input_stage(
    input clk,
    input rst,
    input [15:0] inData,
    input [3:0] shiftAmt,
    output reg [15:0] stage1_data,
    output reg [3:0] stage1_shift
);
    // First pipeline stage - register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage1_data <= 16'b0;
            stage1_shift <= 4'b0;
        end else begin
            stage1_data <= inData;
            stage1_shift <= shiftAmt;
        end
    end
endmodule

module shift_stage1(
    input clk,
    input rst,
    input [15:0] stage1_data,
    input [3:0] stage1_shift,
    output reg [15:0] stage2_data,
    output reg [3:0] stage2_shift
);
    // Second pipeline stage - perform first shift operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_data <= 16'b0;
            stage2_shift <= 4'b0;
        end else begin
            // Perform shift based on lower 2 bits of shift amount
            stage2_data <= stage1_data << (stage1_shift[1:0]);
            stage2_shift <= stage1_shift;
        end
    end
endmodule

module output_stage(
    input [15:0] stage2_data,
    input [3:0] stage2_shift,
    output [15:0] outData
);
    // Final stage - combinational logic for final shift
    assign outData = stage2_data << (stage2_shift[3:2] * 4);
endmodule