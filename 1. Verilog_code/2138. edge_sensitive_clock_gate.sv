module edge_sensitive_clock_gate (
    input  wire clk_in,
    input  wire data_valid,
    input  wire rst_n,
    output wire clk_out
);
    reg data_valid_last;
    wire edge_detected;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            data_valid_last <= 1'b0;
        else
            data_valid_last <= data_valid;
    end
    
    assign edge_detected = data_valid & ~data_valid_last;
    assign clk_out = clk_in & edge_detected;
endmodule