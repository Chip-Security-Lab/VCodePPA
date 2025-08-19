//SystemVerilog
module programmable_rom (
    input clk,
    input prog_en,
    input [3:0] addr,
    input [7:0] din,
    input req,
    output reg ack,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg programmed [0:15];
    reg req_d;
    reg prog_condition;
    reg read_condition;

    always @(posedge clk) begin
        req_d <= req;
        prog_condition <= prog_en && !programmed[addr];
        read_condition <= req && !req_d;

        if (prog_condition) begin
            rom[addr] <= din;
            programmed[addr] <= 1;
        end

        if (read_condition) begin
            data <= rom[addr];
            ack <= 1;
        end else begin
            ack <= 0;
        end
    end
endmodule