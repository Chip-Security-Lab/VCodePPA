//SystemVerilog
module enabled_demux (
    input wire din,                       // Data input
    input wire enable,                    // Enable signal
    input wire [1:0] sel,                 // Selection control
    output reg [3:0] q_out                // Output ports
);

reg [3:0] selected_port;

always @(*) begin
    selected_port[0] = (sel == 2'b00) ? din : 1'b0;
    selected_port[1] = (sel == 2'b01) ? din : 1'b0;
    selected_port[2] = (sel == 2'b10) ? din : 1'b0;
    selected_port[3] = (sel == 2'b11) ? din : 1'b0;
end

always @(*) begin
    q_out = enable ? selected_port : 4'b0;
end

endmodule