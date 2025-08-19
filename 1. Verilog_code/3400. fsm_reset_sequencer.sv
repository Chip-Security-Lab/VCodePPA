module boot_sequence_reset(
    input wire clk,
    input wire power_good,
    output reg [3:0] rst_seq,
    output reg boot_complete
);
    reg [2:0] boot_stage;
    always @(posedge clk or negedge power_good) begin
        if (!power_good) begin
            boot_stage <= 3'b0;
            rst_seq <= 4'b1111;
            boot_complete <= 1'b0;
        end else if (boot_stage < 3'b100) begin
            boot_stage <= boot_stage + 1'b1;
            rst_seq <= rst_seq >> 1;
            boot_complete <= (boot_stage == 3'b011);
        end
    end
endmodule