module reset_polarity_converter (
    input  wire clk,
    input  wire rst_n_in,
    output wire rst_out
);
    reg [1:0] sync_stages;
    
    always @(posedge clk or negedge rst_n_in) begin
        if (!rst_n_in)
            sync_stages <= 2'b11;
        else
            sync_stages <= {sync_stages[0], 1'b0};
    end
    
    assign rst_out = sync_stages[1];
endmodule
