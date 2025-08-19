//SystemVerilog
module prog_clock_gen(
    input i_clk,
    input i_rst_n,
    input i_enable,
    input [15:0] i_divisor,
    output reg o_clk
);
    // Pipeline stage 1 registers
    reg [15:0] count_stage1;
    reg [15:0] divisor_stage1;
    reg enable_stage1;
    reg o_clk_stage1;
    
    // Pipeline stage 2 registers
    reg [15:0] count_stage2;
    reg compare_result_stage2;
    reg o_clk_stage2;
    reg enable_stage2;
    
    // Carry lookahead adder signals
    wire [15:0] count_next;
    wire [3:0] carry_generate;
    wire [3:0] carry_propagate;
    wire [3:0] carry_lookahead;
    
    // Generate and propagate signals for each 4-bit block
    assign carry_generate[0] = count_stage2[3] & 1'b1;
    assign carry_propagate[0] = count_stage2[3] | 1'b1;
    assign carry_generate[1] = count_stage2[7] & count_stage2[6];
    assign carry_propagate[1] = count_stage2[7] | count_stage2[6];
    assign carry_generate[2] = count_stage2[11] & count_stage2[10];
    assign carry_propagate[2] = count_stage2[11] | count_stage2[10];
    assign carry_generate[3] = count_stage2[15] & count_stage2[14];
    assign carry_propagate[3] = count_stage2[15] | count_stage2[14];
    
    // Carry lookahead computation
    assign carry_lookahead[0] = carry_generate[0];
    assign carry_lookahead[1] = carry_generate[1] | (carry_propagate[1] & carry_lookahead[0]);
    assign carry_lookahead[2] = carry_generate[2] | (carry_propagate[2] & carry_lookahead[1]);
    assign carry_lookahead[3] = carry_generate[3] | (carry_propagate[3] & carry_lookahead[2]);
    
    // Sum computation using carry lookahead
    assign count_next[3:0] = count_stage2[3:0] ^ {4{1'b1}} ^ {3'b0, carry_lookahead[0]};
    assign count_next[7:4] = count_stage2[7:4] ^ {4{1'b0}} ^ {3'b0, carry_lookahead[1]};
    assign count_next[11:8] = count_stage2[11:8] ^ {4{1'b0}} ^ {3'b0, carry_lookahead[2]};
    assign count_next[15:12] = count_stage2[15:12] ^ {4{1'b0}} ^ {3'b0, carry_lookahead[3]};
    
    // Pipeline stage 1: Input capture and comparison preparation
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            count_stage1 <= 16'd0;
            divisor_stage1 <= 16'd0;
            enable_stage1 <= 1'b0;
            o_clk_stage1 <= 1'b0;
        end else begin
            divisor_stage1 <= i_divisor;
            enable_stage1 <= i_enable;
            o_clk_stage1 <= o_clk;
            
            if (enable_stage2 && compare_result_stage2) begin
                count_stage1 <= 16'd0;
            end else if (enable_stage2) begin
                count_stage1 <= count_next;
            end else begin
                count_stage1 <= count_stage2;
            end
        end
    end
    
    // Pipeline stage 2: Comparison and output generation
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            count_stage2 <= 16'd0;
            compare_result_stage2 <= 1'b0;
            o_clk_stage2 <= 1'b0;
            enable_stage2 <= 1'b0;
            o_clk <= 1'b0;
        end else begin
            count_stage2 <= count_stage1;
            enable_stage2 <= enable_stage1;
            
            compare_result_stage2 <= (count_stage1 >= divisor_stage1 - 1);
            
            if (enable_stage1) begin
                if (compare_result_stage2) begin
                    o_clk_stage2 <= ~o_clk_stage1;
                end else begin
                    o_clk_stage2 <= o_clk_stage1;
                end
            end
            
            o_clk <= o_clk_stage2;
        end
    end
endmodule