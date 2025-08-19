//SystemVerilog
module rng_toggle_9(
    input            clk,
    input            rst,
    output reg [7:0] rand_val
);

    reg [7:0] rand_val_stage1;
    reg [7:0] rand_val_stage2;

    always @(posedge clk) begin
        if (rst) begin
            rand_val_stage1 <= 8'h55;
            rand_val_stage2 <= 8'h55;
            rand_val        <= 8'h55;
        end else begin
            rand_val_stage1 <= rand_val;
            rand_val_stage2 <= rand_val_stage1 ^ 8'b00000001;
            rand_val        <= rand_val_stage2;
        end
    end

endmodule