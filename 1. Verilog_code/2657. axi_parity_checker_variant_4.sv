//SystemVerilog
module axi_parity_checker (
    input aclk, arstn,
    input [31:0] tdata,
    input tvalid,
    output reg tparity
);
    // Pipeline stage 1 registers
    reg [31:0] tdata_stage1;
    reg tvalid_stage1;
    reg [1:0] ctrl_stage1;
    
    // Pipeline stage 2 registers
    reg tparity_stage2;
    reg tvalid_stage2;
    
    // Stage 1: Input and control processing
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) begin
            tdata_stage1 <= 32'b0;
            tvalid_stage1 <= 1'b0;
            ctrl_stage1 <= 2'b0;
        end else begin
            tdata_stage1 <= tdata;
            tvalid_stage1 <= tvalid;
            ctrl_stage1 <= {!arstn, tvalid};
        end
    end
    
    // Stage 2: Parity calculation
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) begin
            tparity_stage2 <= 1'b0;
            tvalid_stage2 <= 1'b0;
        end else begin
            tvalid_stage2 <= tvalid_stage1;
            case (ctrl_stage1)
                2'b10, 2'b11: tparity_stage2 <= 1'b0;
                2'b01:        tparity_stage2 <= ^tdata_stage1;
                2'b00:        tparity_stage2 <= tparity_stage2;
            endcase
        end
    end
    
    // Output stage
    always @(posedge aclk or negedge arstn) begin
        if (!arstn) begin
            tparity <= 1'b0;
        end else begin
            tparity <= tparity_stage2;
        end
    end
endmodule