module snapshot_buffer (
    input wire clk,
    input wire [31:0] live_data,
    input wire capture,
    output reg [31:0] snapshot_data
);
    always @(posedge clk) begin
        if (capture)
            snapshot_data <= live_data;
    end
endmodule