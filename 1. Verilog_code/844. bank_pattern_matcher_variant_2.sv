//SystemVerilog
module bank_pattern_matcher #(parameter W = 8, BANKS = 4) (
    input clk, rst_n,
    input [W-1:0] data,
    input [W-1:0] patterns [BANKS-1:0],
    input [$clog2(BANKS)-1:0] bank_sel,
    output reg match
);
    wire [W-1:0] data_minus_pattern;
    wire [W-1:0] pattern_minus_data;
    wire [W:0] borrow_chain_1, borrow_chain_2;
    wire is_equal;
    
    // 实现借位减法器
    // data - pattern
    assign borrow_chain_1[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin: subtract_loop_1
            assign data_minus_pattern[i] = data[i] ^ patterns[bank_sel][i] ^ borrow_chain_1[i];
            assign borrow_chain_1[i+1] = (~data[i] & patterns[bank_sel][i]) | 
                                        (~data[i] & borrow_chain_1[i]) | 
                                        (patterns[bank_sel][i] & borrow_chain_1[i]);
        end
    endgenerate
    
    // pattern - data
    assign borrow_chain_2[0] = 1'b0;
    generate
        for (i = 0; i < W; i = i + 1) begin: subtract_loop_2
            assign pattern_minus_data[i] = patterns[bank_sel][i] ^ data[i] ^ borrow_chain_2[i];
            assign borrow_chain_2[i+1] = (~patterns[bank_sel][i] & data[i]) | 
                                        (~patterns[bank_sel][i] & borrow_chain_2[i]) | 
                                        (data[i] & borrow_chain_2[i]);
        end
    endgenerate
    
    // 如果两个数相等，则两者相减结果都应为0
    assign is_equal = (data_minus_pattern == {W{1'b0}}) && (pattern_minus_data == {W{1'b0}});
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            match <= 1'b0;
        else
            match <= is_equal;
    end
endmodule