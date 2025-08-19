//SystemVerilog
module power_efficient_shifter(
    input clk,
    input valid,              // Sender indicates data is valid
    input [7:0] data_in,
    input [2:0] shift,
    output reg [7:0] data_out,
    output reg data_out_valid, // Indicates output data is valid
    input ready               // Receiver indicates it's ready for data
);
    // Pipeline stage valid signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Pipeline stage data registers
    reg [7:0] stage1_data, stage2_data, stage3_data;
    reg [2:0] stage1_shift, stage2_shift, stage3_shift;
    
    // Ready signals for pipeline flow control (backward propagation)
    wire ready_stage3, ready_stage2, ready_stage1;
    wire stage1_active, stage2_active, stage3_active;
    
    // Power gating activation signals per stage
    assign stage1_active = valid_stage1 & |stage1_shift[0];
    assign stage2_active = valid_stage2 & |stage2_shift[1];
    assign stage3_active = valid_stage3 & |stage3_shift[2];
    
    // Ready signal propagation through pipeline
    assign ready_stage3 = ready || !data_out_valid;
    assign ready_stage2 = ready_stage3 || !valid_stage3;
    assign ready_stage1 = ready_stage2 || !valid_stage2;
    
    // Stage 1: Apply shift[0] if needed
    always @(posedge clk) begin
        if (valid && ready_stage1 && !valid_stage1) begin
            // Load new data into first stage
            stage1_data <= data_in;
            stage1_shift <= shift;
            valid_stage1 <= 1'b1;
        end else if (valid_stage1 && ready_stage1) begin
            // Process and advance to next stage
            if (stage1_active && stage1_shift[0])
                stage1_data <= {stage1_data[6:0], 1'b0};
                
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Apply shift[1] if needed
    always @(posedge clk) begin
        if (valid_stage1 && ready_stage2 && !valid_stage2) begin
            // Receive data from previous stage
            stage2_data <= stage1_data;
            stage2_shift <= stage1_shift;
            valid_stage2 <= 1'b1;
        end else if (valid_stage2 && ready_stage2) begin
            // Process and advance to next stage
            if (stage2_active && stage2_shift[1])
                stage2_data <= {stage2_data[5:0], 2'b0};
                
            valid_stage2 <= 1'b0;
        end
    end
    
    // Stage 3: Apply shift[2] if needed
    always @(posedge clk) begin
        if (valid_stage2 && ready_stage3 && !valid_stage3) begin
            // Receive data from previous stage
            stage3_data <= stage2_data;
            stage3_shift <= stage2_shift;
            valid_stage3 <= 1'b1;
        end else if (valid_stage3 && ready_stage3) begin
            // Process and produce final output
            if (stage3_active && stage3_shift[2])
                data_out <= {stage3_data[3:0], 4'b0};
            else
                data_out <= stage3_data;
                
            data_out_valid <= 1'b1;
            valid_stage3 <= 1'b0;
        end else if (data_out_valid && ready) begin
            // Clear valid flag once receiver has accepted the data
            data_out_valid <= 1'b0;
        end
    end
endmodule