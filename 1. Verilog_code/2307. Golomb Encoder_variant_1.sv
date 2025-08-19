//SystemVerilog
module golomb_encoder #(
    parameter M_POWER = 2  // M = 2^M_POWER
)(
    input             i_clk,
    input             i_enable,
    input      [15:0] i_value,
    output reg        o_valid,
    output reg [31:0] o_code,
    output reg [5:0]  o_len
);
    // Registered copies of high fanout signals
    reg [3:0] m_power_buf1, m_power_buf2;
    reg [15:0] i_value_buf1, i_value_buf2;
    
    // Internal signals
    reg [15:0] quotient, remainder;
    wire [15:0] unary_code;
    wire [15:0] mask;
    
    // Register high fanout signals
    always @(posedge i_clk) begin
        m_power_buf1 <= M_POWER[3:0];
        m_power_buf2 <= M_POWER[3:0];
        i_value_buf1 <= i_value;
        i_value_buf2 <= i_value;
    end
    
    // Barrel shifter implementation for quotient calculation
    function [15:0] barrel_right_shift;
        input [15:0] data;
        input [3:0] shift_amount;
        reg [15:0] stage1_buf [1:0]; // Buffered stage1 outputs
        reg [15:0] stage2_buf [1:0]; // Buffered stage2 outputs
        reg [15:0] stage3_buf [1:0]; // Buffered stage3 outputs
        reg [15:0] stage4;
        begin
            // Stage 1: shift by 0 or 1 (with fanout buffering)
            stage1_buf[0] = shift_amount[0] ? {1'b0, data[15:1]} : data;
            stage1_buf[1] = stage1_buf[0]; // Buffer copy
            
            // Stage 2: shift by 0 or 2 (with fanout buffering)
            stage2_buf[0] = shift_amount[1] ? {2'b00, stage1_buf[0][15:2]} : stage1_buf[0];
            stage2_buf[1] = stage2_buf[0]; // Buffer copy
            
            // Stage 3: shift by 0 or 4 (with fanout buffering)
            stage3_buf[0] = shift_amount[2] ? {4'b0000, stage2_buf[0][15:4]} : stage2_buf[0];
            stage3_buf[1] = stage3_buf[0]; // Buffer copy
            
            // Stage 4: shift by 0 or 8
            stage4 = shift_amount[3] ? {8'b00000000, stage3_buf[0][15:8]} : stage3_buf[0];
            
            barrel_right_shift = stage4;
        end
    endfunction
    
    // Barrel shifter implementation for mask generation
    function [15:0] barrel_mask_gen;
        input [3:0] shift_amount;
        reg [15:0] mask_buf [1:0]; // Buffered mask outputs
        begin
            mask_buf[0] = 16'hFFFF;
            
            // Stage 1: shift by 0 or 1
            if (shift_amount[0]) mask_buf[0] = mask_buf[0] & 16'hFFFE;
            
            // Stage 2: shift by 0 or 2
            if (shift_amount[1]) mask_buf[0] = mask_buf[0] & 16'hFFFC;
            
            // Stage 3: shift by 0 or 4
            if (shift_amount[2]) mask_buf[0] = mask_buf[0] & 16'hFFF0;
            
            // Stage 4: shift by 0 or 8
            if (shift_amount[3]) mask_buf[0] = mask_buf[0] & 16'hFF00;
            
            mask_buf[1] = ~mask_buf[0]; // Inverse with buffering
            barrel_mask_gen = mask_buf[1];
        end
    endfunction
    
    // Barrel shifter for unary code generation
    function [15:0] barrel_unary_gen;
        input [3:0] shift_amount;
        reg [15:0] unary_buf [1:0]; // Buffered unary outputs
        begin
            unary_buf[0] = 16'hFFFF;
            
            // Stage 1: shift by 0 or 1
            if (shift_amount[0]) unary_buf[0] = {1'b0, unary_buf[0][15:1]};
            
            // Stage 2: shift by 0 or 2
            if (shift_amount[1]) unary_buf[0] = {2'b00, unary_buf[0][15:2]};
            
            // Stage 3: shift by 0 or 4
            if (shift_amount[2]) unary_buf[0] = {4'b0000, unary_buf[0][15:4]};
            
            // Stage 4: shift by 0 or 8
            if (shift_amount[3]) unary_buf[0] = {8'b00000000, unary_buf[0][15:8]};
            
            unary_buf[1] = unary_buf[0]; // Buffer copy
            barrel_unary_gen = unary_buf[1];
        end
    endfunction
    
    // Distribute mask calculation using buffered signals
    wire [15:0] mask_group1, mask_group2;
    assign mask_group1 = barrel_mask_gen(m_power_buf1);
    assign mask_group2 = mask_group1; // Additional buffer for high fanout
    assign mask = mask_group2;
    
    // Pipelined processing to reduce critical path
    reg [15:0] quotient_stage1, remainder_stage1;
    reg [15:0] quotient_unary;
    reg [3:0] quotient_buf;
    
    always @(posedge i_clk) begin
        if (i_enable) begin
            // First pipeline stage: calculate quotient and remainder
            quotient_stage1 <= barrel_right_shift(i_value_buf1, m_power_buf1);
            remainder_stage1 <= i_value_buf2 & mask;
            quotient_buf <= i_value_buf1[15:12]; // Buffer high bits for quotient calculation
            
            // Second pipeline stage: finalize calculations
            quotient <= quotient_stage1;
            remainder <= remainder_stage1;
            quotient_unary <= barrel_unary_gen(quotient_stage1[3:0]);
            
            // Output stage
            o_code <= {quotient_unary, 1'b0, remainder_stage1};
            o_len <= quotient_stage1 + 1 + m_power_buf2;
            o_valid <= 1'b1;
        end else begin
            o_valid <= 1'b0;
        end
    end
endmodule