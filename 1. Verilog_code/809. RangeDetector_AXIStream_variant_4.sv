//SystemVerilog
module RangeDetector_AXIStream #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input tvalid,
    input [WIDTH-1:0] tdata,
    input [WIDTH-1:0] lower,
    input [WIDTH-1:0] upper,
    output reg tvalid_out,
    output reg [WIDTH-1:0] tdata_out
);

    // Pipeline stage 1 registers
    reg tvalid_stage1;
    reg [WIDTH-1:0] tdata_stage1;
    reg [WIDTH-1:0] lower_stage1;
    reg [WIDTH-1:0] upper_stage1;
    
    // Pipeline stage 2 registers
    reg tvalid_stage2;
    reg [WIDTH-1:0] tdata_stage2;
    reg lower_compare_stage2;
    reg upper_compare_stage2;
    
    // Pipeline stage 3 registers
    reg tvalid_stage3;
    reg [WIDTH-1:0] tdata_stage3;
    reg range_check_stage3;

    // Stage 1: Input registration - Valid signal
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tvalid_stage1 <= 0;
        end
        else begin
            tvalid_stage1 <= tvalid;
        end
    end

    // Stage 1: Input registration - Data signals
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tdata_stage1 <= 0;
            lower_stage1 <= 0;
            upper_stage1 <= 0;
        end
        else begin
            tdata_stage1 <= tdata;
            lower_stage1 <= lower;
            upper_stage1 <= upper;
        end
    end

    // Stage 2: Range comparison - Valid and data forwarding
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tvalid_stage2 <= 0;
            tdata_stage2 <= 0;
        end
        else begin
            tvalid_stage2 <= tvalid_stage1;
            tdata_stage2 <= tdata_stage1;
        end
    end

    // Stage 2: Range comparison - Boundary checks
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            lower_compare_stage2 <= 0;
            upper_compare_stage2 <= 0;
        end
        else begin
            lower_compare_stage2 <= (tdata_stage1 >= lower_stage1);
            upper_compare_stage2 <= (tdata_stage1 <= upper_stage1);
        end
    end

    // Stage 3: Range check - Valid and data forwarding
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tvalid_stage3 <= 0;
            tdata_stage3 <= 0;
        end
        else begin
            tvalid_stage3 <= tvalid_stage2;
            tdata_stage3 <= tdata_stage2;
        end
    end

    // Stage 3: Range check - Final range validation
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            range_check_stage3 <= 0;
        end
        else begin
            range_check_stage3 <= lower_compare_stage2 && upper_compare_stage2;
        end
    end

    // Output stage - Valid signal
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tvalid_out <= 0;
        end
        else begin
            tvalid_out <= tvalid_stage3;
        end
    end

    // Output stage - Data signal with range filtering
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            tdata_out <= 0;
        end
        else begin
            tdata_out <= range_check_stage3 ? tdata_stage3 : 0;
        end
    end

endmodule