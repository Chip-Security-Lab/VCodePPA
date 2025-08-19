module pulse2level_ismu(
    input wire clock,
    input wire reset_n,
    input wire [3:0] pulse_interrupt,
    input wire clear,
    output reg [3:0] level_interrupt
);
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            level_interrupt <= 4'h0;
        else if (clear)
            level_interrupt <= 4'h0;
        else
            level_interrupt <= level_interrupt | pulse_interrupt;
    end
endmodule