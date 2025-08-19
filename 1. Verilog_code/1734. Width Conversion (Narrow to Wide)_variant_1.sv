//SystemVerilog
module n2w_bridge_pipeline #(parameter NARROW=8, WIDE=32) (
    input clk, rst_n, enable,
    input [NARROW-1:0] narrow_data,
    input narrow_valid,
    output reg narrow_ready,
    output reg [WIDE-1:0] wide_data,
    output reg wide_valid,
    input wide_ready
);
    localparam RATIO = WIDE/NARROW;
    localparam COUNT_WIDTH = $clog2(RATIO);
    
    reg [WIDE-1:0] buffer_stage1, buffer_stage2;
    reg [COUNT_WIDTH:0] count_stage1, count_stage2;
    reg narrow_ready_stage1, narrow_ready_stage2;
    reg wide_valid_stage1, wide_valid_stage2;
    
    wire count_full = (count_stage1 == RATIO-1);
    wire count_empty = (count_stage1 == 0);
    wire stage1_ready = narrow_valid && narrow_ready;
    wire stage2_ready = wide_valid_stage1 && wide_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {buffer_stage1, buffer_stage2} <= 0;
            {count_stage1, count_stage2} <= 0;
            {wide_valid, narrow_ready} <= 2'b01;
        end else if (enable) begin
            // Stage 1: Input processing
            narrow_ready_stage1 <= stage1_ready ? 1'b0 : 1'b1;
            if (stage1_ready) begin
                buffer_stage1 <= {buffer_stage1[WIDE-NARROW-1:0], narrow_data};
                count_stage1 <= count_stage1 + 1'b1;
            end
            
            // Stage 2: Output processing
            wide_valid_stage1 <= count_full;
            if (count_full) begin
                wide_data <= {narrow_data, buffer_stage1[WIDE-NARROW-1:0]};
                count_stage2 <= 0;
            end

            // Pipeline update
            buffer_stage2 <= buffer_stage1;
            count_stage2 <= count_stage1;
            wide_valid <= stage2_ready;
            narrow_ready <= narrow_ready_stage1;
        end
    end
endmodule