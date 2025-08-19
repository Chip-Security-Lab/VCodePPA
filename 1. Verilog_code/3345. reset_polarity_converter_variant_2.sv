//SystemVerilog
module reset_polarity_converter (
    input  wire clk,
    input  wire rst_n_in,
    output wire rst_out
);
    reg [2:0] rst_sync_pipeline;
    reg [2:0] valid_pipeline;

    wire flush = ~rst_n_in;

    always @(posedge clk or negedge rst_n_in) begin
        if (!rst_n_in) begin
            rst_sync_pipeline <= 3'b111;
            valid_pipeline    <= 3'b000;
        end else begin
            rst_sync_pipeline <= {rst_sync_pipeline[1:0], 1'b1};
            valid_pipeline    <= {valid_pipeline[1:0], 1'b1};
        end
    end

    assign rst_out = rst_sync_pipeline[2];

endmodule