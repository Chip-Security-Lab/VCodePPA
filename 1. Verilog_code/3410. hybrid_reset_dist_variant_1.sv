//SystemVerilog
module hybrid_reset_dist(
    input wire clk,
    input wire async_rst,
    input wire sync_rst,
    input wire [3:0] mode_select,
    output reg [3:0] reset_out,
    // Pipeline control signals
    input wire valid_in,
    output wire ready_out,
    output reg valid_out
);
    // Pipeline registers for signals
    reg sync_rst_stage1, sync_rst_stage2;
    reg [3:0] mode_select_stage1, mode_select_stage2;
    reg [3:0] intermediate_result_stage1;
    reg valid_stage1, valid_stage2;
    
    // Ready signal generation
    assign ready_out = !valid_stage1 || !valid_stage2;
    
    // Stage 1: Clock sync_rst signal
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            sync_rst_stage1 <= 1'b0;
        else if (valid_in && ready_out)
            sync_rst_stage1 <= sync_rst;
    end
    
    // Stage 1: Clock mode_select signal
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            mode_select_stage1 <= 4'b0000;
        else if (valid_in && ready_out)
            mode_select_stage1 <= mode_select;
    end
    
    // Stage 1: Compute intermediate result
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            intermediate_result_stage1 <= 4'b0000;
        else if (valid_in && ready_out)
            intermediate_result_stage1 <= mode_select & 4'b1111;
    end
    
    // Stage 1: Control valid signal
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            valid_stage1 <= 1'b0;
        else if (valid_in && ready_out)
            valid_stage1 <= 1'b1;
        else if (!valid_stage2)
            valid_stage1 <= 1'b0;
    end
    
    // Stage 2: Clock sync_rst signal
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            sync_rst_stage2 <= 1'b0;
        else if (valid_stage1)
            sync_rst_stage2 <= sync_rst_stage1;
    end
    
    // Stage 2: Clock mode_select signal
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            mode_select_stage2 <= 4'b0000;
        else if (valid_stage1)
            mode_select_stage2 <= mode_select_stage1;
    end
    
    // Stage 2: Control valid signal
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            valid_stage2 <= 1'b0;
        else if (valid_stage1)
            valid_stage2 <= 1'b1;
        else
            valid_stage2 <= 1'b0;
    end
    
    // Stage 2: Generate output valid signal
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            valid_out <= 1'b0;
        else if (valid_stage1)
            valid_out <= 1'b1;
        else
            valid_out <= 1'b0;
    end
    
    // Stage 2: Generate final reset output
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            reset_out <= 4'b1111; // Initial async reset state
        else if (valid_stage1) begin
            if (sync_rst_stage1)
                reset_out <= intermediate_result_stage1;
            else
                reset_out <= 4'b0000;
        end
    end
    
endmodule