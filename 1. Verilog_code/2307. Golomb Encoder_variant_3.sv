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
    reg [15:0] quotient, remainder;
    reg [15:0] unary_code;
    
    // Barrel shifter for quotient calculation (right shift)
    function [15:0] barrel_right_shift;
        input [15:0] data;
        input [3:0] shift_amt;
        reg [15:0] stage0, stage1, stage2, stage3;
        begin
            // Stage 0: shift by 0 or 1
            stage0 = shift_amt[0] ? {1'b0, data[15:1]} : data;
            
            // Stage 1: shift by 0 or 2
            stage1 = shift_amt[1] ? {2'b00, stage0[15:2]} : stage0;
            
            // Stage 2: shift by 0 or 4
            stage2 = shift_amt[2] ? {4'b0000, stage1[15:4]} : stage1;
            
            // Stage 3: shift by 0 or 8
            stage3 = shift_amt[3] ? {8'b00000000, stage2[15:8]} : stage2;
            
            barrel_right_shift = stage3;
        end
    endfunction
    
    // Mask generation for remainder calculation
    function [15:0] generate_mask;
        input [3:0] m_power;
        reg [15:0] mask;
        integer i;
        begin
            mask = 16'h0000;
            for (i = 0; i < 16; i = i + 1) begin
                if (i < m_power)
                    mask[i] = 1'b1;
                else
                    mask[i] = 1'b0;
            end
            generate_mask = mask;
        end
    endfunction
    
    // Generate unary pattern based on input value
    function [15:0] generate_unary;
        input [3:0] quot_val;
        reg [15:0] unary_pattern;
        integer j;
        begin
            unary_pattern = 16'h0000;
            for (j = 0; j < 16; j = j + 1) begin
                if (j < quot_val)
                    unary_pattern[15-j] = 1'b1;
                else
                    unary_pattern[15-j] = 1'b0;
            end
            generate_unary = unary_pattern;
        end
    endfunction
    
    // Quotient calculation always block
    always @(posedge i_clk) begin
        if (i_enable) begin
            quotient <= barrel_right_shift(i_value, M_POWER[3:0]);
        end
    end
    
    // Remainder calculation always block
    always @(posedge i_clk) begin
        if (i_enable) begin
            remainder <= i_value & generate_mask(M_POWER[3:0]);
        end
    end
    
    // Unary code generation always block
    reg [15:0] unary_pattern;
    always @(posedge i_clk) begin
        if (i_enable) begin
            unary_pattern <= generate_unary(quotient[3:0]);
        end
    end
    
    // Output code and length generation always block
    always @(posedge i_clk) begin
        if (i_enable) begin
            o_code <= {unary_pattern, 1'b0, remainder};
            o_len <= quotient + 1 + M_POWER;
            o_valid <= 1'b1;
        end else begin
            o_valid <= 1'b0;
        end
    end
    
endmodule