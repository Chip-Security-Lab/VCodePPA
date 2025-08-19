//SystemVerilog - IEEE 1364-2005
module config_priority_ismu #(
    parameter N_SRC = 8
)(
    input wire clock, resetn,
    input wire [N_SRC-1:0] interrupt_in,
    input wire [N_SRC-1:0] interrupt_mask,
    input wire [3*N_SRC-1:0] priority_config,
    output reg [2:0] highest_priority,
    output reg interrupt_valid
);
    // Stage 1: Extract priorities and valid interrupts
    wire [2:0] curr_priority [0:N_SRC-1];
    wire [N_SRC-1:0] valid_interrupt;
    reg [N_SRC-1:0] valid_interrupt_stage1;
    reg [2:0] curr_priority_stage1 [0:N_SRC-1];
    reg stage1_valid;

    // Stage 2: Find highest priority in first half
    reg [2:0] max_priority_half1;
    reg [2:0] max_idx_half1;
    reg half1_valid;
    reg stage2_valid;

    // Stage 3: Find highest priority in second half
    reg [2:0] max_priority_half2;
    reg [2:0] max_idx_half2;
    reg half2_valid;
    reg stage3_valid;

    // Stage 4: Determine final highest priority
    reg [2:0] final_max_priority;
    reg [2:0] final_max_idx;
    reg final_valid;

    genvar g;
    generate
        for (g = 0; g < N_SRC; g = g + 1) begin : priority_extract
            assign curr_priority[g] = priority_config[g*3+:3];
            assign valid_interrupt[g] = interrupt_in[g] && !interrupt_mask[g];
        end
    endgenerate

    integer i;

    // Pipeline Stage 1: Register priorities and valid interrupts
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (i = 0; i < N_SRC; i = i + 1) begin
                valid_interrupt_stage1[i] <= 1'b0;
                curr_priority_stage1[i] <= 3'd0;
            end
            stage1_valid <= 1'b0;
        end else begin
            for (i = 0; i < N_SRC; i = i + 1) begin
                valid_interrupt_stage1[i] <= valid_interrupt[i];
                curr_priority_stage1[i] <= curr_priority[i];
            end
            stage1_valid <= 1'b1;
        end
    end

    // Pipeline Stage 2: Process first half of interrupts
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            max_priority_half1 <= 3'd0;
            max_idx_half1 <= 3'd0;
            half1_valid <= 1'b0;
            stage2_valid <= 1'b0;
        end else begin
            max_priority_half1 <= 3'd0;
            max_idx_half1 <= 3'd0;
            half1_valid <= 1'b0;
            
            for (i = 0; i < N_SRC/2; i = i + 1) begin
                if (valid_interrupt_stage1[i] && (curr_priority_stage1[i] >= max_priority_half1)) begin
                    max_priority_half1 <= curr_priority_stage1[i];
                    max_idx_half1 <= i[2:0];
                    half1_valid <= 1'b1;
                end
            end
            stage2_valid <= stage1_valid;
        end
    end

    // Pipeline Stage 3: Process second half of interrupts
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            max_priority_half2 <= 3'd0;
            max_idx_half2 <= 3'd0;
            half2_valid <= 1'b0;
            stage3_valid <= 1'b0;
        end else begin
            max_priority_half2 <= 3'd0;
            max_idx_half2 <= 3'd0;
            half2_valid <= 1'b0;
            
            for (i = N_SRC/2; i < N_SRC; i = i + 1) begin
                if (valid_interrupt_stage1[i] && (curr_priority_stage1[i] >= max_priority_half2)) begin
                    max_priority_half2 <= curr_priority_stage1[i];
                    max_idx_half2 <= i[2:0];
                    half2_valid <= 1'b1;
                end
            end
            stage3_valid <= stage2_valid;
        end
    end

    // Pipeline Stage 4: Final comparison and output
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            interrupt_valid <= 1'b0;
            highest_priority <= 3'd0;
            final_valid <= 1'b0;
        end else begin
            if (half1_valid && half2_valid) begin
                // Both halves have valid interrupts, compare priorities
                if (max_priority_half2 > max_priority_half1) begin
                    highest_priority <= max_idx_half2;
                    final_valid <= 1'b1;
                end else begin
                    highest_priority <= max_idx_half1;
                    final_valid <= 1'b1;
                end
            end else if (half1_valid) begin
                highest_priority <= max_idx_half1;
                final_valid <= 1'b1;
            end else if (half2_valid) begin
                highest_priority <= max_idx_half2;
                final_valid <= 1'b1;
            end else begin
                final_valid <= 1'b0;
            end
            
            interrupt_valid <= final_valid && stage3_valid;
        end
    end
endmodule