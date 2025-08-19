//SystemVerilog
//IEEE 1364-2005 Verilog
module RingScheduler #(parameter BUF_SIZE=8) (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    output wire valid_out,
    output wire [BUF_SIZE-1:0] events
);
    // Internal signals for sequential elements
    reg [2:0] ptr_reg, ptr_next;
    reg [BUF_SIZE-1:0] events_reg;
    
    // Pipeline registers - retimed
    reg valid_in_reg;
    reg valid_stage1_reg, valid_stage2_reg;
    reg [BUF_SIZE-1:0] events_stage1_reg, events_shifted_stage2_reg;
    reg [BUF_SIZE-1:0] events_final;
    
    // Retimed output register
    reg valid_out_reg;
    
    // Combinational logic for pointer update
    always @(*) begin
        ptr_next = ptr_reg;
        if (valid_in_reg) begin
            ptr_next = ptr_reg + 3'd1;
        end
    end
    
    // Output assignment - directly from retimed registers
    assign valid_out = valid_out_reg;
    assign events = events_final;
    
    // Sequential logic block - All registers update with retiming
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset values
            ptr_reg <= 3'd0;
            valid_in_reg <= 1'b0;
            valid_stage1_reg <= 1'b0;
            valid_stage2_reg <= 1'b0;
            valid_out_reg <= 1'b0;
            
            events_reg <= {{(BUF_SIZE-1){1'b0}}, 1'b1}; // Initialize with 1
            events_stage1_reg <= {BUF_SIZE{1'b0}};
            events_shifted_stage2_reg <= {BUF_SIZE{1'b0}};
            events_final <= {{(BUF_SIZE-1){1'b0}}, 1'b1}; // Initialize with 1
        end
        else begin
            // Register input signals first
            valid_in_reg <= valid_in;
            
            // Stage 1 - register events from previous stage
            valid_stage1_reg <= valid_in_reg;
            events_stage1_reg <= events_reg;
            
            // Stage 2 - register shifted events 
            valid_stage2_reg <= valid_stage1_reg;
            events_shifted_stage2_reg <= valid_stage1_reg ? (events_stage1_reg << 1) : events_shifted_stage2_reg;
            
            // Stage 3 - compute final events and register directly
            valid_out_reg <= valid_stage2_reg;
            
            // Update ptr register
            ptr_reg <= ptr_next;
            
            // Final output computation with wrap-around logic
            if (valid_stage2_reg) begin
                events_final <= events_shifted_stage2_reg | {events_stage1_reg[BUF_SIZE-1], {(BUF_SIZE-1){1'b0}}};
            end
            
            // Update events register when valid output
            if (valid_out_reg) begin
                events_reg <= events_final;
            end
        end
    end

endmodule