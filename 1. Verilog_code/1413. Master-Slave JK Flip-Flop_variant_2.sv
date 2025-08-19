//SystemVerilog
module ms_jk_flip_flop_pipelined (
    input wire clk,
    input wire reset_n,
    input wire valid_in,
    input wire j,
    input wire k,
    output wire q,
    output wire valid_out
);
    // Pipeline stage registers - extended from 3 to 5 stages
    reg master_stage1, master_stage2, master_stage3, master_stage4, master_stage5;
    reg slave_stage1, slave_stage2, slave_stage3, slave_stage4, slave_stage5;
    
    // Valid signals for pipeline tracking - extended for 5 stages
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5;
    
    // Intermediate computation signals
    reg j_stage1, k_stage1;
    reg computation_result_stage1;
    
    // Pipeline stage 1: Input capture
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            j_stage1 <= 1'b0;
            k_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
            if (valid_in) begin
                j_stage1 <= j;
                k_stage1 <= k;
            end
        end
    end
    
    // Pipeline stage 2: Decision logic computation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            computation_result_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                case ({j_stage1, k_stage1})
                    2'b00: computation_result_stage1 <= master_stage5; // Feedback
                    2'b01: computation_result_stage1 <= 1'b0;
                    2'b10: computation_result_stage1 <= 1'b1;
                    2'b11: computation_result_stage1 <= ~master_stage5; // Feedback
                endcase
            end
        end
    end
    
    // Pipeline stage 3: First stage of master computation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            master_stage1 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            master_stage1 <= computation_result_stage1;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Pipeline stage 4: Second stage of master computation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            master_stage2 <= 1'b0;
            valid_stage4 <= 1'b0;
        end else begin
            master_stage2 <= master_stage1;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Pipeline stage 5: Third stage of master computation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            master_stage3 <= 1'b0;
            valid_stage5 <= 1'b0;
        end else begin
            master_stage3 <= master_stage2;
            valid_stage5 <= valid_stage4;
        end
    end
    
    // Pipeline stage 6: Fourth stage of master computation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            master_stage4 <= 1'b0;
        end else begin
            master_stage4 <= master_stage3;
        end
    end
    
    // Pipeline stage 7: Final master computation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            master_stage5 <= 1'b0;
        end else begin
            master_stage5 <= master_stage4;
        end
    end
    
    // Slave stages follow the master with phase shift
    // First slave stage
    always @(negedge clk or negedge reset_n) begin
        if (!reset_n) begin
            slave_stage1 <= 1'b0;
        end else if (valid_stage5) begin
            slave_stage1 <= master_stage5;
        end
    end
    
    // Second slave stage
    always @(negedge clk or negedge reset_n) begin
        if (!reset_n) begin
            slave_stage2 <= 1'b0;
        end else begin
            slave_stage2 <= slave_stage1;
        end
    end
    
    // Third slave stage
    always @(negedge clk or negedge reset_n) begin
        if (!reset_n) begin
            slave_stage3 <= 1'b0;
        end else begin
            slave_stage3 <= slave_stage2;
        end
    end
    
    // Fourth slave stage
    always @(negedge clk or negedge reset_n) begin
        if (!reset_n) begin
            slave_stage4 <= 1'b0;
        end else begin
            slave_stage4 <= slave_stage3;
        end
    end
    
    // Fifth slave stage
    always @(negedge clk or negedge reset_n) begin
        if (!reset_n) begin
            slave_stage5 <= 1'b0;
        end else begin
            slave_stage5 <= slave_stage4;
        end
    end
    
    // Output assignment
    assign q = slave_stage5;
    assign valid_out = valid_stage5;
    
endmodule