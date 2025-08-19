//SystemVerilog
module axi_parity_checker (
    input aclk, arstn,
    input [31:0] tdata,
    input tvalid,
    output reg tparity
);
    // Stage 1 - Calculate parity for lower half
    reg [15:0] tdata_stage1;
    reg valid_stage1;
    reg parity_lower_stage1;
    
    // Stage 2 - Calculate parity for upper half
    reg [15:0] tdata_stage2;
    reg valid_stage2;
    reg parity_lower_stage2;
    reg parity_upper_stage2;
    
    // Stage 3 - Combine parities
    reg valid_stage3;
    reg parity_lower_stage3;
    reg parity_upper_stage3;
    
    // Stage 1 logic
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) begin
            tdata_stage1 <= 0;
            valid_stage1 <= 0;
            parity_lower_stage1 <= 0;
        end else begin
            valid_stage1 <= tvalid;
            if (tvalid) begin
                tdata_stage1 <= tdata[31:16];
                parity_lower_stage1 <= ^tdata[15:0];
            end
        end
    end
    
    // Stage 2 logic
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) begin
            tdata_stage2 <= 0;
            valid_stage2 <= 0;
            parity_lower_stage2 <= 0;
            parity_upper_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                parity_lower_stage2 <= parity_lower_stage1;
                parity_upper_stage2 <= ^tdata_stage1;
            end
        end
    end
    
    // Stage 3 logic
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) begin
            valid_stage3 <= 0;
            parity_lower_stage3 <= 0;
            parity_upper_stage3 <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                parity_lower_stage3 <= parity_lower_stage2;
                parity_upper_stage3 <= parity_upper_stage2;
            end
        end
    end
    
    // Output stage
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) begin
            tparity <= 0;
        end else if (valid_stage3) begin
            tparity <= parity_lower_stage3 ^ parity_upper_stage3;
        end
    end
endmodule