//SystemVerilog
// IEEE 1364-2005
module barrel_shifter (
    input wire clk,         // Added clock input for pipelining
    input wire rst_n,       // Added reset signal
    input wire [7:0] data_in,
    input wire [2:0] shift_amount,
    input wire direction,   // 0: right, 1: left
    output reg [7:0] data_out
);
    // =========================================================
    // Pipeline stage registers
    // =========================================================
    // Stage 1: Input capture and first shift operation
    reg [7:0] stage1_data;
    reg [2:0] stage1_shift_amount;
    reg stage1_direction;
    
    // Stage 2: Second shift operation
    reg [7:0] stage2_data;
    reg [1:0] stage2_shift_amount;
    reg stage2_direction;
    
    // Stage 3: Final shift operation
    reg [7:0] stage3_data;
    
    // =========================================================
    // Data path logic - Shift operations at each stage
    // =========================================================
    // Stage 1: shift by 0 or 1 bit
    wire [7:0] shift1_right = {1'b0, data_in[7:1]};
    wire [7:0] shift1_left = {data_in[6:0], 1'b0};
    wire [7:0] shift1_result = shift_amount[0] ? 
                              (direction ? shift1_left : shift1_right) : 
                              data_in;
    
    // Stage 2: shift by 0 or 2 bits
    wire [7:0] shift2_right = {2'b0, stage1_data[7:2]};
    wire [7:0] shift2_left = {stage1_data[5:0], 2'b0};
    wire [7:0] shift2_result = stage1_shift_amount[1] ? 
                              (stage1_direction ? shift2_left : shift2_right) : 
                              stage1_data;
    
    // Stage 3: shift by 0 or 4 bits
    wire [7:0] shift3_right = {4'b0, stage2_data[7:4]};
    wire [7:0] shift3_left = {stage2_data[3:0], 4'b0};
    wire [7:0] shift3_result = stage2_shift_amount[0] ? 
                              (stage2_direction ? shift3_left : shift3_right) : 
                              stage2_data;
    
    // =========================================================
    // Pipeline register updates
    // =========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            stage1_data <= 8'h0;
            stage1_shift_amount <= 3'h0;
            stage1_direction <= 1'b0;
            
            stage2_data <= 8'h0;
            stage2_shift_amount <= 2'h0;
            stage2_direction <= 1'b0;
            
            stage3_data <= 8'h0;
            data_out <= 8'h0;
        end else begin
            // Stage 1 registers
            stage1_data <= shift1_result;
            stage1_shift_amount <= shift_amount;
            stage1_direction <= direction;
            
            // Stage 2 registers
            stage2_data <= shift2_result;
            stage2_shift_amount <= stage1_shift_amount[2:1];
            stage2_direction <= stage1_direction;
            
            // Stage 3 registers
            stage3_data <= shift3_result;
            
            // Output register
            data_out <= stage3_data;
        end
    end
endmodule