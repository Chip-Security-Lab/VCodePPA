module d_ff_async_preset (
    input wire clk,
    input wire rst_n,
    input wire preset_n,
    input wire d,
    output reg q
);
    always @(posedge clk or negedge rst_n or negedge preset_n) begin
        if (!rst_n)
            q <= 1'b0;  // Reset has priority
        else if (!preset_n)
            q <= 1'b1;  // Preset
        else
            q <= d;     // Normal operation
    end
endmodule