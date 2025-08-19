module basic_left_shift #(parameter DATA_WIDTH = 8) (
    input clk_i,
    input rst_i,
    input si,            // Serial input
    output so            // Serial output
);
    reg [DATA_WIDTH-1:0] sr;
    
    always @(posedge clk_i) begin
        if (rst_i)
            sr <= 0;
        else
            sr <= {sr[DATA_WIDTH-2:0], si};
    end
    
    assign so = sr[DATA_WIDTH-1];
endmodule