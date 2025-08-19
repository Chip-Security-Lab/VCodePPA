//SystemVerilog
module axi_parity_checker (
    input aclk, arstn,
    input [31:0] tdata,
    input tvalid,
    output reg tparity
);
    // Pipeline stage 1 signals
    reg [15:0] tdata_upper_stage1, tdata_lower_stage1;
    reg tvalid_stage1;
    
    // Pipeline stage 2 signals
    reg [7:0] tdata_upper_upper_stage2, tdata_upper_lower_stage2;
    reg [7:0] tdata_lower_upper_stage2, tdata_lower_lower_stage2;
    reg tvalid_stage2;
    
    // Pipeline stage 3 signals
    reg [3:0] parity_stage3;
    reg tvalid_stage3;
    
    // Pipeline stage 4 signals
    reg [1:0] parity_stage4;
    reg tvalid_stage4;
    
    // Stage 1: Split data into upper and lower halves
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) begin
            tdata_upper_stage1 <= 16'd0;
            tdata_lower_stage1 <= 16'd0;
            tvalid_stage1 <= 1'b0;
        end
        else begin
            tdata_upper_stage1 <= tdata[31:16];
            tdata_lower_stage1 <= tdata[15:0];
            tvalid_stage1 <= tvalid;
        end
    end
    
    // Stage 2: Further split into smaller chunks
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) begin
            tdata_upper_upper_stage2 <= 8'd0;
            tdata_upper_lower_stage2 <= 8'd0;
            tdata_lower_upper_stage2 <= 8'd0;
            tdata_lower_lower_stage2 <= 8'd0;
            tvalid_stage2 <= 1'b0;
        end
        else begin
            tdata_upper_upper_stage2 <= tdata_upper_stage1[15:8];
            tdata_upper_lower_stage2 <= tdata_upper_stage1[7:0];
            tdata_lower_upper_stage2 <= tdata_lower_stage1[15:8];
            tdata_lower_lower_stage2 <= tdata_lower_stage1[7:0];
            tvalid_stage2 <= tvalid_stage1;
        end
    end
    
    // Stage 3: Calculate parity of each chunk
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) begin
            parity_stage3 <= 4'd0;
            tvalid_stage3 <= 1'b0;
        end
        else begin
            parity_stage3[3] <= ^tdata_upper_upper_stage2;
            parity_stage3[2] <= ^tdata_upper_lower_stage2;
            parity_stage3[1] <= ^tdata_lower_upper_stage2;
            parity_stage3[0] <= ^tdata_lower_lower_stage2;
            tvalid_stage3 <= tvalid_stage2;
        end
    end
    
    // Stage 4: Combine parity bits from upper and lower chunks
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) begin
            parity_stage4 <= 2'd0;
            tvalid_stage4 <= 1'b0;
        end
        else begin
            parity_stage4[1] <= parity_stage3[3] ^ parity_stage3[2];
            parity_stage4[0] <= parity_stage3[1] ^ parity_stage3[0];
            tvalid_stage4 <= tvalid_stage3;
        end
    end
    
    // Final stage: Combine parities of all chunks
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) begin
            tparity <= 1'b0;
        end
        else if (tvalid_stage4) begin
            tparity <= parity_stage4[1] ^ parity_stage4[0];
        end
    end
endmodule