module multi_enable_matcher #(parameter DW = 8) (
    input clk, rst_n,
    input [DW-1:0] data, pattern,
    input en_capture, en_compare,
    output reg match
);
    reg [DW-1:0] stored_data;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stored_data <= {DW{1'b0}};
            match <= 1'b0;
        end else begin
            if (en_capture)
                stored_data <= data;
            if (en_compare)
                match <= (stored_data == pattern);
        end
    end
endmodule