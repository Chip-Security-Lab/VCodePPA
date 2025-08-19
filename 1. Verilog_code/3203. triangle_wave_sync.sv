module triangle_wave_sync #(
    parameter DATA_WIDTH = 8
)(
    input clk_i,
    input sync_rst_i,
    input enable_i,
    output [DATA_WIDTH-1:0] wave_o
);
    reg [DATA_WIDTH-1:0] amplitude;
    reg up_down;
    
    always @(posedge clk_i) begin
        if (sync_rst_i) begin
            amplitude <= {DATA_WIDTH{1'b0}};
            up_down <= 1'b1;
        end else if (enable_i) begin
            if (up_down) begin
                if (&amplitude) up_down <= 1'b0;
                else amplitude <= amplitude + 1'b1;
            end else begin
                if (amplitude == {DATA_WIDTH{1'b0}}) up_down <= 1'b1;
                else amplitude <= amplitude - 1'b1;
            end
        end
    end
    
    assign wave_o = amplitude;
endmodule