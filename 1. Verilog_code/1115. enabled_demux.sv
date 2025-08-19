module enabled_demux (
    input wire din,                     // Data input
    input wire enable,                  // Enable signal
    input wire [1:0] sel,               // Selection control
    output reg [3:0] q_out              // Output ports
);
    always @(*) begin
        q_out = 4'b0;                   // Default state
        if (enable) begin
            case (sel)
                2'b00: q_out[0] = din;
                2'b01: q_out[1] = din;
                2'b10: q_out[2] = din;
                2'b11: q_out[3] = din;
            endcase
        end
    end
endmodule