//SystemVerilog
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
    
    // Karatsuba algorithm signals
    wire [7:0] a_high, a_low, shift_result_high, shift_result_low;
    wire [8:0] a_sum;
    wire [15:0] shift_product, shift_middle;
    
    // Split the data for Karatsuba multiplication
    assign a_high = inData[15:8];
    assign a_low = inData[7:0];
    assign a_sum = a_high + a_low;
    
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
    
    // Second pipeline stage - Apply Karatsuba algorithm for shifting
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stage2_data <= 16'b0;
            stage2_shift <= 4'b0;
        end else begin
            // Use lower bits of shift amount for initial shift
            stage2_data <= karatsuba_shifter(stage1_data, stage1_shift[1:0]);
            stage2_shift <= stage1_shift;
        end
    end
    
    // Final stage uses Karatsuba for the final shift
    assign outData = karatsuba_shifter(stage2_data, {2'b0, stage2_shift[3:2]});
    
    // Karatsuba-based shifter function
    function [15:0] karatsuba_shifter;
        input [15:0] data;
        input [3:0] shift_amount;
        reg [7:0] high, low;
        reg [15:0] p1, p2, p3;
        begin
            high = data[15:8];
            low = data[7:0];
            
            // Karatsuba algorithm adapted for shifting
            // p1 = high part shifted
            p1 = {high << shift_amount[1:0], 8'b0};
            
            // p2 = low part shifted
            p2 = {8'b0, low << shift_amount[1:0]};
            
            // p3 = (high+low) shifted
            p3 = ((high + low) << shift_amount[1:0]);
            
            // Combine using Karatsuba formula adapted for shifting
            karatsuba_shifter = p1 + p2;
            
            // Apply additional shifts based on higher bits if needed
            if (shift_amount[2])
                karatsuba_shifter = karatsuba_shifter << 4;
            if (shift_amount[3])
                karatsuba_shifter = karatsuba_shifter << 8;
        end
    endfunction
endmodule