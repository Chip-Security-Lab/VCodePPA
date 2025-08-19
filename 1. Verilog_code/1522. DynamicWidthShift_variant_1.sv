//SystemVerilog
// IEEE 1364-2005
module DynamicWidthShift #(parameter MAX_WIDTH=16) (
    input clk, rstn,
    input [$clog2(MAX_WIDTH)-1:0] width_sel,
    input din,
    input valid_in,
    output reg valid_out,
    output reg [MAX_WIDTH-1:0] q
);
    // Pipeline stage registers
    reg [$clog2(MAX_WIDTH)-1:0] width_sel_stage1, width_sel_stage2;
    reg [MAX_WIDTH-1:0] q_stage1, q_stage2;
    reg din_stage1;
    reg valid_stage1, valid_stage2;
    
    // Stage 1: Input capture and first half processing
    reg [MAX_WIDTH/2-1:0] next_q_stage1;
    integer i;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            width_sel_stage1 <= 0;
            q_stage1 <= 0;
            din_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            width_sel_stage1 <= width_sel;
            q_stage1 <= q;
            din_stage1 <= din;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Second half processing
    reg [MAX_WIDTH-1:0] next_q_stage2;
    integer j;
    
    always @(*) begin
        next_q_stage2[0] = din_stage1;
        for (j=1; j<MAX_WIDTH/2; j=j+1) begin
            next_q_stage2[j] = (j < width_sel_stage1) ? q_stage1[j-1] : q_stage1[j];
        end
    end
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            width_sel_stage2 <= 0;
            q_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            width_sel_stage2 <= width_sel_stage1;
            q_stage2[MAX_WIDTH/2-1:0] <= next_q_stage2[MAX_WIDTH/2-1:0];
            q_stage2[MAX_WIDTH-1:MAX_WIDTH/2] <= q_stage1[MAX_WIDTH-1:MAX_WIDTH/2];
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Final processing and output
    reg [MAX_WIDTH-1:0] next_q_final;
    integer k;
    
    always @(*) begin
        next_q_final[MAX_WIDTH/2-1:0] = q_stage2[MAX_WIDTH/2-1:0];
        for (k=MAX_WIDTH/2; k<MAX_WIDTH; k=k+1) begin
            next_q_final[k] = (k < width_sel_stage2) ? q_stage2[k-1] : q_stage2[k];
        end
    end
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            q <= {MAX_WIDTH{1'b0}};
            valid_out <= 0;
        end else begin
            q <= next_q_final;
            valid_out <= valid_stage2;
        end
    end
endmodule