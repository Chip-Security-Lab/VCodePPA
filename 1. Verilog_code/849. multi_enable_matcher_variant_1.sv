//SystemVerilog
module multi_enable_matcher #(parameter DW = 8) (
    input clk, rst_n,
    input [DW-1:0] data, pattern,
    input en_capture, en_compare,
    output reg match
);
    reg [DW-1:0] stored_data;
    wire [DW-1:0] data_xor;
    wire [DW-1:0] xor_reduced;
    wire pre_match;
    
    // 使用XOR进行位比较，减少比较器延迟
    assign data_xor = stored_data ^ pattern;
    assign xor_reduced = |data_xor;
    assign pre_match = ~xor_reduced;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stored_data <= {DW{1'b0}};
            match <= 1'b0;
        end else begin
            if (en_capture)
                stored_data <= data;
                
            if (en_compare)
                match <= pre_match;
        end
    end
endmodule