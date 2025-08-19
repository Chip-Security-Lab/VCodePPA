//SystemVerilog
module vmem_ctrl #(parameter AW=12)(
    input clk,
    input rst_n, // Reset signal added for proper pipeline initialization
    output reg [AW-1:0] addr,
    output reg ref_en,
    // Pipeline control signals
    input pipeline_ready,
    output reg pipeline_valid
);

    // Pipeline stage registers
    reg [15:0] refresh_cnt_stage1;
    reg [15:0] refresh_cnt_stage2;
    reg ref_en_stage1;
    reg ref_en_stage2;
    reg [AW-1:0] addr_stage1;
    
    // Conditional complementary subtractor signals
    wire subtract_op;
    wire [15:0] operand_a, operand_b;
    wire [15:0] complemented_b;
    wire [15:0] sub_result;
    
    // Define subtraction operation and operands
    assign subtract_op = 1'b0; // Always performing addition (for counter increment)
    assign operand_a = refresh_cnt_stage1;
    assign operand_b = 16'h0001; // Increment by 1
    
    // Conditional complementary subtractor implementation
    assign complemented_b = subtract_op ? ~operand_b : operand_b;
    assign sub_result = operand_a + complemented_b + subtract_op;
    
    // Stage 1: Counter increment using subtractor and refresh detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_cnt_stage1 <= 16'b0;
            ref_en_stage1 <= 1'b0;
            pipeline_valid <= 1'b0;
        end 
        else if (pipeline_ready) begin
            refresh_cnt_stage1 <= sub_result;
            ref_en_stage1 <= (refresh_cnt_stage1[15:13] == 3'b111);
            pipeline_valid <= 1'b1;
        end
    end
    
    // Stage 2: Address selection and propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_cnt_stage2 <= 16'b0;
            ref_en_stage2 <= 1'b0;
            addr_stage1 <= {AW{1'b0}};
        end 
        else if (pipeline_ready) begin
            refresh_cnt_stage2 <= refresh_cnt_stage1;
            ref_en_stage2 <= ref_en_stage1;
            addr_stage1 <= ref_en_stage1 ? refresh_cnt_stage1[AW-1:0] : addr;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr <= {AW{1'b0}};
            ref_en <= 1'b0;
        end 
        else if (pipeline_ready) begin
            addr <= addr_stage1;
            ref_en <= ref_en_stage2;
        end
    end

endmodule