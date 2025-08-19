//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: seg_dynamic_scan
// Description: Dynamic segment display scanner with pipelined data flow
///////////////////////////////////////////////////////////////////////////////
module seg_dynamic_scan #(
    parameter N = 4
)(
    input wire clk,
    input wire [N*8-1:0] seg_data,
    output reg [3:0] sel,
    output reg [7:0] seg
);

    // Pipeline stage 1: Counter logic
    reg [1:0] cnt_r;
    
    // Pipeline stage 2: Segment data selection
    reg [7:0] seg_selected;
    reg [1:0] cnt_stage2;
    
    // Stage 1: Counter update logic - optimized with direct increment
    always @(posedge clk) begin
        cnt_r <= cnt_r + 1'b1;
    end
    
    // Stage 2: Segment data selection pipeline - optimized indexing
    always @(posedge clk) begin
        cnt_stage2 <= cnt_r;
        
        // Optimized segment data selection using case statement for better synthesis
        case(cnt_r)
            2'b00: seg_selected <= seg_data[7:0];
            2'b01: seg_selected <= seg_data[15:8];
            2'b10: seg_selected <= seg_data[23:16];
            2'b11: seg_selected <= seg_data[31:24];
        endcase
    end
    
    // Stage 3: Output generation pipeline
    always @(posedge clk) begin
        seg <= seg_selected;
        
        // Optimized one-hot decoding directly in the sequential block
        case(cnt_stage2)
            2'b00: sel <= 4'b1110;
            2'b01: sel <= 4'b1101;
            2'b10: sel <= 4'b1011;
            2'b11: sel <= 4'b0111;
        endcase
    end

endmodule