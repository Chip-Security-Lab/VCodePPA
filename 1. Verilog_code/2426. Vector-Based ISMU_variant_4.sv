//SystemVerilog
module vector_ismu #(parameter VECTOR_WIDTH = 8)(
    input wire clk_i, rst_n_i,
    input wire [VECTOR_WIDTH-1:0] src_i,
    input wire [VECTOR_WIDTH-1:0] mask_i,
    input wire ack_i,
    input wire ready_i,
    output reg [VECTOR_WIDTH-1:0] vector_o,
    output reg valid_o,
    output wire ready_o
);
    // Reduced pipeline - Stage 1 registers (combines original stage 1 and 2)
    reg [VECTOR_WIDTH-1:0] pending_stage1;
    reg valid_stage1;
    
    // Stage 2 registers (was stage 3 in original)
    reg [VECTOR_WIDTH-1:0] vector_stage2;
    reg valid_stage2;
    
    // Pipeline control signals
    wire stall = valid_o && !ack_i;
    assign ready_o = !stall;
    
    // Combined Stage 1: Mask operation and Accumulation
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            pending_stage1 <= {VECTOR_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (ready_o) begin
            if (ready_i) begin
                // Directly apply mask and combine with pending data
                pending_stage1 <= pending_stage1 | (src_i & ~mask_i);
                valid_stage1 <= 1'b1;
            end else if (ack_i && valid_o) begin
                pending_stage1 <= {VECTOR_WIDTH{1'b0}};
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Output preparation
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            vector_stage2 <= {VECTOR_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (ready_o) begin
            vector_stage2 <= pending_stage1;
            valid_stage2 <= valid_stage1 && |pending_stage1;
        end
    end
    
    // Output registers
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            vector_o <= {VECTOR_WIDTH{1'b0}};
            valid_o <= 1'b0;
        end else if (ready_o) begin
            vector_o <= vector_stage2;
            valid_o <= valid_stage2;
        end else if (ack_i) begin
            valid_o <= 1'b0;
        end
    end
endmodule