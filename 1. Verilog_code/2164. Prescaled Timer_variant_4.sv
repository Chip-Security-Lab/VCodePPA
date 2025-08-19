//SystemVerilog
module prescaled_timer (
    input wire i_clk, i_arst, i_enable,
    input wire [7:0] i_prescale,
    input wire [15:0] i_max,
    output reg [15:0] o_count,
    output wire o_match
);
    // Stage 1: Prescaler pipeline
    reg [7:0] pre_cnt_stage1;
    reg [7:0] i_prescale_stage1;
    reg i_enable_stage1;
    reg pre_tick_stage1;
    
    // Stage 2: Counter pipeline
    reg [15:0] o_count_stage2;
    reg [15:0] i_max_stage2;
    reg i_enable_stage2;
    reg pre_tick_stage2;
    
    // Pipeline valid signals
    reg stage1_valid, stage2_valid;
    
    // Stage 1: Prescaler logic
    always @(posedge i_clk or posedge i_arst) begin
        if (i_arst) begin
            pre_cnt_stage1 <= 8'd0;
            i_prescale_stage1 <= 8'd0;
            i_enable_stage1 <= 1'b0;
            pre_tick_stage1 <= 1'b0;
            stage1_valid <= 1'b0;
        end
        else begin
            i_prescale_stage1 <= i_prescale;
            i_enable_stage1 <= i_enable;
            stage1_valid <= 1'b1;
            
            if (i_enable) begin
                if (pre_cnt_stage1 >= i_prescale) begin
                    pre_cnt_stage1 <= 8'd0;
                    pre_tick_stage1 <= 1'b1;
                end
                else begin
                    pre_cnt_stage1 <= pre_cnt_stage1 + 8'd1;
                    pre_tick_stage1 <= 1'b0;
                end
            end
            else begin
                pre_tick_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Counter pipeline registers
    always @(posedge i_clk or posedge i_arst) begin
        if (i_arst) begin
            o_count_stage2 <= 16'd0;
            i_max_stage2 <= 16'd0;
            i_enable_stage2 <= 1'b0;
            pre_tick_stage2 <= 1'b0;
            stage2_valid <= 1'b0;
        end
        else begin
            i_max_stage2 <= i_max;
            i_enable_stage2 <= i_enable_stage1;
            pre_tick_stage2 <= pre_tick_stage1;
            stage2_valid <= stage1_valid;
            
            if (i_enable_stage1 && pre_tick_stage1) begin
                if (o_count_stage2 >= i_max_stage2) begin
                    o_count_stage2 <= 16'd0;
                end
                else begin
                    o_count_stage2 <= o_count_stage2 + 16'd1;
                end
            end
        end
    end
    
    // Output stage
    always @(posedge i_clk or posedge i_arst) begin
        if (i_arst) begin
            o_count <= 16'd0;
        end
        else if (stage2_valid) begin
            o_count <= o_count_stage2;
        end
    end
    
    // Match detection in output stage
    assign o_match = stage2_valid && (o_count_stage2 == i_max_stage2);
    
endmodule