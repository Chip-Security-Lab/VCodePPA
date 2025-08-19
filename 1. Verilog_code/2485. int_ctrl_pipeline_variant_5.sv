//SystemVerilog
module int_ctrl_pipeline #(
    parameter DW = 8
)(
    input wire clk,
    input wire en,
    input wire [DW-1:0] req_in,
    output reg [DW-1:0] req_q,
    output reg [3:0] curr_pri
);
    // Input stage registers
    reg [DW-1:0] req_in_reg;
    reg [DW-1:0] req_q_stage1;
    
    // Priority encoder pipeline registers
    reg [DW-1:0] combined_req_reg;
    reg [3:0] new_pri_stage1;
    
    // Mask generation pipeline registers
    reg [DW-1:0] clear_mask_reg;
    
    // Priority encoder function - optimized for timing
    function [3:0] find_highest_pri;
        input [DW-1:0] req;
        reg [3:0] pri;
        begin
            pri = 4'd0; // Default priority
            casez(req)
                8'b1???_????: pri = 4'd7;
                8'b01??_????: pri = 4'd6;
                8'b001?_????: pri = 4'd5;
                8'b0001_????: pri = 4'd4;
                8'b0000_1???: pri = 4'd3;
                8'b0000_01??: pri = 4'd2;
                8'b0000_001?: pri = 4'd1;
                8'b0000_0001: pri = 4'd0;
                default:      pri = 4'd0;
            endcase
            find_highest_pri = pri;
        end
    endfunction
    
    // Stage 1: Input registration and request combination
    always @(posedge clk) begin
        if (en) begin
            req_in_reg <= req_in;
            req_q_stage1 <= req_q;
        end
    end
    
    // Data path: Request combination
    wire [DW-1:0] combined_req;
    assign combined_req = req_in_reg | req_q_stage1;
    
    // Stage 2: Priority calculation and mask preparation
    always @(posedge clk) begin
        if (en) begin
            combined_req_reg <= combined_req;
            new_pri_stage1 <= find_highest_pri(combined_req);
        end
    end
    
    // Data path: Clear mask generation using 2's complement addition
    wire [DW-1:0] clear_mask;
    wire [3:0] index_plus_one;
    wire [3:0] complement_index;
    
    // Using 2's complement addition to implement subtraction
    // We need to compute (DW-1) - new_pri_stage1 for proper shifting
    assign complement_index = ~new_pri_stage1;
    assign index_plus_one = complement_index + 4'b0001; // 2's complement representation
    assign clear_mask = (new_pri_stage1 == 4'b0) ? 8'h01 : (8'h01 << new_pri_stage1);
    
    // Stage 3: Final output preparation
    always @(posedge clk) begin
        if (en) begin
            clear_mask_reg <= clear_mask;
            curr_pri <= new_pri_stage1;
        end
    end
    
    // Final stage: Result calculation using 2's complement for subtraction
    wire [DW-1:0] inverted_mask;
    wire [DW-1:0] result_mask;
    
    assign inverted_mask = ~clear_mask_reg;
    assign result_mask = inverted_mask + 8'h01; // 2's complement of mask
    
    always @(posedge clk) begin
        if (en) begin
            // Using AND with inverted mask which is equivalent to subtraction
            req_q <= combined_req_reg & inverted_mask;
        end
    end
endmodule