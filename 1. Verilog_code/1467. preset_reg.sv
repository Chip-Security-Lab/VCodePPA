module preset_reg(
    input clk, sync_preset, load,
    input [11:0] data_in,
    output reg [11:0] data_out
);
    always @(posedge clk) begin
        if (sync_preset)
            data_out <= 12'hFFF;  // Preset to all 1s
        else if (load)
            data_out <= data_in;
    end
endmodule