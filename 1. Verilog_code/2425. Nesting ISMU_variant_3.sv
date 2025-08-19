//SystemVerilog
module nesting_ismu(
    input clk, rst,
    input [7:0] intr_src,
    input [7:0] intr_enable,
    input [7:0] intr_priority,
    input [2:0] current_level,
    input ready,
    output reg [2:0] intr_level,
    output reg valid
);
    // Register inputs to reduce input-to-register delay
    reg [7:0] intr_src_reg;
    reg [7:0] intr_enable_reg;
    reg [7:0] intr_priority_reg;
    reg [2:0] current_level_reg;
    reg ready_reg;
    
    // Pipeline registers for combinational logic
    reg [7:0] active_src_reg;
    reg [2:0] max_level_reg;
    
    // Control signals
    reg has_pending;
    reg [2:0] pending_level;
    
    // First stage - register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_src_reg <= 8'd0;
            intr_enable_reg <= 8'd0;
            intr_priority_reg <= 8'd0;
            current_level_reg <= 3'd0;
            ready_reg <= 1'b0;
        end else begin
            intr_src_reg <= intr_src;
            intr_enable_reg <= intr_enable;
            intr_priority_reg <= intr_priority;
            current_level_reg <= current_level;
            ready_reg <= ready;
        end
    end
    
    // Second stage - compute active sources and register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            active_src_reg <= 8'd0;
        end else begin
            active_src_reg <= intr_src_reg & intr_enable_reg;
        end
    end
    
    // Third stage - determine max level and register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            max_level_reg <= 3'd0;
        end else begin
            max_level_reg <= 
                active_src_reg[7] && (intr_priority_reg[7] > current_level_reg) ? 3'd7 :
                active_src_reg[6] && (intr_priority_reg[6] > current_level_reg) ? 3'd6 :
                active_src_reg[5] && (intr_priority_reg[5] > current_level_reg) ? 3'd5 :
                active_src_reg[4] && (intr_priority_reg[4] > current_level_reg) ? 3'd4 :
                active_src_reg[3] && (intr_priority_reg[3] > current_level_reg) ? 3'd3 :
                active_src_reg[2] && (intr_priority_reg[2] > current_level_reg) ? 3'd2 :
                active_src_reg[1] && (intr_priority_reg[1] > current_level_reg) ? 3'd1 :
                active_src_reg[0] && (intr_priority_reg[0] > current_level_reg) ? 3'd0 : 3'd0;
        end
    end
    
    // Final stage - Valid-Ready handshake logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_level <= 3'd0;
            valid <= 1'b0;
            pending_level <= 3'd0;
            has_pending <= 1'b0;
        end else begin
            // Detect if max_level_reg > current_level_reg and active_src_reg has any active bits
            if (|active_src_reg && (max_level_reg > current_level_reg)) begin
                if (!valid || (valid && ready_reg)) begin
                    valid <= 1'b1;
                    intr_level <= max_level_reg;
                    has_pending <= 1'b0;
                end else begin
                    pending_level <= max_level_reg;
                    has_pending <= 1'b1;
                end
            end else if (valid && ready_reg) begin
                if (has_pending) begin
                    valid <= 1'b1;
                    intr_level <= pending_level;
                    has_pending <= 1'b0;
                end else begin
                    valid <= 1'b0;
                end
            end
        end
    end
endmodule