module active_low_enable_reg(
    input clk, reset,
    input [11:0] data_bus,
    input load_n,
    output reg [11:0] register_out
);
    always @(posedge clk) begin
        if (reset)
            register_out <= 12'h0;
        else if (!load_n)  // Active low enable
            register_out <= data_bus;
    end
endmodule
