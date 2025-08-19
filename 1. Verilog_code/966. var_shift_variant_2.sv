//SystemVerilog
module var_shift #(parameter W = 8) (
    input wire clock,
    input wire clear,
    input wire [W-1:0] data,
    input wire [2:0] shift_amt,
    input wire load,
    input wire valid_in,
    output wire valid_out,
    output wire ready_in,
    output wire [W-1:0] result
);
    // Pipeline registers for data path
    reg [W-1:0] data_stage1, data_stage2, data_stage3;
    reg [2:0] shift_amt_stage1, shift_amt_stage2;
    
    // Pipeline registers for control signals
    reg load_stage1, load_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Pipeline ready signals (for handshaking)
    wire ready_stage2, ready_stage3;
    
    // Final result register
    reg [W-1:0] shift_reg;
    
    // Ready propagation (backward)
    assign ready_stage3 = 1'b1; // Output always ready to accept new data
    assign ready_stage2 = ready_stage3;
    assign ready_in = ready_stage2;
    
    // Valid propagation (forward)
    assign valid_out = valid_stage3;
    
    // First pipeline stage - Register inputs
    always @(posedge clock) begin
        if (clear) begin
            data_stage1 <= {W{1'b0}};
            shift_amt_stage1 <= 3'b0;
            load_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else if (ready_in) begin
            data_stage1 <= data;
            shift_amt_stage1 <= shift_amt;
            load_stage1 <= load;
            valid_stage1 <= valid_in;
        end
    end
    
    // Second pipeline stage - Process control logic
    always @(posedge clock) begin
        if (clear) begin
            data_stage2 <= {W{1'b0}};
            shift_amt_stage2 <= 3'b0;
            load_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else if (ready_stage2) begin
            data_stage2 <= data_stage1;
            shift_amt_stage2 <= shift_amt_stage1;
            load_stage2 <= load_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Third pipeline stage - Execute shifting operation
    always @(posedge clock) begin
        if (clear) begin
            shift_reg <= {W{1'b0}};
            data_stage3 <= {W{1'b0}};
            valid_stage3 <= 1'b0;
        end
        else if (ready_stage3) begin
            if (load_stage2 && valid_stage2)
                shift_reg <= data_stage2;
            else if (valid_stage2)
                shift_reg <= shift_reg >> shift_amt_stage2;
                
            data_stage3 <= shift_reg;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignment
    assign result = data_stage3;
endmodule