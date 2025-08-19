//SystemVerilog
module AsyncHandshakeBridge(
    input src_clk, dst_clk,
    input req_in, ack_out,
    output reg req_out, ack_in,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    reg [31:0] buf_reg;
    reg src_flag, dst_flag;
    wire handshake_active;
    
    assign handshake_active = req_out && (src_flag != dst_flag);
    
    always @(posedge src_clk) begin
        if (req_in && !ack_in) begin
            buf_reg <= data_in;
            src_flag <= ~src_flag;
            req_out <= 1'b1;
        end
        if (ack_out) begin
            req_out <= 1'b0;
        end
    end
    
    always @(posedge dst_clk) begin
        if (handshake_active) begin
            dst_flag <= src_flag; // Moved dst_flag assignment before ack_in
            data_out <= buf_reg;  // Moved data_out assignment before ack_in
            ack_in <= 1'b1;
        end else begin
            ack_in <= 1'b0;
        end
    end
endmodule