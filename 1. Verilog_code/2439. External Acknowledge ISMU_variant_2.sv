//SystemVerilog - IEEE 1364-2005
module ext_ack_ismu(
    input wire i_clk, i_rst,
    input wire [3:0] i_int,
    input wire [3:0] i_mask,
    input wire i_ext_ack,
    input wire [1:0] i_ack_id,
    output reg o_int_req,
    output reg [1:0] o_int_id
);
    // Stage 1 signals
    reg [3:0] masked_int_stage1;
    reg [3:0] pending_stage1;
    reg i_ext_ack_stage1;
    reg [1:0] i_ack_id_stage1;
    reg stage1_valid;
    
    // Stage 2 signals
    reg [3:0] pending_stage2;
    reg stage2_valid;
    
    // Stage 3 signals
    reg [3:0] pending_stage3;
    reg stage3_valid;
    reg int_pending_stage3;
    
    // Combinational logic for stage 1
    wire [3:0] masked_int = i_int & ~i_mask;
    wire [3:0] next_pending = pending_stage1 | masked_int_stage1;
    wire [3:0] pending_after_ack = i_ext_ack_stage1 ? 
                                 (next_pending & ~(4'h1 << i_ack_id_stage1)) : 
                                 next_pending;
    
    // Pipeline stage 1 - Input and pending update
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            masked_int_stage1 <= 4'h0;
            pending_stage1 <= 4'h0;
            i_ext_ack_stage1 <= 1'b0;
            i_ack_id_stage1 <= 2'h0;
            stage1_valid <= 1'b0;
        end else begin
            masked_int_stage1 <= masked_int;
            pending_stage1 <= pending_after_ack;
            i_ext_ack_stage1 <= i_ext_ack;
            i_ack_id_stage1 <= i_ack_id;
            stage1_valid <= 1'b1;
        end
    end
    
    // Pipeline stage 2 - Intermediate stage to reduce critical path
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            pending_stage2 <= 4'h0;
            stage2_valid <= 1'b0;
        end else if (stage1_valid) begin
            pending_stage2 <= pending_stage1;
            stage2_valid <= stage1_valid;
        end
    end
    
    // Pipeline stage 3 - Calculate output signals
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            pending_stage3 <= 4'h0;
            stage3_valid <= 1'b0;
            int_pending_stage3 <= 1'b0;
        end else if (stage2_valid) begin
            pending_stage3 <= pending_stage2;
            stage3_valid <= stage2_valid;
            int_pending_stage3 <= |pending_stage2;
        end
    end
    
    // Output stage - Priority encoder for interrupt ID
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_int_req <= 1'b0;
            o_int_id <= 2'h0;
        end else if (stage3_valid) begin
            o_int_req <= int_pending_stage3;
            
            if (int_pending_stage3) begin
                o_int_id <= pending_stage3[0] ? 2'd0 : 
                           pending_stage3[1] ? 2'd1 : 
                           pending_stage3[2] ? 2'd2 : 2'd3;
            end
        end
    end
endmodule