//SystemVerilog
module async_arith_shift_right (
    input             clk,
    input             rst_n,
    input      [15:0] data_i,
    input      [3:0]  shamt_i,
    input             valid_i,
    output            ready_o,
    output reg [15:0] data_o,
    output reg        valid_o,
    input             ready_i
);
    // Pipeline stage registers
    reg [15:0] data_stage1, data_stage2, data_stage3;
    reg [3:0]  shamt_stage1, shamt_stage2, shamt_stage3;
    reg        valid_stage1, valid_stage2, valid_stage3;
    
    // Intermediate shift results
    reg [15:0] shift_stage2, shift_stage3;
    
    // Handshake control
    assign ready_o = !valid_stage1 || (valid_stage1 && !valid_stage2) || 
                    (valid_stage3 && ready_i && valid_stage2);
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 16'b0;
            shamt_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else if (valid_i && ready_o) begin
            data_stage1 <= data_i;
            shamt_stage1 <= shamt_i;
            valid_stage1 <= 1'b1;
        end else if (valid_stage1 && (!valid_stage2 || (valid_stage3 && ready_i))) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: First part of shift calculation (handle first half of shifts)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 16'b0;
            shamt_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
            shift_stage2 <= 16'b0;
        end else if (valid_stage1 && (!valid_stage2 || (valid_stage3 && ready_i))) begin
            data_stage2 <= data_stage1;
            shamt_stage2 <= shamt_stage1;
            valid_stage2 <= valid_stage1;
            
            // First part of shift - handle shift by 0-1 bits
            case (shamt_stage1[0])
                1'b0: shift_stage2 <= data_stage1;
                1'b1: shift_stage2 <= {data_stage1[15], data_stage1[15:1]};
            endcase
        end else if (valid_stage2 && valid_stage3 && ready_i) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Stage 3: Second part of shift calculation (handle second half of shifts)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= 16'b0;
            shamt_stage3 <= 4'b0;
            valid_stage3 <= 1'b0;
            shift_stage3 <= 16'b0;
        end else if (valid_stage2 && (!valid_stage3 || ready_i)) begin
            data_stage3 <= data_stage2;
            shamt_stage3 <= shamt_stage2;
            valid_stage3 <= valid_stage2;
            
            // Second part of shift - handle shift by 0/2 bits
            case (shamt_stage2[1])
                1'b0: shift_stage3 <= shift_stage2;
                1'b1: shift_stage3 <= {{2{shift_stage2[15]}}, shift_stage2[15:2]};
            endcase
        end else if (valid_stage3 && ready_i) begin
            valid_stage3 <= 1'b0;
        end
    end
    
    // Output stage: Final part of shift calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_o <= 16'b0;
            valid_o <= 1'b0;
        end else if (valid_stage3 && (!valid_o || ready_i)) begin
            valid_o <= valid_stage3;
            
            // Final part of shift - handle shift by 0/4/8 bits
            case (shamt_stage3[3:2])
                2'b00: data_o <= shift_stage3;
                2'b01: data_o <= {{4{shift_stage3[15]}}, shift_stage3[15:4]};
                2'b10: data_o <= {{8{shift_stage3[15]}}, shift_stage3[15:8]};
                2'b11: data_o <= {{12{shift_stage3[15]}}, shift_stage3[15:12]};
            endcase
        end else if (valid_o && ready_i) begin
            valid_o <= 1'b0;
        end
    end
endmodule