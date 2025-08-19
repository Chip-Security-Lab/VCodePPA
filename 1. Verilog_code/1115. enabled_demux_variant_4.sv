//SystemVerilog
module enabled_demux (
    input wire din,                     // Data input
    input wire enable,                  // Enable signal
    input wire [1:0] sel,               // Selection control
    output reg [3:0] q_out              // Output ports
);
    integer i;
    always @(*) begin
        q_out = 4'b0;                   // Default state
        if (enable && sel <= 2'b11) begin
            for (i = 0; i < 4; i = i + 1) begin
                q_out[i] = (sel == i[1:0]) ? din : 1'b0;
            end
        end
    end
endmodule