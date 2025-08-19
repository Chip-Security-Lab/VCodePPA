//SystemVerilog
module int_ctrl_adapt #(
    parameter N = 4
)(
    input clk, rst,
    input [N-1:0] req,
    input [N-1:0] service_time,
    output reg [N-1:0] grant
);
    // Pipeline stage 1: History counter update and priority computation
    reg [7:0] hist_counter[0:N-1];
    reg [7:0] min_hist_stage1;
    reg [N-1:0] valid_req_stage1;
    reg [N-1:0] req_stage1;
    reg [2:0] min_idx_stage1;
    
    // Intermediate combinational signals to break long paths
    wire [N-1:0] update_needed;
    wire [7:0] new_hist_values[0:N-1];
    wire [N-1:0] is_valid_req;
    
    // Stage 2 registers
    reg [7:0] min_hist_stage2;
    reg [N-1:0] valid_req_stage2;
    reg [2:0] min_idx_stage2;
    reg [N-1:0] req_stage2;
    
    integer i;
    
    // Pre-compute update conditions to reduce critical path
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : gen_update_logic
            assign update_needed[g] = req[g] && service_time[g] && (hist_counter[g] > service_time[g]);
            assign new_hist_values[g] = update_needed[g] ? service_time[g] : hist_counter[g];
            assign is_valid_req[g] = req[g];
        end
    endgenerate
    
    // Stage 1: Update history counters and identify requests
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1)
                hist_counter[i] <= 8'hFF;
                
            valid_req_stage1 <= 0;
            min_hist_stage1 <= 8'hFF;
            min_idx_stage1 <= 0;
            req_stage1 <= 0;
        end 
        else begin
            // Update history counters using pre-computed values
            for (i = 0; i < N; i = i + 1) begin
                hist_counter[i] <= new_hist_values[i];
            end
            
            // Capture request signals
            req_stage1 <= req;
            valid_req_stage1 <= is_valid_req;
            
            // Find minimum history using balanced tree approach
            min_hist_stage1 <= 8'hFF;
            min_idx_stage1 <= 0;
            
            // First compare entries 0,1 and 2,3 in parallel
            // Then compare the winners
            if (N >= 4) begin
                if (is_valid_req[0] && is_valid_req[1]) begin
                    if (hist_counter[0] <= hist_counter[1]) begin
                        if (is_valid_req[2] && is_valid_req[3]) begin
                            if (hist_counter[2] <= hist_counter[3]) begin
                                // Compare 0 vs 2
                                if (hist_counter[0] <= hist_counter[2]) begin
                                    min_hist_stage1 <= hist_counter[0];
                                    min_idx_stage1 <= 0;
                                end else begin
                                    min_hist_stage1 <= hist_counter[2];
                                    min_idx_stage1 <= 2;
                                end
                            end else begin
                                // Compare 0 vs 3
                                if (hist_counter[0] <= hist_counter[3]) begin
                                    min_hist_stage1 <= hist_counter[0];
                                    min_idx_stage1 <= 0;
                                end else begin
                                    min_hist_stage1 <= hist_counter[3];
                                    min_idx_stage1 <= 3;
                                end
                            end
                        end else if (is_valid_req[2]) begin
                            // Compare 0 vs 2
                            if (hist_counter[0] <= hist_counter[2]) begin
                                min_hist_stage1 <= hist_counter[0];
                                min_idx_stage1 <= 0;
                            end else begin
                                min_hist_stage1 <= hist_counter[2];
                                min_idx_stage1 <= 2;
                            end
                        end else if (is_valid_req[3]) begin
                            // Compare 0 vs 3
                            if (hist_counter[0] <= hist_counter[3]) begin
                                min_hist_stage1 <= hist_counter[0];
                                min_idx_stage1 <= 0;
                            end else begin
                                min_hist_stage1 <= hist_counter[3];
                                min_idx_stage1 <= 3;
                            end
                        end else begin
                            min_hist_stage1 <= hist_counter[0];
                            min_idx_stage1 <= 0;
                        end
                    end else begin
                        if (is_valid_req[2] && is_valid_req[3]) begin
                            if (hist_counter[2] <= hist_counter[3]) begin
                                // Compare 1 vs 2
                                if (hist_counter[1] <= hist_counter[2]) begin
                                    min_hist_stage1 <= hist_counter[1];
                                    min_idx_stage1 <= 1;
                                end else begin
                                    min_hist_stage1 <= hist_counter[2];
                                    min_idx_stage1 <= 2;
                                end
                            end else begin
                                // Compare 1 vs 3
                                if (hist_counter[1] <= hist_counter[3]) begin
                                    min_hist_stage1 <= hist_counter[1];
                                    min_idx_stage1 <= 1;
                                end else begin
                                    min_hist_stage1 <= hist_counter[3];
                                    min_idx_stage1 <= 3;
                                end
                            end
                        end else if (is_valid_req[2]) begin
                            // Compare 1 vs 2
                            if (hist_counter[1] <= hist_counter[2]) begin
                                min_hist_stage1 <= hist_counter[1];
                                min_idx_stage1 <= 1;
                            end else begin
                                min_hist_stage1 <= hist_counter[2];
                                min_idx_stage1 <= 2;
                            end
                        end else if (is_valid_req[3]) begin
                            // Compare 1 vs 3
                            if (hist_counter[1] <= hist_counter[3]) begin
                                min_hist_stage1 <= hist_counter[1];
                                min_idx_stage1 <= 1;
                            end else begin
                                min_hist_stage1 <= hist_counter[3];
                                min_idx_stage1 <= 3;
                            end
                        end else begin
                            min_hist_stage1 <= hist_counter[1];
                            min_idx_stage1 <= 1;
                        end
                    end
                end else if (is_valid_req[0]) begin
                    if (is_valid_req[2] && is_valid_req[3]) begin
                        if (hist_counter[2] <= hist_counter[3]) begin
                            // Compare 0 vs 2
                            if (hist_counter[0] <= hist_counter[2]) begin
                                min_hist_stage1 <= hist_counter[0];
                                min_idx_stage1 <= 0;
                            end else begin
                                min_hist_stage1 <= hist_counter[2];
                                min_idx_stage1 <= 2;
                            end
                        end else begin
                            // Compare 0 vs 3
                            if (hist_counter[0] <= hist_counter[3]) begin
                                min_hist_stage1 <= hist_counter[0];
                                min_idx_stage1 <= 0;
                            end else begin
                                min_hist_stage1 <= hist_counter[3];
                                min_idx_stage1 <= 3;
                            end
                        end
                    end else if (is_valid_req[2]) begin
                        // Compare 0 vs 2
                        if (hist_counter[0] <= hist_counter[2]) begin
                            min_hist_stage1 <= hist_counter[0];
                            min_idx_stage1 <= 0;
                        end else begin
                            min_hist_stage1 <= hist_counter[2];
                            min_idx_stage1 <= 2;
                        end
                    end else if (is_valid_req[3]) begin
                        // Compare 0 vs 3
                        if (hist_counter[0] <= hist_counter[3]) begin
                            min_hist_stage1 <= hist_counter[0];
                            min_idx_stage1 <= 0;
                        end else begin
                            min_hist_stage1 <= hist_counter[3];
                            min_idx_stage1 <= 3;
                        end
                    end else begin
                        min_hist_stage1 <= hist_counter[0];
                        min_idx_stage1 <= 0;
                    end
                end else if (is_valid_req[1]) begin
                    if (is_valid_req[2] && is_valid_req[3]) begin
                        if (hist_counter[2] <= hist_counter[3]) begin
                            // Compare 1 vs 2
                            if (hist_counter[1] <= hist_counter[2]) begin
                                min_hist_stage1 <= hist_counter[1];
                                min_idx_stage1 <= 1;
                            end else begin
                                min_hist_stage1 <= hist_counter[2];
                                min_idx_stage1 <= 2;
                            end
                        end else begin
                            // Compare 1 vs 3
                            if (hist_counter[1] <= hist_counter[3]) begin
                                min_hist_stage1 <= hist_counter[1];
                                min_idx_stage1 <= 1;
                            end else begin
                                min_hist_stage1 <= hist_counter[3];
                                min_idx_stage1 <= 3;
                            end
                        end
                    end else if (is_valid_req[2]) begin
                        // Compare 1 vs 2
                        if (hist_counter[1] <= hist_counter[2]) begin
                            min_hist_stage1 <= hist_counter[1];
                            min_idx_stage1 <= 1;
                        end else begin
                            min_hist_stage1 <= hist_counter[2];
                            min_idx_stage1 <= 2;
                        end
                    end else if (is_valid_req[3]) begin
                        // Compare 1 vs 3
                        if (hist_counter[1] <= hist_counter[3]) begin
                            min_hist_stage1 <= hist_counter[1];
                            min_idx_stage1 <= 1;
                        end else begin
                            min_hist_stage1 <= hist_counter[3];
                            min_idx_stage1 <= 3;
                        end
                    end else begin
                        min_hist_stage1 <= hist_counter[1];
                        min_idx_stage1 <= 1;
                    end
                end else if (is_valid_req[2] && is_valid_req[3]) begin
                    if (hist_counter[2] <= hist_counter[3]) begin
                        min_hist_stage1 <= hist_counter[2];
                        min_idx_stage1 <= 2;
                    end else begin
                        min_hist_stage1 <= hist_counter[3];
                        min_idx_stage1 <= 3;
                    end
                end else if (is_valid_req[2]) begin
                    min_hist_stage1 <= hist_counter[2];
                    min_idx_stage1 <= 2;
                end else if (is_valid_req[3]) begin
                    min_hist_stage1 <= hist_counter[3];
                    min_idx_stage1 <= 3;
                end
            end else begin
                // Handle smaller N values
                for (i = 0; i < N; i = i + 1) begin
                    if (is_valid_req[i] && hist_counter[i] < min_hist_stage1) begin
                        min_hist_stage1 <= hist_counter[i];
                        min_idx_stage1 <= i;
                    end
                end
            end
        end
    end
    
    // Stage 2: Generate grant signals based on priority
    always @(posedge clk) begin
        if (rst) begin
            min_hist_stage2 <= 8'hFF;
            valid_req_stage2 <= 0;
            min_idx_stage2 <= 0;
            req_stage2 <= 0;
            grant <= 0;
        end 
        else begin
            // Forward stage 1 data to stage 2
            min_hist_stage2 <= min_hist_stage1;
            valid_req_stage2 <= valid_req_stage1;
            min_idx_stage2 <= min_idx_stage1;
            req_stage2 <= req_stage1;
            
            // Generate grant signals
            grant <= 0;
            if (|valid_req_stage2) begin
                grant[min_idx_stage2] <= 1'b1;
            end
        end
    end
endmodule