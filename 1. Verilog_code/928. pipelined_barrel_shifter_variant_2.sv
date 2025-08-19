//SystemVerilog
module pipelined_barrel_shifter(
    input [15:0] inData,
    input [3:0] shiftAmt,
    input clk,
    input rst,
    output [15:0] outData
);
    // Pipeline registers
    reg [15:0] stage1_data, stage2_data, stage3_data;
    reg [3:0] stage1_shift, stage2_shift;
    reg [1:0] stage3_shift;
    
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
    
    // Second pipeline stage - handle first shift operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_data <= 16'b0;
            stage2_shift <= 4'b0;
        end else begin
            case(stage1_shift[1:0])
                2'b00: stage2_data <= stage1_data;
                2'b01: stage2_data <= {stage1_data[14:0], 1'b0};
                2'b10: stage2_data <= {stage1_data[13:0], 2'b0};
                2'b11: stage2_data <= {stage1_data[12:0], 3'b0};
            endcase
            stage2_shift <= stage1_shift;
        end
    end
    
    // Third pipeline stage - prepare for final shift
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage3_data <= 16'b0;
            stage3_shift <= 2'b0;
        end else begin
            stage3_data <= stage2_data;
            stage3_shift <= stage2_shift[3:2];
        end
    end
    
    // Final stage (registered output)
    reg [15:0] output_data;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            output_data <= 16'b0;
        end else begin
            case(stage3_shift)
                2'b00: output_data <= stage3_data;
                2'b01: output_data <= {stage3_data[11:0], 4'b0};
                2'b10: output_data <= {stage3_data[7:0], 8'b0};
                2'b11: output_data <= {stage3_data[3:0], 12'b0};
            endcase
        end
    end
    
    assign outData = output_data;
endmodule