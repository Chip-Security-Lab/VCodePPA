//SystemVerilog
module Timer_Cascade #(parameter STAGES=2) (
    input clk, rst, en,
    output reg cascade_done
);
    // Internal signals
    genvar i;
    reg [STAGES:0] carry_stage2;
    reg [STAGES-1:0] carry_en;
    wire [STAGES:0] carry;
    
    // First pipeline stage signals - moved forward
    reg [1:0] cnt_lower_stage1 [STAGES-1:0];
    reg [1:0] cnt_upper_stage1 [STAGES-1:0];
    
    // Second pipeline stage signals
    reg [3:0] cnt_combined_stage2 [STAGES-1:0];
    
    // Input stage - register the enable signal to reduce input-to-register path
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            carry_en <= {STAGES{1'b0}};
        end
        else begin
            for(int j=0; j<STAGES; j=j+1) begin
                carry_en[j] <= en;
            end
        end
    end
    
    // First carry assignment directly from registered enable
    assign carry[0] = en;
    
    // Generate pipeline stages
    generate for(i=0; i<STAGES; i=i+1) begin: stage
        // Pipeline stage 1: Optimized counter logic
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                cnt_lower_stage1[i] <= 2'b00;
                cnt_upper_stage1[i] <= 2'b00;
            end
            else begin
                if (carry[i]) begin
                    // Handle lower 2 bits
                    cnt_lower_stage1[i] <= (cnt_lower_stage1[i] == 2'b11) ? 2'b00 : cnt_lower_stage1[i] + 1'b1;
                    
                    // Handle upper 2 bits
                    if (cnt_lower_stage1[i] == 2'b11) begin
                        cnt_upper_stage1[i] <= (cnt_upper_stage1[i] == 2'b11) ? 2'b00 : cnt_upper_stage1[i] + 1'b1;
                    end
                end
            end
        end
        
        // Pipeline stage 2: Combined counter bits and carry generation
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                cnt_combined_stage2[i] <= 4'b0000;
                carry_stage2[i+1] <= 1'b0;
            end
            else begin
                // Combine the upper and lower bits
                cnt_combined_stage2[i] <= {cnt_upper_stage1[i], cnt_lower_stage1[i]};
                
                // Generate carry for next stage - simplified logic
                carry_stage2[i+1] <= carry[i] && (cnt_upper_stage1[i] == 2'b11) && (cnt_lower_stage1[i] == 2'b11);
            end
        end
        
        // Connect carry to next stage
        assign carry[i+1] = carry_stage2[i+1];
    end endgenerate
    
    // Output stage
    always @(posedge clk or posedge rst) begin
        if (rst)
            cascade_done <= 1'b0;
        else
            cascade_done <= carry[STAGES];
    end
endmodule